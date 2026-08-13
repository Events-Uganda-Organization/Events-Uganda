import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:events_uganda/Services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'outbox/outbox_storage.dart';
import 'outbox/outbox_storage_io.dart'
    if (dart.library.html) 'outbox/outbox_storage_web.dart' as storage;

enum OutboxMediaType { image, audio }

class OutboxItem {
  OutboxItem({
    required this.id,
    required this.conversationId,
    required this.type,
    this.text,
    this.filename,
    this.durationMs,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final OutboxMediaType type;
  final String? text;
  final String? filename;
  final int? durationMs;
  final int createdAt;

  String get storageKey => 'item_$id';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'conversationId': conversationId,
        'type': type.name,
        'text': text,
        'filename': filename,
        'durationMs': durationMs,
        'createdAt': createdAt,
      };

  factory OutboxItem.fromJson(Map<String, dynamic> json) => OutboxItem(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        type: OutboxMediaType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => OutboxMediaType.image,
        ),
        text: json['text'] as String?,
        filename: json['filename'] as String?,
        durationMs: (json['durationMs'] as num?)?.toInt(),
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      );
}

class OutboxEvent {
  OutboxEvent({
    required this.outboxId,
    this.message,
    this.failed = false,
  });

  final String outboxId;
  final ChatMessage? message;
  final bool failed;
}

/// Persistent, offline-first upload queue for chat media (images + voice).
///
/// Media messages are written to local storage the moment the user hits send
/// and are uploaded silently in the background. If the app is closed before
/// the upload completes, the queue is replayed on the next launch. The UI
/// renders optimistically and only listens for [events] to swap the local
/// preview for the real server message.
class ChatOutbox {
  ChatOutbox._();

  static final ChatOutbox instance = ChatOutbox._();

  static const String _itemsKey = 'chat_outbox_items';

  final OutboxStorage _storage = storage.createOutboxStorage();
  final StreamController<OutboxEvent> _events =
      StreamController<OutboxEvent>.broadcast();

  List<OutboxItem> _items = <OutboxItem>[];
  bool _loaded = false;
  bool _draining = false;
  Timer? _retryTimer;
  int _retrySeconds = 10;

  Stream<OutboxEvent> get events => _events.stream;

  int get pendingCount => _items.length;

  bool get hasPending => _items.isNotEmpty;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_itemsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _items = list
            .map((e) => OutboxItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _items = <OutboxItem>[];
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _itemsKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  /// Queues a media message. Returns the outbox id immediately so the caller
  /// can render an optimistic bubble. Media bytes are copied to local storage
  /// so the item survives app restarts.
  Future<String> enqueueMedia({
    required String conversationId,
    required OutboxMediaType type,
    required Uint8List bytes,
    String? text,
    String? filename,
    Duration? duration,
  }) async {
    await _ensureLoaded();
    final String id =
        'ox_${DateTime.now().millisecondsSinceEpoch}_${_random()}';
    final OutboxItem item = OutboxItem(
      id: id,
      conversationId: conversationId,
      type: type,
      text: text,
      filename: filename,
      durationMs: duration?.inMilliseconds,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _storage.writeBytes(item.storageKey, bytes);
    _items.add(item);
    await _persist();
    unawaited(drain());
    return id;
  }

  String _random() {
    final math.Random rnd = math.Random();
    return rnd.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
  }

  /// Attempts to upload every pending item. Retries are scheduled with
  /// exponential backoff while items remain. Safe to call repeatedly.
  Future<void> drain() async {
    await _ensureLoaded();
    if (_draining) return;
    final List<OutboxItem> pending = List<OutboxItem>.of(_items);
    if (pending.isEmpty) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _retrySeconds = 10;
      return;
    }
    _draining = true;
    try {
      for (final OutboxItem item in pending) {
        if (!_items.any((e) => e.id == item.id)) continue;
        try {
          final ChatMessage? sent = await _upload(item);
          if (sent != null) {
            await _removeItem(item);
            _events.add(OutboxEvent(outboxId: item.id, message: sent));
          } else {
            _events.add(OutboxEvent(outboxId: item.id, failed: true));
          }
        } catch (_) {
          _events.add(OutboxEvent(outboxId: item.id, failed: true));
        }
      }
    } finally {
      _draining = false;
    }
    if (_items.isNotEmpty) {
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: _retrySeconds), drain);
      _retrySeconds = math.min(_retrySeconds * 2, 300);
    } else {
      _retryTimer?.cancel();
      _retryTimer = null;
      _retrySeconds = 10;
    }
  }

  Future<ChatMessage?> _upload(OutboxItem item) async {
    final Uint8List? bytes = await _storage.readBytes(item.storageKey);
    if (bytes == null || bytes.isEmpty) {
      await _removeItem(item);
      return null;
    }
    if (item.type == OutboxMediaType.image) {
      return ChatService.sendImage(
        item.conversationId,
        bytes,
        caption: (item.text?.isNotEmpty ?? false) ? item.text : null,
        filename: item.filename ?? 'photo_${item.createdAt}.jpg',
      );
    }
    return ChatService.sendVoice(
      item.conversationId,
      bytes,
      filename: item.filename ?? 'voice_${item.createdAt}.m4a',
      duration: Duration(milliseconds: item.durationMs ?? 0),
    );
  }

  Future<void> _removeItem(OutboxItem item) async {
    _items.removeWhere((e) => e.id == item.id);
    await _persist();
    await _storage.deleteBytes(item.storageKey);
  }
}

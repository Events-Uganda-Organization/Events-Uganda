import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/components/snackbar_helper.dart';
import 'package:events_uganda/Services/chat_outbox.dart';
import 'package:events_uganda/Services/chat_service.dart';
import 'package:events_uganda/Services/chat_socket_service.dart';
import 'package:events_uganda/Users/Customers/Empty_State_Art.dart';
import 'package:events_uganda/Users/Customers/Service_Details_Screen.dart';

enum _ChatMenuAction { disappearing, clearChat, block, report }

class MessageScreen extends StatefulWidget {
  const MessageScreen({
    super.key,
    this.name,
    this.color,
    this.status,
    this.conversationId,
    this.highlightMessageId,
  });

  final String? name;
  final Color? color;
  final String? status;
  final String? conversationId;
  final String? highlightMessageId;

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _messagesScroll = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<Uint8List> _selectedImages = [];
  final List<Map<String, Object>> _messages = [];
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Stopwatch _recordingStopwatch = Stopwatch();
  final List<double> _waveSamples = [];
  final ValueNotifier<double> _voiceProgress = ValueNotifier<double>(0);
  Timer? _recordingTicker;
  Timer? _disappearingTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<ChatMessage>? _socketSub;
  StreamSubscription<ChatReadReceipt>? _readReceiptSub;
  StreamSubscription<OutboxEvent>? _outboxSub;
  String? _recordingPath;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _recordingLocked = false;
  double _cancelDragOffset = 0;
  double _lastAmplitude = 0.5;
  bool _receivedAmplitude = false;
  int? _playingVoiceIndex;
  bool _isPlayingVoice = false;
  bool _isLoadingMessages = false;
  String? _authToken;
  String _disappearingMode = 'OFF';
  bool _blocked = false;
  bool _amBlocked = false;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageFocusNode.addListener(_onMessageFocusChanged);
    _outboxSub = ChatOutbox.instance.events.listen(_onOutboxEvent);
    AuthService.getToken().then((token) {
      if (mounted && token != null && token.isNotEmpty) {
        setState(() => _authToken = token);
      }
    });
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _voiceProgress.value = 1;
        if (mounted) {
          setState(() {
            _isPlayingVoice = false;
            _playingVoiceIndex = null;
          });
        }
      }
    });
    _positionSub = _audioPlayer.positionStream.listen((position) {
      if (!_isPlayingVoice) return;
      final Duration? total = _audioPlayer.duration;
      if (total != null && total.inMilliseconds > 0) {
        _voiceProgress.value =
            (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
      }
    });
    if (widget.conversationId != null) {
      _loadMessages();
      _loadConversationSettings();
      _initSocket();
      ChatOutbox.instance.drain();
      _startDisappearingTimer();
    }
  }

  void _onMessageFocusChanged() {
    if (mounted) setState(() {});
  }

  void _startDisappearingTimer() {
    _disappearingTimer?.cancel();
    _disappearingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pruneExpiredMessages(),
    );
  }

  void _pruneExpiredMessages() {
    if (!mounted) return;
    final int before = _messages.length;
    _messages.removeWhere((m) {
      final Object? expiresAt = m['expiresAt'];
      if (expiresAt is! int) return false;
      return expiresAt <= DateTime.now().millisecondsSinceEpoch;
    });
    if (before != _messages.length) {
      setState(() {});
    }
  }

  Future<void> _loadConversationSettings() async {
    final conversationId = widget.conversationId;
    if (conversationId == null) return;
    try {
      final conv = await ChatService.getConversation(conversationId);
      if (!mounted) return;
      setState(() {
        _disappearingMode = conv.disappearingMode;
        _blocked = conv.blocked;
        _amBlocked = conv.amBlocked;
      });
    } catch (_) {}
  }

  bool get _isBlocked => _blocked || _amBlocked;

  PopupMenuItem<_ChatMenuAction> _buildChatMenuItem({
    required IconData icon,
    required String label,
    required Color dotColor,
    required _ChatMenuAction value,
    required double screenWidth,
  }) {
    return PopupMenuItem<_ChatMenuAction>(
      value: value,
      height: screenWidth * 0.14,
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.028,
            height: screenWidth * 0.028,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Container(
            width: screenWidth * 0.09,
            height: screenWidth * 0.09,
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: dotColor, size: screenWidth * 0.048),
          ),
          SizedBox(width: screenWidth * 0.035),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleChatMenuAction(_ChatMenuAction action) {
    debugPrint('[MessageScreen] Chat menu action selected: $action');
    switch (action) {
      case _ChatMenuAction.disappearing:
        _openDisappearingSheet();
      case _ChatMenuAction.clearChat:
        _confirmClearChat();
      case _ChatMenuAction.block:
        _confirmBlockOrUnblock();
      case _ChatMenuAction.report:
        _showReportSheet();
    }
  }

  void _openDisappearingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _DisappearingMessagesSheet(
        currentMode: _disappearingMode,
        onSelect: (mode) async {          final conversationId = widget.conversationId;
          if (conversationId == null) {
            debugPrint('[MessageScreen] Disappearing mode aborted: conversationId is null');
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            return;
          }
          debugPrint('[MessageScreen] Setting disappearing mode to "$mode" for conversationId=$conversationId');
          try {
            await ChatService.setDisappearingMode(conversationId, mode);
            debugPrint('[MessageScreen] Disappearing mode set to "$mode" successfully for conversationId=$conversationId');
            if (mounted) setState(() => _disappearingMode = mode);
            if (mounted) {
              SnackbarHelper.show(
                context,
                mode == 'OFF'
                    ? 'Disappearing messages turned off'
                    : 'Disappearing messages set to ${_disappearingLabel(mode)}',
                icon: mode == 'OFF'
                    ? Icons.timer_off_outlined
                    : Icons.schedule_outlined,
                backgroundColor: const Color(0xFFCC471B),
              );
            }
          } catch (e) {
            debugPrint('[MessageScreen] Failed to set disappearing mode "$mode" for conversationId=$conversationId: $e');
            if (mounted) {
              SnackbarHelper.show(
                context,
                'Could not update: $e',
                icon: Icons.error_outline_rounded,
                backgroundColor: const Color(0xFFCC471B),
              );
            }
          }
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  String _disappearingLabel(String mode) {
    switch (mode) {
      case '24H':
        return '24 hours';
      case '7D':
        return '7 days';
      default:
        return 'Off';
    }
  }

  Future<void> _confirmClearChat() async {
    final conversationId = widget.conversationId;
    debugPrint('[MessageScreen] _confirmClearChat called, conversationId=$conversationId');
    if (conversationId == null) {
      debugPrint('[MessageScreen] _confirmClearChat aborted: conversationId is null');
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ClearChatSheet(
        contactName: widget.name,
        onClear: () async {
          debugPrint('[MessageScreen] Clear chat confirmed, conversationId=$conversationId');
          try {
            await ChatService.clearChat(conversationId);
            debugPrint('[MessageScreen] Chat cleared successfully, conversationId=$conversationId');
            if (mounted) {
              setState(() {
                _messages.clear();
                _highlightedMessageId = null;
              });
              if (_messagesScroll.hasClients) {
                _messagesScroll.jumpTo(0);
              }
              SnackbarHelper.show(
                context,
                'Chat cleared',
                icon: Icons.check_circle_rounded,
                backgroundColor: const Color(0xFFCC471B),
              );
            }
          } catch (e) {
            debugPrint('[MessageScreen] Failed to clear chat, conversationId=$conversationId: $e');
            if (mounted) {
              SnackbarHelper.show(
                context,
                'Could not clear chat: $e',
                icon: Icons.error_outline_rounded,
                backgroundColor: const Color(0xFFCC471B),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmBlockOrUnblock() async {
    final bool block = !_blocked;
    final conversationId = widget.conversationId;
    debugPrint('[MessageScreen] _confirmBlockOrUnblock called, block=$block, conversationId=$conversationId, _blocked=$_blocked, _amBlocked=$_amBlocked');
    if (conversationId == null) {
      debugPrint('[MessageScreen] _confirmBlockOrUnblock aborted: conversationId is null');
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BlockUserSheet(
        blocking: block,
        contactName: widget.name,
        onAction: () async {
          debugPrint('[MessageScreen] Block/unblock confirmed, block=$block, conversationId=$conversationId');
          try {
            if (block) {
              await ChatService.blockUser(conversationId);
              debugPrint('[MessageScreen] User blocked successfully, conversationId=$conversationId');
            } else {
              await ChatService.unblockUser(conversationId);
              debugPrint('[MessageScreen] User unblocked successfully, conversationId=$conversationId');
            }
            if (mounted) {
              setState(() => _blocked = block);
              SnackbarHelper.show(
                context,
                block ? 'User blocked' : 'User unblocked',
                icon: Icons.check_circle_rounded,
                backgroundColor: const Color(0xFFCC471B),
              );
            }
          } catch (e) {
            debugPrint('[MessageScreen] Failed to ${block ? 'block' : 'unblock'} user, conversationId=$conversationId: $e');
            if (mounted) {
              SnackbarHelper.show(
                context,
                'Could not update: $e',
                icon: Icons.error_outline_rounded,
                backgroundColor: const Color(0xFFCC471B),
              );
            }
          }
        },
      ),
    );
  }

  void _showReportSheet() {
    final conversationId = widget.conversationId;
    debugPrint('[MessageScreen] _showReportSheet called, conversationId=$conversationId');
    if (conversationId == null) {
      debugPrint('[MessageScreen] _showReportSheet aborted: conversationId is null');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ReportUserSheet(
        contactName: widget.name,
        onSubmit: (reason) async {
          debugPrint('[MessageScreen] Report submitted, reason="$reason", conversationId=$conversationId');
          try {
            await ChatService.reportUser(conversationId, reason);
            debugPrint('[MessageScreen] Report submitted successfully, conversationId=$conversationId');
            if (mounted) {
              SnackbarHelper.show(
                context,
                'Report submitted. Thank you for keeping the community safe.',
                icon: Icons.check_circle_rounded,
                backgroundColor: const Color(0xFFCC471B),
              );
            }
          } catch (e) {
            debugPrint('[MessageScreen] Failed to submit report, conversationId=$conversationId: $e');
            if (mounted) {
              SnackbarHelper.show(
                context,
                'Could not submit report: $e',
                icon: Icons.error_outline_rounded,
                backgroundColor: const Color(0xFFCC471B),
              );
            }
          }
        },
      ),
    );
  }

  void _showBlockedNotice() {
    SnackbarHelper.show(
      context,
      _amBlocked
          ? 'This user has blocked you'
          : 'You blocked this user. Unblock to message them.',
      icon: Icons.info_outline_rounded,
      backgroundColor: const Color(0xFFCC471B),
    );
  }

  Widget _buildBlockedBanner(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE7E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE57373).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Color(0xFFE53935), size: 18),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Text(
              _amBlocked
                  ? 'This user has blocked you.'
                  : 'You blocked this user. Unblock to message them.',
              style: TextStyle(
                color: const Color(0xFFC62828),
                fontSize: screenWidth * 0.03,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ChatOutbox.instance.drain();
    }
  }

  void _onOutboxEvent(OutboxEvent event) {
    if (!mounted) return;
    final ChatMessage? sent = event.message;
    final int idx = _messages.indexWhere(
      (m) => m['pendingId'] == event.outboxId,
    );
    if (sent == null) {
      if (event.failed && idx != -1) {
        setState(() {
          _messages[idx] = <String, Object>{
            ..._messages[idx],
            'failed': true,
          };
        });
      }
      return;
    }
    if (idx != -1) {
      setState(() {
        _messages[idx] = _realMessageMap(sent);
      });
      _scrollToBottom();
      return;
    }
    if (sent.conversationId != widget.conversationId) return;
    final bool exists =
        _messages.any((m) => m['id'] == sent.id && m['id'] != null);
    if (exists) return;
    setState(() {
      _messages.add(_realMessageMap(sent));
    });
    _scrollToBottom();
  }

  Map<String, Object> _realMessageMap(ChatMessage sent) {
    final Map<String, Object> map = <String, Object>{
      'id': sent.id,
      'text': sent.text ?? '',
      'time': _formatTimeFromEpoch(sent.createdAt),
      'mine': true,
      'date': sent.createdAt,
    };
    final String? imageUrl = sent.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      map['imageUrl'] = imageUrl;
    }
    final String? audioUrl = sent.audioUrl;
    if (audioUrl != null && audioUrl.isNotEmpty) {
      map['audioUrl'] = audioUrl;
      map['duration'] = Duration(milliseconds: sent.audioDurationMs ?? 0);
    }
    if (sent.readAt != null) map['readAt'] = sent.readAt!;
    if (sent.deliveredAt != null) map['deliveredAt'] = sent.deliveredAt!;
    if (sent.expiresAt != null) {
      map['expiresAt'] = sent.expiresAt!.millisecondsSinceEpoch;
    }
    return map;
  }

  void _initSocket() {
    final socket = ChatSocketService.instance;
    socket.ensureConnected();
    _socketSub = socket.messages.listen((message) {
      if (message.conversationId != widget.conversationId) return;
      if (!mounted) return;
      if (message.isMine && message.hasMedia) return;
      final int idx =
          _messages.indexWhere((m) => m['id'] == message.id && m['id'] != null);
      if (idx != -1) {
        setState(() {
          if (message.deliveredAt != null) {
            _messages[idx]['deliveredAt'] = message.deliveredAt!;
          }
          if (message.readAt != null) {
            _messages[idx]['readAt'] = message.readAt!;
          }
        });
        return;
      }
      setState(() {
        _messages.add({
          'id': message.id,
          'text': message.text ?? '',
          if (message.imageUrl != null) 'imageUrl': message.imageUrl!,
          if (message.audioUrl != null) 'audioUrl': message.audioUrl!,
          if (message.audioUrl != null && message.audioDurationMs != null)
            'duration': Duration(milliseconds: message.audioDurationMs!),
          'time': _formatTimeFromEpoch(message.createdAt),
          'mine': message.isMine,
          'date': message.createdAt,
          if (message.deliveredAt != null) 'deliveredAt': message.deliveredAt!,
          if (message.readAt != null) 'readAt': message.readAt!,
          if (message.expiresAt != null)
            'expiresAt': message.expiresAt!.millisecondsSinceEpoch,
        });
      });
      _scrollToBottom();
    });
    _readReceiptSub = socket.readReceipts.listen((receipt) {
      if (receipt.conversationId != widget.conversationId) return;
      if (!mounted) return;
      setState(() {
        for (final m in _messages) {
          if (m['mine'] == true && m['readAt'] == null) {
            m['readAt'] = receipt.readAt;
          }
        }
      });
    });
  }

  Future<void> _loadMessages() async {
    final conversationId = widget.conversationId;
    if (conversationId == null) return;
    setState(() {
      _isLoadingMessages = true;
    });
    try {
      final messages = await ChatService.getMessages(conversationId);
      if (!mounted) return;
      setState(() {
        _messages.clear();
        for (final m in messages.reversed) {
          _messages.add({
            'id': m.id,
            'text': m.text ?? '',
            if (m.imageUrl != null) 'imageUrl': m.imageUrl!,
            if (m.audioUrl != null) 'audioUrl': m.audioUrl!,
            if (m.audioUrl != null && m.audioDurationMs != null)
              'duration': Duration(milliseconds: m.audioDurationMs!),
            'time': _formatTimeFromEpoch(m.createdAt),
            'mine': m.isMine,
            'date': m.createdAt,
            if (m.deliveredAt != null) 'deliveredAt': m.deliveredAt!,
            if (m.readAt != null) 'readAt': m.readAt!,
            if (m.expiresAt != null)
              'expiresAt': m.expiresAt!.millisecondsSinceEpoch,
          });
        }
        _isLoadingMessages = false;
      });
      ChatService.markRead(conversationId);
      if (widget.highlightMessageId != null && widget.highlightMessageId!.isNotEmpty) {
        _scrollToHighlighted();
      } else {
        _scrollToBottom();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  String _formatTimeFromEpoch(DateTime time) {
    final TimeOfDay t = TimeOfDay.fromDateTime(time);
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageFocusNode.removeListener(_onMessageFocusChanged);
    _messageFocusNode.dispose();
    _outboxSub?.cancel();
    _highlightTimer?.cancel();
    _recordingTicker?.cancel();
    _amplitudeSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _socketSub?.cancel();
    _readReceiptSub?.cancel();
    _disappearingTimer?.cancel();
    _messageController.dispose();
    _messagesScroll.dispose();
    _voiceProgress.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  String _currentTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _sendMessage() async {
    if (_isBlocked) {
      _showBlockedNotice();
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;

    final conversationId = widget.conversationId;
    if (conversationId == null) return;

    if (_selectedImages.isNotEmpty) {
      final List<Uint8List> images = List<Uint8List>.of(_selectedImages);
      final List<String?> outboxIds = <String?>[];
      for (int i = 0; i < images.length; i++) {
        final String? caption = (i == 0 && text.isNotEmpty) ? text : null;
        final String filename =
            'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        try {
          outboxIds.add(await ChatOutbox.instance.enqueueMedia(
            conversationId: conversationId,
            type: OutboxMediaType.image,
            bytes: images[i],
            text: caption,
            filename: filename,
          ));
        } catch (_) {
          outboxIds.add(null);
          try {
            final ChatMessage sent = await ChatService.sendImage(
              conversationId,
              images[i],
              caption: caption,
              filename: filename,
            );
            if (mounted) {
              setState(() {
                _messages.add({
                  'id': sent.id,
                  'text': sent.text ?? '',
                  if (sent.imageUrl != null) 'imageUrl': sent.imageUrl!,
                  'time': _formatTimeFromEpoch(sent.createdAt),
                  'mine': true,
                  'date': sent.createdAt,
                  if (sent.deliveredAt != null)
                    'deliveredAt': sent.deliveredAt!,
                  if (sent.readAt != null) 'readAt': sent.readAt!,
                  if (sent.expiresAt != null)
                    'expiresAt': sent.expiresAt!.millisecondsSinceEpoch,
                });
              });
            }
          } catch (_) {}
        }
      }
      if (!mounted) return;
      setState(() {
        _selectedImages.clear();
        _messageController.clear();
        for (int i = 0; i < images.length; i++) {
          final String? id = outboxIds[i];
          if (id == null) continue;
          _messages.add(<String, Object>{
            'id': id,
            'pendingId': id,
            'images': <Uint8List>[images[i]],
            if (i == 0 && text.isNotEmpty) 'text': text,
            'time': _currentTime(),
            'mine': true,
            'date': DateTime.now(),
          });
        }
      });
      _scrollToBottom();
      return;
    }

    if (text.isNotEmpty) {
      final socket = ChatSocketService.instance;
      if (socket.isActive && socket.sendMessage(conversationId, text)) {
        _messageController.clear();
        _scrollToBottom();
        return;
      }
      try {
        final sent = await ChatService.sendMessage(conversationId, text);
        if (!mounted) return;
        setState(() {
          _messages.add({
            'id': sent.id,
            'text': sent.text ?? text,
            'time': _formatTimeFromEpoch(sent.createdAt),
            'mine': true,
            'date': sent.createdAt,
            if (sent.deliveredAt != null) 'deliveredAt': sent.deliveredAt!,
            if (sent.readAt != null) 'readAt': sent.readAt!,
            if (sent.expiresAt != null)
              'expiresAt': sent.expiresAt!.millisecondsSinceEpoch,
          });
        });
        _messageController.clear();
        _scrollToBottom();
      } catch (_) {
        if (!mounted) return;
        SnackbarHelper.show(
          context,
          'Message failed to send. Try again.',
          icon: Icons.error_outline_rounded,
          backgroundColor: const Color(0xFFCC471B),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messagesScroll.hasClients) {
        _messagesScroll.animateTo(
          _messagesScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToHighlighted() {
    final String? id = widget.highlightMessageId;
    if (id == null || id.isEmpty) return;
    final GlobalKey? key = _messageKeys[id];
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? ctx = key.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        alignment: 0.3,
      );
      setState(() {
        _highlightedMessageId = id;
      });
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    });
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, String>? get _mediaHeaders => _authToken == null
      ? null
      : {'Authorization': 'Bearer $_authToken'};

  Future<String> _buildRecordingPath() async {
    if (kIsWeb) {
      return 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';
    }
    final dir = await getTemporaryDirectory();
    return '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  void _onAmplitude(Amplitude amplitude) {
    _receivedAmplitude = true;
    _lastAmplitude = ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
  }

  void _startRecordingTicker({bool resetTimer = true}) {
    if (resetTimer) _recordingStopwatch..reset()..start();
    final math.Random random = math.Random();
    _recordingTicker = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted || !_isRecording) return;
      setState(() {
        final double jitter = (random.nextDouble() - 0.5) * 0.08;
        final double base = _receivedAmplitude
            ? math.max(_lastAmplitude, 0.15)
            : 0.35 + random.nextDouble() * 0.12;
        _waveSamples.add((base + jitter).clamp(0.15, 1.0));
        if (_waveSamples.length > 26) _waveSamples.removeAt(0);
      });
    });
  }

  List<double> _recordingLevels() {
    const int count = 26;
    if (_waveSamples.length >= count) return _waveSamples;
    return [
      ...List<double>.filled(count - _waveSamples.length, 0.15),
      ..._waveSamples,
    ];
  }

  Future<bool> _startRecording() async {
    try {
      final bool permission = await _audioRecorder.hasPermission();
      if (!permission) {
        _showMicPermissionMessage();
        return false;
      }
      final String path = await _buildRecordingPath();
      final RecordConfig config = kIsWeb
          ? const RecordConfig(encoder: AudioEncoder.opus, bitRate: 32000)
          : const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000);
      await _audioRecorder.start(config, path: path);
      _amplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen(_onAmplitude);
      if (!mounted) return false;
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingPath = path;
        _recordingLocked = false;
        _cancelDragOffset = 0;
        _receivedAmplitude = false;
        _waveSamples.clear();
      });
      _startRecordingTicker();
      return true;
    } catch (_) {
      if (mounted) _showMicPermissionMessage();
      return false;
    }
  }

  Future<void> _pauseRecording() async {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    _recordingStopwatch.stop();
    try {
      await _audioRecorder.pause();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isPaused = false;
    });
    _recordingStopwatch.start();
    _startRecordingTicker(resetTimer: false);
  }

  Future<void> _stopRecording() async {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    _recordingStopwatch.stop();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    try {
      final bool recording = await _audioRecorder.isRecording();
      if (recording) {
        final String? saved = await _audioRecorder.stop();
        if (saved != null && saved.isNotEmpty) _recordingPath = saved;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordingLocked = false;
      _cancelDragOffset = 0;
    });
  }

  Future<void> _cancelRecording() async {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    _recordingStopwatch.stop();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    try {
      await _audioRecorder.cancel();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _recordingPath = null;
      _isRecording = false;
      _isPaused = false;
      _recordingLocked = false;
      _cancelDragOffset = 0;
      _waveSamples.clear();
    });
  }

  Future<void> _sendVoiceMessage() async {
    final Duration duration = _recordingStopwatch.elapsed;
    await _stopRecording();
    final String? path = _recordingPath;
    if (path == null || path.isEmpty || duration.inMilliseconds < 300) {
      await _cancelRecording();
      return;
    }
    final conversationId = widget.conversationId;
    if (!mounted) return;
    setState(() {
      _recordingPath = null;
      _waveSamples.clear();
    });
    final Uint8List bytes;
    try {
      bytes = await XFile(path).readAsBytes();
    } catch (_) {
      return;
    }
    if (conversationId == null || bytes.isEmpty) return;
    final String filename =
        'voice_${DateTime.now().millisecondsSinceEpoch}.${kIsWeb ? 'webm' : 'm4a'}';
    final String id;
    try {
      id = await ChatOutbox.instance.enqueueMedia(
        conversationId: conversationId,
        type: OutboxMediaType.audio,
        bytes: bytes,
        filename: filename,
        duration: duration,
      );
    } catch (_) {
      try {
        final ChatMessage sent = await ChatService.sendVoice(
          conversationId,
          bytes,
          filename: filename,
          duration: duration,
        );
        if (!mounted) return;
        setState(() {
          _messages.add({
            'id': sent.id,
            'text': sent.text ?? '',
            if (sent.audioUrl != null) 'audioUrl': sent.audioUrl!,
            if (sent.audioDurationMs != null)
              'duration': Duration(milliseconds: sent.audioDurationMs!),
            'time': _currentTime(),
            'mine': true,
            'date': sent.createdAt,
            if (sent.deliveredAt != null) 'deliveredAt': sent.deliveredAt!,
            if (sent.readAt != null) 'readAt': sent.readAt!,
            if (sent.expiresAt != null)
              'expiresAt': sent.expiresAt!.millisecondsSinceEpoch,
          });
        });
        _scrollToBottom();
      } catch (_) {}
      return;
    }
    if (!mounted) return;
    setState(() {
      _messages.add(<String, Object>{
        'id': id,
        'pendingId': id,
        'voice': path,
        'duration': duration,
        'time': _currentTime(),
        'mine': true,
        'date': DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _showMicPermissionMessage() {
    SnackbarHelper.show(
      context,
      'Microphone permission is required to record voice messages.',
      icon: Icons.mic_off,
      backgroundColor: const Color(0xFFCC471B),
    );
  }

  Future<void> _onMicTapped() async {
    if (_isBlocked) {
      _showBlockedNotice();
      return;
    }
    if (_isRecording) {
      if (_isPaused) {
        await _resumeRecording();
      } else {
        await _pauseRecording();
      }
      return;
    }
    if (_recordingPath != null) return;
    await _startRecording();
  }

  Future<void> _onMicLongPress() async {
    if (_isRecording || _recordingPath != null) return;
    await _startRecording();
  }

  void _onMicLongPressMove(LongPressMoveUpdateDetails details) {
    if (!_isRecording) return;
    final double dx = details.offsetFromOrigin.dx;
    final double dy = details.offsetFromOrigin.dy;
    setState(() {
      if (dy < -screenHeightUnit(context) * 0.08) {
        _recordingLocked = true;
        _cancelDragOffset = 0;
      } else {
        _cancelDragOffset = dx < -screenWidthUnit(context) * 0.25 ? dx : 0;
      }
    });
  }

  Future<void> _onMicLongPressEnd(LongPressEndDetails details) async {
    if (!_isRecording) return;
    if (_cancelDragOffset < -screenWidthUnit(context) * 0.25) {
      await _cancelRecording();
      return;
    }
    if (_recordingLocked) {
      setState(() => _cancelDragOffset = 0);
      return;
    }
    await _stopRecording();
  }

  void _onPanelPanUpdate(DragUpdateDetails details, double screenWidth) {
    if (!_isRecording) return;
    setState(() {
      if (_recordingLocked) {
        if (details.delta.dy > 0) {
          _cancelDragOffset += details.delta.dy;
          if (_cancelDragOffset > screenHeightUnit(context) * 0.03) {
            _recordingLocked = false;
            _cancelDragOffset = 0;
          }
        }
      } else {
        _cancelDragOffset = math.max(
          -screenWidth * 0.5,
          _cancelDragOffset + details.delta.dx,
        );
        if (details.delta.dy < -screenHeightUnit(context) * 0.04) {
          _recordingLocked = true;
          _cancelDragOffset = 0;
        }
      }
    });
  }

  Future<void> _onPanelPanEnd(DragEndDetails details) async {
    if (_cancelDragOffset < -screenWidthUnit(context) * 0.35) {
      await _cancelRecording();
    } else {
      setState(() => _cancelDragOffset = 0);
    }
  }

  void _toggleRecordingLock() {
    setState(() => _recordingLocked = !_recordingLocked);
  }

  Future<void> _playVoiceMessage(int index) async {
    final Map<String, Object> message = _messages[index];
    final String? audioUrl = message['audioUrl'] as String?;
    final String? path = message['voice'] as String?;
    try {
      if (_isPlayingVoice && _playingVoiceIndex == index) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _isPlayingVoice = false;
          _playingVoiceIndex = null;
        });
        _voiceProgress.value = 0;
        return;
      }
      await _audioPlayer.stop();
      if (audioUrl != null && audioUrl.isNotEmpty) {
        await _audioPlayer.setUrl(
          ChatService.mediaUrl(audioUrl),
          headers: _mediaHeaders,
        );
      } else if (path != null && path.isNotEmpty) {
        if (kIsWeb) {
          await _audioPlayer.setUrl(path);
        } else {
          await _audioPlayer.setFilePath(path);
        }
      } else {
        return;
      }
      if (!mounted) return;
      setState(() {
        _isPlayingVoice = true;
        _playingVoiceIndex = index;
      });
      _voiceProgress.value = 0;
      await _audioPlayer.play();
    } catch (_) {}
  }

  List<double> _voiceBars(int index, Duration duration) {
    final math.Random random =
        math.Random(duration.inMilliseconds + index * 1000);
    return List<double>.generate(38, (_) => 0.25 + random.nextDouble() * 0.75);
  }

  Future<void> _showImageSourceSheet() async {
    if (_isBlocked) {
      _showBlockedNotice();
      return;
    }
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeightUnit(context) * 0.02),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attach Photos',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidthUnit(context) * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeightUnit(context) * 0.015),
              _sheetOption(
                context,
                Icons.photo_camera,
                'Use Camera',
                ImageSource.camera,
              ),
              _sheetOption(
                context,
                Icons.photo_library,
                'Select from Gallery',
                ImageSource.gallery,
              ),
            ],
          ),
        ),
      ),
    );
    if (source == ImageSource.camera) {
      await _takePhoto();
    } else if (source == ImageSource.gallery) {
      await _pickFromGallery();
    }
  }

  Widget _sheetOption(
    BuildContext context,
    IconData icon,
    String label,
    ImageSource source,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFCD7C20), size: 30),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontSize: screenWidthUnit(context) * 0.04,
        ),
      ),
      onTap: () => Navigator.of(context).pop(source),
    );
  }

  Future<void> _takePhoto() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 72,
    );
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImages.add(bytes);
    });
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> files = await _imagePicker.pickMultiImage(
      maxWidth: 1280,
      imageQuality: 72,
    );
    if (files.isEmpty) return;
    final List<Uint8List> bytes = <Uint8List>[];
    for (final XFile file in files) {
      bytes.add(await file.readAsBytes());
    }
    if (!mounted) return;
    setState(() {
      _selectedImages.addAll(bytes);
    });
  }

  void _clearSelectedImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  void _openImageViewer(int initialIndex, List<Uint8List> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(
          initialIndex: initialIndex,
          images: images,
        ),
      ),
    );
  }

  double screenWidthUnit(BuildContext context) =>
      MediaQuery.of(context).size.width;

  double screenHeightUnit(BuildContext context) =>
      MediaQuery.of(context).size.height;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(date.year, date.month, date.day);
    final int difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    final String dd = date.day.toString().padLeft(2, '0');
    final String mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  Widget _buildDateSeparator(String label, double screenWidth) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: screenWidth * 0.02,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenWidth * 0.01,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.7),
            fontSize: screenWidth * 0.028,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildImageFan(
    List<Uint8List> images,
    double screenWidth, {
    double cardFactor = 0.5,
  }) {
    final int shown = math.min(images.length, 4);
    final double cardWidth = screenWidth * cardFactor;
    final double cardHeight = screenWidth * cardFactor;
    final double step = cardHeight * 0.055;
    final double fanHeight = cardHeight + step * (shown - 1) + screenWidth * 0.08;
    return GestureDetector(
      onTap: () => _openImageViewer(0, images),
      child: SizedBox(
        width: cardWidth + screenWidth * 0.1,
        height: fanHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            for (int i = shown - 1; i >= 0; i--)
              Positioned(
                top: (shown - 1 - i) * step,
                child: Transform.rotate(
                  angle: -0.04 - (shown - 1 - i) * 0.025,
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(
                        images[i],
                        fit: BoxFit.cover,
                        width: cardWidth,
                        height: cardHeight,
                      ),
                    ),
                  ),
                ),
              ),
            if (images.length > shown)
              Positioned(
                right: screenWidth * 0.02,
                top: step * (shown - 1),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenWidth * 0.012,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '+${images.length - shown}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImageBubble(
    Map<String, Object> message,
    String imageUrl,
    double screenWidth,
    double screenHeight,
    bool mine,
    String time,
  ) {
    final String text = message['text'] as String? ?? '';
    final String fullUrl = ChatService.mediaUrl(imageUrl);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: screenHeight * 0.006,
          bottom: screenHeight * 0.006,
          left: mine ? screenWidth * 0.15 : 0,
          right: mine ? 0 : screenWidth * 0.15,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.01,
          vertical: screenHeight * 0.008,
        ),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFCD7C20) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () => _openNetworkImageViewer(fullUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth * 0.55,
                    maxHeight: screenHeight * 0.35,
                  ),
                  child: Image.network(
                    fullUrl,
                    headers: _mediaHeaders,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _ShimmerBox(
                        child: Container(
                          width: screenWidth * 0.3,
                          height: screenHeight * 0.2,
                          color: const Color(0xFFE8E5DF),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: screenWidth * 0.3,
                      height: screenHeight * 0.2,
                      color: Colors.black.withValues(alpha: 0.05),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (text.isNotEmpty) ...[
              SizedBox(height: screenHeight * 0.006),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ],
            SizedBox(height: screenHeight * 0.003),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
              child: _timeWithTicks(
                message,
                time,
                screenWidth,
                TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontSize: screenWidth * 0.024,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNetworkImageViewer(String url) {
    final Map<String, String>? headers = _mediaHeaders;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        url,
                        headers: headers,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewStrip(double screenWidth, double screenHeight) {
    return Container(
      height: screenWidth * 0.36,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(2, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildImageFan(
                _selectedImages,
                screenWidth,
                cardFactor: 0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearSelectedImages,
            child: Container(
              width: screenWidth * 0.09,
              height: screenWidth * 0.09,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: screenWidth * 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBubble(
    Map<String, Object> message,
    int index,
    double screenWidth,
    double screenHeight,
  ) {
    final bool mine = message['mine'] as bool;
    final String time = message['time'] as String;
    final Duration duration = message['duration'] as Duration? ?? Duration.zero;
    final bool playing = _isPlayingVoice && _playingVoiceIndex == index;
    final Color accent = mine ? Colors.white : const Color(0xFFCD7C20);
    final List<double> bars = _voiceBars(index, duration);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
        margin: EdgeInsets.only(
          top: screenHeight * 0.006,
          bottom: screenHeight * 0.006,
          left: mine ? screenWidth * 0.15 : 0,
          right: mine ? 0 : screenWidth * 0.15,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.012,
        ),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFCD7C20) : Colors.white,
          borderRadius: mine
              ? const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(0),
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(25),
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _playVoiceMessage(index),
              child: Container(
                width: screenWidth * 0.11,
                height: screenWidth * 0.11,
                decoration: BoxDecoration(
                  color: mine ? Colors.white : const Color(0xFFCD7C20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.stop : Icons.play_arrow,
                  color: mine ? const Color(0xFFCD7C20) : Colors.white,
                  size: screenWidth * 0.06,
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: _voiceProgress,
                builder: (context, progress, _) {
                  final int played =
                      playing ? (progress * bars.length).round() : 0;
                  return SizedBox(
                    height: screenWidth * 0.06,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        levels: bars,
                        color: accent,
                        playedLevels: played,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: mine ? Colors.white : Colors.black,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.003),
                _timeWithTicks(
                  message,
                  time,
                  screenWidth,
                  TextStyle(
                    color: mine
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.5),
                    fontSize: screenWidth * 0.024,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingPanel(double screenWidth, double screenHeight) {
    final bool cancelling = _cancelDragOffset < -screenWidth * 0.35;
    return GestureDetector(
      onPanUpdate: (details) => _onPanelPanUpdate(details, screenWidth),
      onPanEnd: _onPanelPanEnd,
      child: Transform.translate(
        offset: Offset(_cancelDragOffset, 0),
        child: Container(
          height: screenWidth * 0.128,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(2, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleRecordingLock,
                child: Container(
                  width: screenWidth * 0.09,
                  height: screenWidth * 0.09,
                  decoration: BoxDecoration(
                    color: _recordingLocked
                        ? const Color(0xFFCD7C20)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _recordingLocked ? Icons.lock : Icons.lock_open,
                    color: _recordingLocked ? Colors.white : Colors.black,
                    size: screenWidth * 0.05,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.015),
              GestureDetector(
                onTap: _cancelRecording,
                child: Container(
                  width: screenWidth * 0.09,
                  height: screenWidth * 0.09,
                  decoration: BoxDecoration(
                    color: cancelling
                        ? const Color(0xFFE53935)
                        : Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete,
                    color: cancelling ? Colors.white : const Color(0xFFE53935),
                    size: screenWidth * 0.05,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Opacity(
                  opacity: _isPaused ? 0.4 : 1.0,
                  child: SizedBox(
                    height: screenWidth * 0.08,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        levels: _recordingLevels(),
                        color: const Color(0xFFCD7C20),
                        playedLevels: 0,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                _formatDuration(_recordingStopwatch.elapsed),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              GestureDetector(
                onTap: _sendVoiceMessage,
                child: Container(
                  width: screenWidth * 0.095,
                  height: screenWidth * 0.095,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCD7C20),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.rotate(
                    angle: math.pi * -45 / 180,
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: screenWidth * 0.045,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryTicks(Map<String, Object> message, double screenWidth) {
    if (!(message['mine'] as bool? ?? false)) return const SizedBox.shrink();
    final double size = screenWidth * 0.03;
    if (message['failed'] as bool? ?? false) {
      return Icon(
        Icons.error_outline_rounded,
        size: size,
        color: const Color(0xFFEF5350),
      );
    }
    if (message['pendingId'] != null) {
      return Icon(Icons.schedule, size: size, color: Colors.white70);
    }
    if (message['readAt'] != null) {
      return Icon(
        Icons.done_all,
        size: size,
        color: const Color(0xFF40C4FF),
      );
    }
    if (message['deliveredAt'] != null) {
      return Icon(Icons.done_all, size: size, color: Colors.white70);
    }
    return Icon(Icons.done, size: size, color: Colors.white70);
  }

  Widget _timeWithTicks(
    Map<String, Object> message,
    String time,
    double screenWidth,
    TextStyle style,
  ) {
    final bool mine = message['mine'] as bool? ?? false;
    if (!mine) {
      return Text(time, style: style);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDeliveryTicks(message, screenWidth),
        SizedBox(width: screenWidth * 0.008),
        Text(time, style: style),
      ],
    );
  }

  Widget _buildBubble(
    Map<String, Object> message,
    int index,
    double screenWidth,
    double screenHeight,
  ) {
    final bool mine = message['mine'] as bool;
    final String time = message['time'] as String;
    final String text = message['text'] as String? ?? '';
    final List<Uint8List> images = message['images'] as List<Uint8List>? ?? const [];
    final bool hasImages = images.isNotEmpty;
    final String? voice = message['voice'] as String?;
    final String? audioUrl = message['audioUrl'] as String?;
    final bool hasVoice =
        (voice != null && voice.isNotEmpty) ||
        (audioUrl != null && audioUrl.isNotEmpty);
    final String? imageUrl = message['imageUrl'] as String?;
    final bool hasNetworkImage = imageUrl != null && imageUrl.isNotEmpty;

    if (hasVoice) {
      return _buildVoiceBubble(message, index, screenWidth, screenHeight);
    }

    if (hasNetworkImage) {
      return _buildNetworkImageBubble(
        message,
        imageUrl,
        screenWidth,
        screenHeight,
        mine,
        time,
      );
    }

    if (hasImages) {
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: screenHeight * 0.006,
            bottom: screenHeight * 0.006,
            left: mine ? screenWidth * 0.15 : 0,
            right: mine ? 0 : screenWidth * 0.15,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.01,
            vertical: screenHeight * 0.008,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildImageFan(images, screenWidth),
              if (text.isNotEmpty) ...[
                SizedBox(height: screenHeight * 0.006),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ],
              SizedBox(height: screenHeight * 0.003),
              _timeWithTicks(
                message,
                time,
                screenWidth,
                TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontSize: screenWidth * 0.024,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
        margin: EdgeInsets.only(
          top: screenHeight * 0.006,
          bottom: screenHeight * 0.006,
          left: mine ? screenWidth * 0.15 : 0,
          right: mine ? 0 : screenWidth * 0.15,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.012,
        ),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFCD7C20) : Colors.white,
          borderRadius: mine
              ? const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(0),
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(25),
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : Colors.black,
                fontSize: screenWidth * 0.035,
              ),
            ),
            SizedBox(height: screenHeight * 0.003),
            _timeWithTicks(
              message,
              time,
              screenWidth,
              TextStyle(
                color: mine
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.5),
                fontSize: screenWidth * 0.024,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final List<Widget> chatItems = <Widget>[];
    DateTime? previousDate;
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final DateTime date = message['date'] as DateTime;
      if (previousDate == null || !_isSameDay(previousDate, date)) {
        chatItems.add(_buildDateSeparator(_dateLabel(date), screenWidth));
      }
      final String? messageId = message['id'] as String?;
      Widget bubble = _buildBubble(message, i, screenWidth, screenHeight);
      if (message['failed'] as bool? ?? false) {
        bubble = GestureDetector(
          onTap: () {
            SnackbarHelper.show(
              context,
              'Retrying send...',
              icon: Icons.info_outline_rounded,
              backgroundColor: const Color(0xFFCC471B),
            );
            ChatOutbox.instance.drain();
          },
          child: bubble,
        );
      }
      if (messageId != null && messageId.isNotEmpty) {
        if (messageId == _highlightedMessageId) {
          bubble = Container(
            margin: EdgeInsets.symmetric(vertical: screenHeight * 0.004),
            padding: EdgeInsets.all(screenWidth * 0.012),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFCC471B),
                width: 1.5,
              ),
            ),
            child: bubble,
          );
        }
        chatItems.add(
          KeyedSubtree(
            key: _messageKeys.putIfAbsent(messageId, () => GlobalKey()),
            child: bubble,
          ),
        );
      } else {
        chatItems.add(bubble);
      }
      previousDate = date;
    }

    final bool hasPreview = _selectedImages.isNotEmpty;
    final double previewHeight =
        hasPreview ? screenWidth * 0.36 + screenHeight * 0.01 : 0;
    final double recordingBarHeight = _recordingPath != null
        ? screenWidth * 0.128 + screenHeight * 0.01
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: screenHeight * 0.0,
              bottom: screenHeight * 0.0,
              right: (screenWidth + screenWidth * 1) / 300,
              child: Image.asset(
                'assets/backgroundcolors/normalscreen.png',
                width: screenWidth * 1.08,
                height: screenHeight * 0.9,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.035,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: screenWidth * 0.128,
                  height: screenWidth * 0.128,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C2B0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: screenWidth * 0.10,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top:
                  screenHeight * 0.035 +
                  (screenWidth * 0.128 - screenWidth * 0.146) / 2,
              left:
                  screenWidth * 0.04 + screenWidth * 0.128 + screenWidth * 0.03,
              child: Container(
                width: screenWidth * 0.146,
                height: screenWidth * 0.146,
                decoration: BoxDecoration(
                  color: widget.color ?? const Color(0xFF7EED27),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.name != null && widget.name!.isNotEmpty
                        ? widget.name![0]
                        : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top:
                  screenHeight * 0.035 +
                  (screenWidth * 0.128 - screenWidth * 0.146) / 2,
              left:
                  screenWidth * 0.04 +
                  screenWidth * 0.128 +
                  screenWidth * 0.03 +
                  screenWidth * 0.146 +
                  screenWidth * 0.03,
              right: screenWidth * 0.04,
              height: screenWidth * 0.146,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          widget.status ?? 'Online',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                (widget.status ?? 'Online')
                                    .toLowerCase()
                                    .contains('online')
                                ? const Color(0xFF4CAF50)
                                : Colors.black.withValues(alpha: 0.5),
                            fontSize: screenWidth * 0.028,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Icon(
                    Icons.phone_outlined,
                    color: const Color(0xFFCD7C20),
                    size: screenWidth * 0.08,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ServiceDetailsScreen(),
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: const Color(0xFFCD7C20),
                      size: screenWidth * 0.08,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  PopupMenuButton<_ChatMenuAction>(
                    onSelected: _handleChatMenuAction,
                    offset: const Offset(0, 8),
                    elevation: 16,
                    color: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    itemBuilder: (ctx) => [
                      _buildChatMenuItem(
                        icon: Icons.timer_outlined,
                        label: 'Disappearing messages',
                        dotColor: const Color(0xFFF3CA9B),
                        value: _ChatMenuAction.disappearing,
                        screenWidth: screenWidth,
                      ),
                      _buildChatMenuItem(
                        icon: Icons.delete_outline,
                        label: 'Clear chat',
                        dotColor: const Color(0xFFE57373),
                        value: _ChatMenuAction.clearChat,
                        screenWidth: screenWidth,
                      ),
                      const PopupMenuDivider(height: 1),
                      _buildChatMenuItem(
                        icon: Icons.person_off_outlined,
                        label: _blocked ? 'Unblock user' : 'Block user',
                        dotColor: _blocked
                            ? const Color(0xFF90A4AE)
                            : const Color(0xFFFF6B6B),
                        value: _ChatMenuAction.block,
                        screenWidth: screenWidth,
                      ),
                      _buildChatMenuItem(
                        icon: Icons.flag_outlined,
                        label: 'Report user',
                        dotColor: const Color(0xFFFFA726),
                        value: _ChatMenuAction.report,
                        screenWidth: screenWidth,
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top:
                  screenHeight * 0.035 +
                  screenWidth * 0.146 +
                  screenHeight * 0.01,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              bottom:
                  screenHeight * 0.02 +
                  screenWidth * 0.128 +
                  screenHeight * 0.015 +
                  previewHeight +
                  recordingBarHeight,
              child: _isLoadingMessages && _messages.isEmpty
                  ? const _MessageSkeletonLoader()
                  : _messages.isEmpty
                      ? _MessageEmptyState(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    )
                  : ListView(
                      controller: _messagesScroll,
                      padding: EdgeInsets.zero,
                      children: chatItems,
                    ),
            ),
            Positioned(
              bottom: screenHeight * 0.02,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasPreview) ...[
                    _buildPreviewStrip(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.01),
                  ],
                  if (_recordingPath != null) ...[
                    _buildRecordingPanel(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.01),
                  ],
                  if (_isBlocked) ...[
                    _buildBlockedBanner(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.01),
                  ],
                  Row(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      width: screenWidth * 0.128,
                      height: screenWidth * 0.128,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Container(
                      height: screenWidth * 0.128,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _messageFocusNode.hasFocus
                              ? const Color(0xFFCC471B)
                              : Colors.transparent,
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(2, 7),
                          ),
                        ],
                      ),
                      child: SizedBox.expand(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _messageFocusNode,
                              onSubmitted: (_) => _sendMessage(),
                              textAlignVertical: const TextAlignVertical(y: -0.85),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.035,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type Message Here...',
                                hintStyle: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  fontSize: screenWidth * 0.032,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: 0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: screenWidth * 0.095,
                              height: screenWidth * 0.095,
                              margin: EdgeInsets.only(
                                right: screenWidth * 0.02,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFCD7C20),
                                shape: BoxShape.circle,
                              ),
                              child: Transform.rotate(
                                angle: math.pi * -45 / 180,
                                child: Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: screenWidth * 0.045,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  GestureDetector(
                    onTap: _onMicTapped,
                    onLongPress: _onMicLongPress,
                    onLongPressMoveUpdate: _onMicLongPressMove,
                    onLongPressEnd: _onMicLongPressEnd,
                    child: Container(
                      width: screenWidth * 0.128,
                      height: screenWidth * 0.128,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFCD7C20),
                            Color(0xFFF4F4F4),
                            Color(0xFFF5F5F5),
                            Color(0xFFCD7C20),
                          ],
                          stops: [0.0, 0.13, 0.19, 0.83],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isPaused
                              ? Icons.play_arrow
                              : _isRecording
                                  ? Icons.pause
                                  : Icons.mic,
                          color: _isRecording
                              ? const Color(0xFFE53935)
                              : Colors.black,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.levels,
    required this.color,
    required this.playedLevels,
  });

  final List<double> levels;
  final Color color;
  final int playedLevels;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.width <= 0 || size.height <= 0) return;
    final double count = levels.length.toDouble();
    final double gap = math.min(size.width * 0.015, 2.0);
    final double barWidth = (size.width - gap * (count - 1)) / count;
    if (barWidth <= 0) return;
    final Paint paint = Paint();
    for (int i = 0; i < levels.length; i++) {
      final double height = levels[i].clamp(0.06, 1.0) * size.height;
      final double x = i * (barWidth + gap);
      paint.color = i < playedLevels ? color : color.withValues(alpha: 0.4);
      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - height) / 2, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.levels != levels ||
        oldDelegate.playedLevels != playedLevels ||
        oldDelegate.color != color;
  }
}

class _ImageViewerScreen extends StatefulWidget {
  const _ImageViewerScreen({required this.initialIndex, required this.images});

  final int initialIndex;
  final List<Uint8List> images;

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) => InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  widget.images[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 26),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageEmptyState extends StatefulWidget {
  const _MessageEmptyState({
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  State<_MessageEmptyState> createState() => _MessageEmptyStateState();
}

class _MessageEmptyStateState extends State<_MessageEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sw = widget.screenWidth;
    final double sh = widget.screenHeight;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MessageEmptyScene(sw: sw, controller: _controller),
            SizedBox(height: sh * 0.015),
            Text(
              'Say hello!',
              style: TextStyle(
                color: Colors.black,
                fontSize: sw * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sh * 0.008),
            Text(
              'This is the start of your conversation. '
              'Send your first message below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
                fontSize: sw * 0.032,
              ),
            ),
            SizedBox(height: sh * 0.015),
            _BounceArrow(sw: sw, t: _controller),
          ],
        ),
      ),
    );
  }
}

class _MessageEmptyScene extends StatelessWidget {
  const _MessageEmptyScene({required this.sw, required this.controller});

  final double sw;
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: sw * 0.6,
      height: sw * 0.6,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final double t = controller.value;
          final double bob = math.sin(t * math.pi * 2) * sw * 0.015;
          final bool blinking = (t > 0.4 && t < 0.48) || (t > 0.88 && t < 0.96);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: sw * 0.04,
                top: sw * 0.1 + bob * 0.5,
                child: _Sparkle(
                  sw: sw,
                  color: kEmptyAccent,
                  t: t,
                ),
              ),
              Positioned(
                right: sw * 0.05,
                top: sw * 0.05 - bob,
                child: _Sparkle(
                  sw: sw,
                  color: kEmptyYellow,
                  t: (t + 0.3) % 1,
                ),
              ),
              Positioned(
                left: sw * 0.14,
                bottom: sw * 0.12 - bob * 0.4,
                child: _Sparkle(
                  sw: sw,
                  color: const Color(0xFFFFB3C1),
                  t: (t + 0.6) % 1,
                ),
              ),
              Positioned(
                right: 0,
                top: sw * 0.15 - bob,
                child: TypingDotsBubble(sw: sw, t: t),
              ),
              Transform.translate(
                offset: Offset(0, bob),
                child: ChatCharacterBubble(
                  sw: sw,
                  blinking: blinking,
                  lookDown: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageSkeletonLoader extends StatelessWidget {
  const _MessageSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double w = size.width;
    final double h = size.height;
    final Color grey = const Color(0xFFE8E5DF);

    final BorderRadius leftRadius = const BorderRadius.only(
      topLeft: Radius.circular(0),
      topRight: Radius.circular(25),
      bottomLeft: Radius.circular(25),
      bottomRight: Radius.circular(25),
    );
    final BorderRadius rightRadius = const BorderRadius.only(
      topLeft: Radius.circular(25),
      topRight: Radius.circular(0),
      bottomLeft: Radius.circular(25),
      bottomRight: Radius.circular(25),
    );

    Widget block(double width, double height, BorderRadius radius) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: grey, borderRadius: radius),
      );
    }

    Widget avatar() => block(
          w * 0.09,
          w * 0.09,
          BorderRadius.circular(w * 0.045),
        );

    Widget theirs(double width, double height) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          avatar(),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: block(width, height, leftRadius),
            ),
          ),
        ],
      );
    }

    Widget mine(double width, double height) {
      return Align(
        alignment: Alignment.centerRight,
        child: block(width, height, rightRadius),
      );
    }

    final double gap = h * 0.014;

    final Widget content = SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          theirs(w * 0.55, h * 0.05),
          SizedBox(height: gap),
          mine(w * 0.42, h * 0.04),
          SizedBox(height: gap),
          mine(w * 0.62, h * 0.065),
          SizedBox(height: gap),
          theirs(w * 0.68, h * 0.055),
          SizedBox(height: gap),
          mine(w * 0.5, h * 0.05),
          SizedBox(height: gap),
          theirs(w * 0.4, h * 0.045),
          SizedBox(height: gap),
          mine(w * 0.66, h * 0.08),
        ],
      ),
    );

    return _ShimmerBox(child: content);
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.child});

  final Widget child;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double shift = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.5 + shift * 3, 0),
            end: Alignment(-0.5 + shift * 3, 0),
            colors: const [
              Color(0xFFE4E1DA),
              Color(0xFFFAF8F3),
              Color(0xFFE4E1DA),
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: widget.child,
        );
      },
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.sw,
    required this.color,
    required this.t,
  });

  final double sw;
  final Color color;
  final double t;

  @override
  Widget build(BuildContext context) {
    final double scale = 0.7 + 0.3 * math.sin(t * math.pi * 2);
    final double opacity = 0.5 + 0.5 * math.sin((t + 0.25) * math.pi * 2);
    return Transform.scale(
      scale: scale,
      child: CustomPaint(
        size: Size(sw * 0.05, sw * 0.05),
        painter: StarPainter(color: color.withValues(alpha: opacity)),
      ),
    );
  }
}

class _BounceArrow extends StatelessWidget {
  const _BounceArrow({required this.sw, required this.t});

  final double sw;
  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, _) {
        final double dy = math.sin(t.value * math.pi * 2) * sw * 0.012;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_downward_rounded,
                color: kEmptyAccent,
                size: sw * 0.05,
              ),
              Text(
                'Type your message below',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontSize: sw * 0.026,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _SheetIconHeader extends StatelessWidget {
  const _SheetIconHeader({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    return Row(
      children: [
        Container(
          width: sw * 0.11,
          height: sw * 0.11,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(sw * 0.03),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: sw * 0.042,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: sh * 0.004),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: sw * 0.03,
                  height: 1.3,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisappearingOption {
  const _DisappearingOption({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String mode;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _DisappearingMessagesSheet extends StatelessWidget {
  const _DisappearingMessagesSheet({
    required this.currentMode,
    required this.onSelect,
  });

  final String currentMode;
  final Future<void> Function(String mode) onSelect;

  static const List<_DisappearingOption> _options = [
    _DisappearingOption(
      mode: 'OFF',
      title: 'Off',
      subtitle: 'Messages stay forever',
      icon: Icons.timer_off_outlined,
    ),
    _DisappearingOption(
      mode: '24H',
      title: '24 hours',
      subtitle: 'Messages disappear after 24 hours',
      icon: Icons.schedule_outlined,
    ),
    _DisappearingOption(
      mode: '7D',
      title: '7 days',
      subtitle: 'Messages disappear after 7 days',
      icon: Icons.calendar_month_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        sw * 0.05,
        sh * 0.014,
        sw * 0.05,
        sh * 0.03,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetGrabber(),
          SizedBox(height: sh * 0.02),
          const _SheetIconHeader(
            icon: Icons.timer_outlined,
            color: Color(0xFFCC471B),
            background: Color(0xFFFFE9DE),
            title: 'Disappearing messages',
            subtitle:
                'New messages in this chat disappear after the time you choose.',
          ),
          SizedBox(height: sh * 0.02),
          for (final option in _options) ...[
            _disappearingCard(context, option, sw, sh),
            SizedBox(height: sh * 0.012),
          ],
        ],
      ),
    );
  }

  Widget _disappearingCard(
    BuildContext context,
    _DisappearingOption option,
    double sw,
    double sh,
  ) {
    final bool selected = currentMode == option.mode;
    return GestureDetector(
      onTap: () => onSelect(option.mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04,
          vertical: sh * 0.014,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1EA) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFCC471B) : const Color(0xFFEFE7DD),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: sw * 0.09,
              height: sw * 0.09,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFCC471B)
                    : const Color(0xFFF5F2EC),
                borderRadius: BorderRadius.circular(sw * 0.045),
              ),
              child: Icon(
                option.icon,
                color: selected ? Colors.white : Colors.black54,
                size: sw * 0.045,
              ),
            ),
            SizedBox(width: sw * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: sw * 0.036,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: sh * 0.003),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: sw * 0.028,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: sw * 0.05,
              height: sw * 0.05,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFCC471B) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFCC471B)
                      : const Color(0xFFCFC8BF),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearChatSheet extends StatefulWidget {
  const _ClearChatSheet({required this.contactName, required this.onClear});

  final String? contactName;
  final Future<void> Function() onClear;

  @override
  State<_ClearChatSheet> createState() => _ClearChatSheetState();
}

class _ClearChatSheetState extends State<_ClearChatSheet> {
  bool _busy = false;

  Future<void> _handleClear() async {
    setState(() => _busy = true);
    await widget.onClear();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        sw * 0.05,
        sh * 0.014,
        sw * 0.05,
        sh * 0.03,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetGrabber(),
          SizedBox(height: sh * 0.02),
          _SheetIconHeader(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFE53935),
            background: const Color(0xFFFDECEA),
            title: 'Clear chat?',
            subtitle:
                'This deletes every message in this chat for both of you. This cannot be undone.',
          ),
          SizedBox(height: sh * 0.024),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFE0D8CD)),
                    padding: EdgeInsets.symmetric(vertical: sh * 0.017),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _handleClear,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    padding: EdgeInsets.symmetric(vertical: sh * 0.017),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Clear chat',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlockUserSheet extends StatefulWidget {
  const _BlockUserSheet({
    required this.blocking,
    required this.contactName,
    required this.onAction,
  });

  final bool blocking;
  final String? contactName;
  final Future<void> Function() onAction;

  @override
  State<_BlockUserSheet> createState() => _BlockUserSheetState();
}

class _BlockUserSheetState extends State<_BlockUserSheet> {
  bool _busy = false;

  Future<void> _handleAction() async {
    setState(() => _busy = true);
    await widget.onAction();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    final String name = widget.contactName ?? 'this user';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        sw * 0.05,
        sh * 0.014,
        sw * 0.05,
        sh * 0.03,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetGrabber(),
          SizedBox(height: sh * 0.02),
          _SheetIconHeader(
            icon: widget.blocking
                ? Icons.person_off_outlined
                : Icons.person_add_alt_1_outlined,
            color: widget.blocking
                ? const Color(0xFFE53935)
                : const Color(0xFF4CAF50),
            background: widget.blocking
                ? const Color(0xFFFDECEA)
                : const Color(0xFFE7F5E3),
            title: widget.blocking ? 'Block $name?' : 'Unblock $name?',
            subtitle: widget.blocking
                ? 'They will no longer be able to send you messages, and you will not see their activity. You can unblock them anytime.'
                : 'You will be able to message and call each other again.',
          ),
          SizedBox(height: sh * 0.024),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFE0D8CD)),
                    padding: EdgeInsets.symmetric(vertical: sh * 0.017),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _handleAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.blocking
                        ? const Color(0xFFE53935)
                        : const Color(0xFF4CAF50),
                    padding: EdgeInsets.symmetric(vertical: sh * 0.017),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          widget.blocking ? 'Block' : 'Unblock',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportReason {
  const _ReportReason({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

class _ReportUserSheet extends StatefulWidget {
  const _ReportUserSheet({required this.contactName, required this.onSubmit});

  final String? contactName;
  final Future<void> Function(String reason) onSubmit;

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  static const List<_ReportReason> _reasons = [
    _ReportReason(title: 'Spam or scam', icon: Icons.campaign_outlined),
    _ReportReason(title: 'Harassment', icon: Icons.thumb_down_outlined),
    _ReportReason(
      title: 'Inappropriate content',
      icon: Icons.warning_amber_outlined,
    ),
    _ReportReason(title: 'Impersonation', icon: Icons.badge_outlined),
  ];

  final TextEditingController _details = TextEditingController();
  int? _selectedIndex;
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final String? picked =
        _selectedIndex != null ? _reasons[_selectedIndex!].title : null;
    final String custom = _details.text.trim();
    final String reason = picked ?? (custom.isEmpty ? '' : custom);
    if (reason.isEmpty) {
      SnackbarHelper.show(
        context,
        'Please choose a reason for your report',
        icon: Icons.error_outline_rounded,
        backgroundColor: const Color(0xFFCC471B),
      );
      return;
    }
    setState(() => _busy = true);
    await widget.onSubmit(reason);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          sw * 0.05,
          sh * 0.014,
          sw * 0.05,
          sh * 0.03,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetGrabber(),
              SizedBox(height: sh * 0.02),
              _SheetIconHeader(
                icon: Icons.flag_outlined,
                color: const Color(0xFFCD7C20),
                background: const Color(0xFFFFF1DC),
                title: 'Report ${widget.contactName ?? 'user'}',
                subtitle:
                    'Tell us what happened. Your report is confidential and helps keep the community safe.',
              ),
              SizedBox(height: sh * 0.02),
              for (int i = 0; i < _reasons.length; i++) ...[
                _reasonCard(context, i, sw, sh),
                SizedBox(height: sh * 0.01),
              ],
              SizedBox(height: sh * 0.006),
              TextField(
                controller: _details,
                maxLines: 3,
                maxLength: 200,
                enabled: !_busy,
                decoration: InputDecoration(
                  hintText: 'Add more details (optional)',
                  hintStyle: TextStyle(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F4EE),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFCC471B),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: sh * 0.018),
              SizedBox(
                height: sh * 0.055,
                child: FilledButton(
                  onPressed: _busy ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFCC471B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit report',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reasonCard(
    BuildContext context,
    int index,
    double sw,
    double sh,
  ) {
    final bool selected = _selectedIndex == index;
    final _ReportReason reason = _reasons[index];
    return GestureDetector(
      onTap: _busy ? null : () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04,
          vertical: sh * 0.013,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1EA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFCC471B) : const Color(0xFFEFE7DD),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: sw * 0.08,
              height: sw * 0.08,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFCC471B)
                    : const Color(0xFFF5F2EC),
                borderRadius: BorderRadius.circular(sw * 0.04),
              ),
              child: Icon(
                reason.icon,
                color: selected ? Colors.white : Colors.black54,
                size: sw * 0.04,
              ),
            ),
            SizedBox(width: sw * 0.03),
            Expanded(
              child: Text(
                reason.title,
                style: TextStyle(
                  fontSize: sw * 0.034,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: sw * 0.045,
              height: sw * 0.045,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFCC471B) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFCC471B)
                      : const Color(0xFFCFC8BF),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

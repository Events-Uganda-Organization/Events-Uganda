import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'outbox_storage.dart';

OutboxStorage createOutboxStorage() => OutboxStorageIo();

class OutboxStorageIo implements OutboxStorage {
  Directory? _dir;

  Future<Directory> _directory() async {
    final dir = _dir;
    if (dir != null) return dir;
    final docs = await getApplicationDocumentsDirectory();
    final outbox = Directory('${docs.path}/chat_outbox');
    if (!await outbox.exists()) {
      await outbox.create(recursive: true);
    }
    _dir = outbox;
    return outbox;
  }

  @override
  Future<void> writeBytes(String key, Uint8List bytes) async {
    final dir = await _directory();
    await File('${dir.path}/$key').writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> readBytes(String key) async {
    final dir = await _directory();
    final file = File('${dir.path}/$key');
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> deleteBytes(String key) async {
    final dir = await _directory();
    final file = File('${dir.path}/$key');
    if (await file.exists()) {
      await file.delete();
    }
  }
}

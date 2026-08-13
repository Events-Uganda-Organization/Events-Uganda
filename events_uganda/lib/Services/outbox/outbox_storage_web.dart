import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'outbox_storage.dart';

OutboxStorage createOutboxStorage() => OutboxStorageWeb();

class OutboxStorageWeb implements OutboxStorage {
  static const String _prefix = 'chat_outbox_media_';

  @override
  Future<void> writeBytes(String key, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefix + key, base64Encode(bytes));
  }

  @override
  Future<Uint8List?> readBytes(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefix + key);
    if (raw == null) return null;
    return base64Decode(raw);
  }

  @override
  Future<void> deleteBytes(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefix + key);
  }
}

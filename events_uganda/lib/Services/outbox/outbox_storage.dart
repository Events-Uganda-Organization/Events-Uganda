import 'dart:typed_data';

abstract class OutboxStorage {
  Future<void> writeBytes(String key, Uint8List bytes);
  Future<Uint8List?> readBytes(String key);
  Future<void> deleteBytes(String key);
}

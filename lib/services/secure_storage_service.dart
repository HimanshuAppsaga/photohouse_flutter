import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _deviceIdKey = 'device_id';
  static const String _uploadQueueKey = 'upload_queue';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: _userKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Retrieves or creates a stable per-install device name / identifier
  Future<String> getOrCreateDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      deviceId = 'PhotoHouse Mobile App ($now)';
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  Future<void> saveUploadQueue(String queueJson) async {
    await _storage.write(key: _uploadQueueKey, value: queueJson);
  }

  Future<String?> getUploadQueue() async {
    return await _storage.read(key: _uploadQueueKey);
  }

  Future<void> deleteUploadQueue() async {
    await _storage.delete(key: _uploadQueueKey);
  }

  Future<String?> readKey(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> writeKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  String _userScope(String? userId) => (userId != null && userId.isNotEmpty) ? userId : 'guest';

  Future<void> saveSelectedProvider(String providerId, {String? userId}) async {
    final key = 'ai_provider_${_userScope(userId)}';
    await _storage.write(key: key, value: providerId);
  }

  Future<String?> getSelectedProvider({String? userId}) async {
    final key = 'ai_provider_${_userScope(userId)}';
    return await _storage.read(key: key);
  }

  Future<void> saveSelectedModel(String modelId, {String? userId}) async {
    final key = 'ai_model_${_userScope(userId)}';
    await _storage.write(key: key, value: modelId);
  }

  Future<String?> getSelectedModel({String? userId}) async {
    final key = 'ai_model_${_userScope(userId)}';
    return await _storage.read(key: key);
  }

  Future<void> saveApiKey(String providerId, String apiKey, {String? userId}) async {
    final key = 'api_key_${_userScope(userId)}_$providerId';
    await _storage.write(key: key, value: apiKey);
  }

  Future<String?> getApiKey(String providerId, {String? userId}) async {
    final key = 'api_key_${_userScope(userId)}_$providerId';
    return await _storage.read(key: key);
  }

  Future<Map<String, String>> getAllApiKeys(List<String> providerIds, {String? userId}) async {
    Map<String, String> keys = {};
    for (var id in providerIds) {
      final key = await getApiKey(id, userId: userId);
      if (key != null && key.isNotEmpty) {
        keys[id] = key;
      }
    }
    return keys;
  }

  Future<void> clearUserData(String? userId) async {
    final scope = _userScope(userId);
    await _storage.delete(key: 'ai_provider_$scope');
    await _storage.delete(key: 'ai_model_$scope');
    for (var provider in ['google', 'openai', 'anthropic', 'groq']) {
      await _storage.delete(key: 'api_key_${scope}_$provider');
    }
  }
}

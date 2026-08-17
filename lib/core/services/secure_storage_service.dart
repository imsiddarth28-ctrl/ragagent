import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  static const _keyProvider = 'ai_provider';
  static const _keyModel = 'ai_model';
  static const _prefixApiKey = 'api_key_';

  Future<void> saveSelectedProvider(String providerId) async {
    await _storage.write(key: _keyProvider, value: providerId);
  }

  Future<String?> getSelectedProvider() async {
    return await _storage.read(key: _keyProvider);
  }

  Future<void> saveSelectedModel(String modelId) async {
    await _storage.write(key: _keyModel, value: modelId);
  }

  Future<String?> getSelectedModel() async {
    return await _storage.read(key: _keyModel);
  }

  Future<void> saveApiKey(String providerId, String key) async {
    await _storage.write(key: '$_prefixApiKey$providerId', value: key);
  }

  Future<String?> getApiKey(String providerId) async {
    return await _storage.read(key: '$_prefixApiKey$providerId');
  }

  Future<Map<String, String>> getAllApiKeys(List<String> providerIds) async {
    Map<String, String> keys = {};
    for (var id in providerIds) {
      final key = await getApiKey(id);
      if (key != null) keys[id] = key;
    }
    return keys;
  }
}

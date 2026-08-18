import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ai_config_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../auth/data/auth_provider.dart';

final secureStorageProvider = Provider((ref) => SecureStorageService());

class AISettingsNotifier extends StateNotifier<AISettings> {
  final Ref _ref;
  final SecureStorageService _storage;
  String? _currentUserId;

  AISettingsNotifier(this._ref, this._storage) : super(AISettings(
    selectedProvider: null,
    selectedModel: null,
    apiKeys: {},
  )) {
    final auth = _ref.read(authProvider);
    _currentUserId = auth.user?.id ?? (auth.isGuest ? 'guest' : null);
    _loadFromStorage();

    // Re-load settings whenever auth user changes
    _ref.listen<AuthState>(authProvider, (previous, next) {
      final newUserId = next.user?.id ?? (next.isGuest ? 'guest' : null);
      if (_currentUserId != newUserId) {
        _currentUserId = newUserId;
        _loadFromStorage();
      }
    });
  }

  Future<void> _loadFromStorage() async {
    final provider = await _storage.getSelectedProvider(userId: _currentUserId);
    final model = await _storage.getSelectedModel(userId: _currentUserId);
    final savedKeys = await _storage.getAllApiKeys(['google', 'openai', 'anthropic', 'groq'], userId: _currentUserId);
    final webSearch = await _storage.getAllowWebSearch(userId: _currentUserId);
    
    state = state.copyWith(
      selectedProvider: provider,
      selectedModel: model,
      apiKeys: savedKeys,
      allowWebSearch: webSearch,
    );
  }

  void setProvider(String providerId) {
    if (state.selectedProvider != providerId) {
      state = state.copyWith(
        selectedProvider: providerId,
        selectedModel: null, 
      );
      _storage.saveSelectedProvider(providerId, userId: _currentUserId);
      _ref.read(connectionTestProvider.notifier).reset();
    }
  }

  void setModel(String modelId) {
    if (state.selectedModel != modelId) {
      state = state.copyWith(selectedModel: modelId);
      _storage.saveSelectedModel(modelId, userId: _currentUserId);
      _ref.read(connectionTestProvider.notifier).reset();
    }
  }

  void setApiKey(String providerId, String key) {
    final newKeys = Map<String, String>.from(state.apiKeys);
    newKeys[providerId] = key;
    state = state.copyWith(apiKeys: newKeys);
    _storage.saveApiKey(providerId, key, userId: _currentUserId);
    _ref.read(connectionTestProvider.notifier).reset();
  }

  void setTopK(int val) {
    state = state.copyWith(topK: val);
  }

  void setAllowWebSearch(bool val) {
    state = state.copyWith(allowWebSearch: val);
    _storage.saveAllowWebSearch(val, userId: _currentUserId);
  }

  void reload() {
    final auth = _ref.read(authProvider);
    _currentUserId = auth.user?.id ?? (auth.isGuest ? 'guest' : null);
    _loadFromStorage();
  }
}

final aiSettingsProvider = StateNotifierProvider<AISettingsNotifier, AISettings>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AISettingsNotifier(ref, storage);
});

final providersProvider = FutureProvider<List<AIProviderModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getProviders();
});

final modelsProvider = FutureProvider.family<List<AIModel>, String>((ref, providerId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getModels(providerId);
});

class ConnectionTestNotifier extends StateNotifier<ConnectionTestState> {
  final ApiService _apiService;
  final Ref _ref;

  ConnectionTestNotifier(this._apiService, this._ref) : super(ConnectionTestState());

  Future<void> testConnection() async {
    final settings = _ref.read(aiSettingsProvider);
    final providerId = settings.selectedProvider;
    final modelId = settings.selectedModel;
    final apiKey = providerId != null ? settings.apiKeys[providerId] : null;

    if (providerId == null || modelId == null || apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(
        result: ConnectionTestResult(success: false, message: 'Please select provider, model and enter API key.'),
      );
      return;
    }

    state = state.copyWith(isLoading: true, result: null);

    try {
      final result = await _apiService.testConnection(
        providerId: providerId,
        modelId: modelId,
        apiKey: apiKey,
      );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        result: ConnectionTestResult(success: false, message: 'Unexpected error: $e'),
      );
    }
  }

  void reset() {
    state = ConnectionTestState();
  }
}

final connectionTestProvider = StateNotifierProvider<ConnectionTestNotifier, ConnectionTestState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ConnectionTestNotifier(apiService, ref);
});

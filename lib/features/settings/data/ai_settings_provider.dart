import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ai_config_model.dart';
import '../../../core/services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class AISettingsNotifier extends StateNotifier<AISettings> {
  final Ref _ref;

  AISettingsNotifier(this._ref) : super(AISettings(
    selectedProvider: null,
    selectedModel: null,
    apiKeys: {},
  ));

  void setProvider(String providerId) {
    if (state.selectedProvider != providerId) {
      state = state.copyWith(
        selectedProvider: providerId,
        selectedModel: null, // Reset model when provider changes
      );
      // Reset test state when configuration changes
      _ref.read(connectionTestProvider.notifier).reset();
    }
  }

  void setModel(String modelId) {
    if (state.selectedModel != modelId) {
      state = state.copyWith(selectedModel: modelId);
      // Reset test state when configuration changes
      _ref.read(connectionTestProvider.notifier).reset();
    }
  }

  void setApiKey(String providerId, String key) {
    final newKeys = Map<String, String>.from(state.apiKeys);
    newKeys[providerId] = key;
    state = state.copyWith(apiKeys: newKeys);
    // Reset test state when configuration changes
    _ref.read(connectionTestProvider.notifier).reset();
  }

  void setTopK(int val) {
    state = state.copyWith(topK: val);
  }
}

final aiSettingsProvider = StateNotifierProvider<AISettingsNotifier, AISettings>((ref) {
  return AISettingsNotifier(ref);
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

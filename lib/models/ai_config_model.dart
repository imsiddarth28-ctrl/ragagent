class AIProviderModel {
  final String id;
  final String name;

  AIProviderModel({required this.id, required this.name});

  factory AIProviderModel.fromJson(Map<String, dynamic> json) {
    return AIProviderModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

class AIModel {
  final String id;
  final String name;

  AIModel({required this.id, required this.name});

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

class AISettings {
  final String? selectedProvider;
  final String? selectedModel;
  final Map<String, String> apiKeys;
  final int topK;

  AISettings({
    this.selectedProvider,
    this.selectedModel,
    required this.apiKeys,
    this.topK = 4,
  });

  AISettings copyWith({
    String? selectedProvider,
    String? selectedModel,
    Map<String, String>? apiKeys,
    int? topK,
  }) {
    return AISettings(
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedModel: selectedModel ?? this.selectedModel,
      apiKeys: apiKeys ?? this.apiKeys,
      topK: topK ?? this.topK,
    );
  }
}

class ConnectionTestResult {
  final bool success;
  final String message;

  ConnectionTestResult({required this.success, required this.message});

  factory ConnectionTestResult.fromJson(Map<String, dynamic> json) {
    return ConnectionTestResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class ConnectionTestState {
  final bool isLoading;
  final ConnectionTestResult? result;

  ConnectionTestState({this.isLoading = false, this.result});

  ConnectionTestState copyWith({bool? isLoading, ConnectionTestResult? result}) {
    return ConnectionTestState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
    );
  }
}

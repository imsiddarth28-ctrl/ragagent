import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../../models/ai_config_model.dart';
import '../../models/document_model.dart';
import '../../models/message_model.dart';
import '../../models/conversation_model.dart';
import '../../models/user_model.dart';

class ApiService {
  // Production Render URL
  static const String _prodUrl = 'https://ragagent-9b88.onrender.com';
  static const String _localUrl = 'http://10.0.2.2:8000'; // Standard Android emulator loopback

  // Set to true for live cloud backend
  static const bool _useProd = true; 

  String get _baseUrl => _useProd ? _prodUrl : _localUrl;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers({bool isJson = true}) {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ==================== AUTHENTICATION ====================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headers(),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _authToken = data['access_token'];
        return {
          'token': data['access_token'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        throw Exception(data['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Auth error: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _headers(),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _authToken = data['access_token'];
        return {
          'token': data['access_token'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        throw Exception(data['detail'] ?? 'Invalid credentials');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>> googleAuth({
    required String email,
    required String name,
    String? avatarUrl,
    String? idToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: _headers(),
        body: json.encode({
          'email': email,
          'name': name,
          'avatar_url': avatarUrl,
          'id_token': idToken,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _authToken = data['access_token'];
        return {
          'token': data['access_token'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        throw Exception(data['detail'] ?? 'Google authentication failed');
      }
    } catch (e) {
      throw Exception('Google Sign In error: $e');
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Session expired');
      }
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // ==================== AI PROVIDERS ====================

  Future<List<AIProviderModel>> getProviders() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/providers/'), headers: _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AIProviderModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load providers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Backend unavailable: $e');
    }
  }

  Future<List<AIModel>> getModels(String providerId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/providers/$providerId/models'), headers: _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AIModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load models: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Backend unavailable: $e');
    }
  }

  Future<ConnectionTestResult> testConnection({
    required String providerId,
    required String modelId,
    required String apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/providers/test-connection'),
        headers: _headers(),
        body: json.encode({
          'provider': providerId,
          'model': modelId,
          'api_key': apiKey,
        }),
      );

      if (response.statusCode == 200) {
        return ConnectionTestResult.fromJson(json.decode(response.body));
      } else {
        return ConnectionTestResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        message: 'Connection failed: $e',
      );
    }
  }

  // ==================== DOCUMENTS ====================

  Future<Document> uploadDocument(PlatformFile file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/documents/upload'));
      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      
      final Uint8List fileBytes = await file.readAsBytes();
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: file.name,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Document.fromJson(data);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error during upload: $e');
    }
  }

  Future<List<Document>> getDocuments({String? sourceType}) async {
    try {
      final uri = sourceType != null 
          ? Uri.parse('$_baseUrl/documents/?source_type=$sourceType')
          : Uri.parse('$_baseUrl/documents/');
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Document.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
       throw Exception('Backend unavailable: $e');
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/documents/$id'), headers: _headers());
      if (response.statusCode != 200) {
        throw Exception('Failed to delete document');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ==================== RETRIEVAL & SEARCH ====================

  Future<List<Source>> search(String query, {int topK = 4}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/retrieval/search'),
        headers: _headers(),
        body: json.encode({
          'query': query,
          'top_k': topK,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.map((res) => Source.fromJson({
          ...res,
          'snippet': res['text'] ?? res['snippet'] ?? '',
        })).toList();
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Search unavailable: $e');
    }
  }

  // ==================== CONVERSATIONS & RAG AGENT ====================

  Future<Conversation> createConversation(String title, {List<String>? documentIds}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/'),
        headers: _headers(),
        body: json.encode({
          'title': title,
          'document_ids': documentIds,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Conversation.fromJson(data);
      } else {
        throw Exception('Failed to create conversation');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Conversation>> getConversations() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/conversations/'), headers: _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Conversation.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Conversation> getConversation(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/conversations/$id'), headers: _headers());
      if (response.statusCode == 200) {
        return Conversation.fromJson(json.decode(response.body));
      } else {
        throw Exception('Conversation not found');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Message> addMessage(String conversationId, String role, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages'),
        headers: _headers(),
        body: json.encode({
          'role': role,
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        return Message.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/conversations/$id'), headers: _headers());
      if (response.statusCode != 200) {
        throw Exception('Failed to delete conversation');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Message> askQuestion({
    required String conversationId,
    required String question,
    required String provider,
    required String model,
    required String apiKey,
    int topK = 4,
    bool allowWebSearch = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/ask'),
        headers: _headers(),
        body: json.encode({
          'question': question,
          'provider': provider,
          'model': model,
          'api_key': apiKey,
          'top_k': topK,
          'allow_web_search': allowWebSearch,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Message.fromJson(data);
      } else {
        String errorDetail = 'Server response (${response.statusCode})';
        try {
          final data = json.decode(response.body);
          if (data is Map && data.containsKey('detail')) {
            errorDetail = data['detail'].toString();
          }
        } catch (_) {
          if (response.statusCode == 502 || response.statusCode == 503) {
            errorDetail = 'Backend is currently restarting/deploying. Please try again in 10 seconds.';
          }
        }
        throw Exception(errorDetail);
      }
    } catch (e) {
      throw Exception('RAG Agent error: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../models/ai_config_model.dart';
import '../../models/document_model.dart';
import '../../models/message_model.dart';
import '../../models/conversation_model.dart';

class ApiService {
  // Production Render URL
  static const String _prodUrl = 'https://ragagent-9b88.onrender.com';
  static const String _localUrl = 'http://127.0.0.1:8000';

  // Set to true for production deployment
  static const bool _useProd = true; 

  String get _baseUrl => _useProd ? _prodUrl : _localUrl;

  Future<List<AIProviderModel>> getProviders() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/providers/'));
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
      final response = await http.get(Uri.parse('$_baseUrl/providers/$providerId/models'));
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
        headers: {'Content-Type': 'application/json'},
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

  Future<Document> uploadDocument(PlatformFile file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/documents/upload'));
      
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

  Future<List<Document>> getDocuments() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/documents/'));
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
      final response = await http.delete(Uri.parse('$_baseUrl/documents/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete document');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }



  Future<List<Source>> search(String query, {int topK = 4}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/retrieval/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'top_k': topK,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
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

  // Conversation Methods
  Future<Conversation> createConversation(String title, {List<String>? documentIds}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.get(Uri.parse('$_baseUrl/conversations/'));
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
      final response = await http.get(Uri.parse('$_baseUrl/conversations/$id'));
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
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.delete(Uri.parse('$_baseUrl/conversations/$id'));
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
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/ask'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'question': question,
          'provider': provider,
          'model': model,
          'api_key': apiKey,
          'top_k': topK,
        }),
      );

      if (response.statusCode == 200) {
        return Message.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body)['detail'] ?? 'Failed to generate answer';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('RAG error: $e');
    }
  }


}

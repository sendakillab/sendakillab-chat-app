import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../models/llm_model.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ChatReply {
  ChatReply({
    required this.model,
    required this.content,
    required this.conversationId,
  });

  final String model;
  final String content;
  final String conversationId;
}

class ConversationSummary {
  ConversationSummary({
    required this.id,
    required this.title,
    required this.modelName,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? modelName;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Conversation').toString(),
      modelName: json['model_name']?.toString(),
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
              DateTime.now(),
    );
  }
}

class ConversationDetail {
  ConversationDetail({
    required this.id,
    required this.title,
    required this.modelName,
    required this.messages,
  });

  final String id;
  final String title;
  final String? modelName;
  final List<ChatMessage> messages;

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];

    final messages = rawMessages
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final roleName = (item['role'] ?? '').toString().toLowerCase();

          return ChatMessage(
            role: roleName == 'assistant'
                ? ChatRole.assistant
                : ChatRole.user,
            content: (item['content'] ?? '').toString(),
            createdAt:
                DateTime.tryParse((item['created_at'] ?? '').toString()) ??
                    DateTime.now(),
          );
        })
        .toList();

    return ConversationDetail(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Conversation').toString(),
      modelName: json['model_name']?.toString(),
      messages: messages,
    );
  }
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, dynamic>> health() async {
    final response = await _client
        .get(_uri('/health'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw ApiException(
        'Health check failed (${response.statusCode})',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<LlmModel>> getModels() async {
    final response = await _client
        .get(_uri('/api/v1/models'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException(
        'Could not load models (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    final rawModels = decoded is Map<String, dynamic>
        ? (decoded['models'] as List<dynamic>? ?? const [])
        : const <dynamic>[];

    return rawModels
        .whereType<Map<String, dynamic>>()
        .map(LlmModel.fromJson)
        .where((model) => model.name.isNotEmpty)
        .toList();
  }

  Future<ChatReply> chat({
    required String message,
    required String model,
    String? conversationId,
    double temperature = 0.7,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'model': model,
      'temperature': temperature,
    };

    if (conversationId != null && conversationId.isNotEmpty) {
      body['conversation_id'] = conversationId;
    }

    final response = await _client
        .post(
          _uri('/api/v1/chat'),
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 130));

    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(
          'Chat failed',
          response,
        ),
      );
    }

    final decoded =
        jsonDecode(response.body) as Map<String, dynamic>;

    final messageMap = decoded['message'];
    final content = messageMap is Map<String, dynamic>
        ? (messageMap['content'] ?? '').toString()
        : '';

    return ChatReply(
      model: (decoded['model'] ?? model).toString(),
      content: content.isEmpty
          ? 'The model returned an empty response.'
          : content,
      conversationId:
          (decoded['conversation_id'] ?? '').toString(),
    );
  }

  Future<List<ConversationSummary>> getConversations() async {
    final response = await _client
        .get(_uri('/api/v1/conversations'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(
          'Could not load chat history',
          response,
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ConversationSummary.fromJson)
        .toList();
  }

  Future<ConversationDetail> getConversation(String id) async {
    final response = await _client
        .get(_uri('/api/v1/conversations/$id'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(
          'Could not open conversation',
          response,
        ),
      );
    }

    return ConversationDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteConversation(String id) async {
    final response = await _client
        .delete(_uri('/api/v1/conversations/$id'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(
          'Could not delete conversation',
          response,
        ),
      );
    }
  }

  String _errorMessage(
    String prefix,
    http.Response response,
  ) {
    String detail = response.body;

    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map && parsed['detail'] != null) {
        detail = parsed['detail'].toString();
      }
    } catch (_) {}

    return '$prefix (${response.statusCode}): $detail';
  }

  void dispose() => _client.close();
}

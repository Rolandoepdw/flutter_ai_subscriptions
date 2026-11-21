import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_ai_subscriptions/flutter_ai_subscriptions.dart';
import 'package:example/models/chat_message.dart';

class ChatService {
  final AIConfigManager _configManager;

  ChatService(this._configManager);

  Future<String> sendMessage(List<ChatMessage> history) async {
    return await _executeWithRetry(() => _sendInternal(history));
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      developer.log('Chat request failed: $e', name: 'ChatService');
      
      final errorStr = e.toString();
      if (errorStr.contains('429') || errorStr.contains('401') || errorStr.contains('quota_exceeded')) {
        developer.log('Detected quota/auth error. Rotating key and retrying...', name: 'ChatService');
        await _configManager.reportKeyExhausted();
        return await action();
      }
      rethrow;
    }
  }

  Future<String> _sendInternal(List<ChatMessage> history) async {
    final credentials = _configManager.getActiveCredentials();
    if (credentials == null) throw Exception('No active credentials available.');

    final allProviders = await _configManager.getAllProviders();
    
    // Use the Request Factory from the package
    final requestDetail = AIRequestFactory.generateChatRequest(
      credentials: credentials,
      allProviders: allProviders,
      messages: history.where((m) => !m.isSystemLog).map((m) {
        return {
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.content,
        };
      }).toList(),
    );

    developer.log('Sending request to: ${requestDetail.url}', name: 'ChatService');

    final response = await http.post(
      Uri.parse(requestDetail.url),
      headers: requestDetail.headers,
      body: jsonEncode(requestDetail.body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _extractContent(data, credentials.providerId);
    } else {
      throw Exception('${credentials.providerId} API Error (${response.statusCode}): ${response.body}');
    }
  }

  String _extractContent(Map<String, dynamic> data, String providerId) {
    try {
      if (providerId == 'google') {
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']['content'] ?? '';
        }
        throw Exception('Empty choices in response');
      }
    } catch (e) {
      throw Exception('Error parsing $providerId response: $e. Body: $data');
    }
  }
}

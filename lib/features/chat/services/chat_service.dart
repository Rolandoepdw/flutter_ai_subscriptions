import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_active_credentials.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/ai_config_manager.dart';
import 'package:flutter_ai_subscriptions/features/chat/models/chat_message.dart';

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
      
      if (e.toString().contains('429') || e.toString().contains('401')) {
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

    if (credentials.providerId == 'google') {
      return await _sendToGoogle(credentials, history);
    } else {
      return await _sendToOpenAICompatible(credentials, history);
    }
  }

  Future<String> _sendToGoogle(AIActiveCredentials creds, List<ChatMessage> history) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/${creds.modelId}:generateContent?key=${creds.apiKey}';
    
    final contents = history.where((m) => !m.isSystemLog).map((m) {
      return {
        'role': m.role == MessageRole.user ? 'user' : 'model',
        'parts': [{'text': m.content}]
      };
    }).toList();

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contents': contents}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        return data['candidates'][0]['content']['parts'][0]['text'];
      } catch (e) {
        throw Exception('Unexpected Google API response format: ${response.body}');
      }
    } else {
      throw Exception('Google API Error (${response.statusCode}): ${response.body}');
    }
  }

  Future<String> _sendToOpenAICompatible(AIActiveCredentials creds, List<ChatMessage> history) async {
    final allProviders = await _configManager.getAllProviders();
    final definition = allProviders.firstWhere((p) => p.id == creds.providerId);
    
    // LM Studio often uses base URL as http://localhost:1234/v1
    // If the URL already ends with /v1, we don't duplicate it.
    String baseUrl = definition.baseUrl;
    if (!baseUrl.endsWith('/v1') && !baseUrl.contains('/v1/')) {
      // If it doesn't have /v1, we usually need to add it for the OpenAI spec.
      // But we must check if /chat/completions is already there.
      if (!baseUrl.endsWith('/')) baseUrl += '/';
      baseUrl += 'v1';
    }

    final url = baseUrl.endsWith('/') ? '${baseUrl}chat/completions' : '$baseUrl/chat/completions';
    developer.log('Sending request to: $url', name: 'ChatService');

    final messages = history.where((m) => !m.isSystemLog).map((m) {
      return {
        'role': m.role.name,
        'content': m.content,
      };
    }).toList();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${creds.apiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/Rolandoepdw/flutter_ai_subscriptions',
        'X-OpenRouter-Title': 'Flutter AI Subscriptions',
      },
      body: jsonEncode({
        'model': creds.modelId,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        // Safe access to avoid NoSuchMethodError
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']['content'] ?? '';
        }
        throw Exception('Empty choices in response');
      } catch (e) {
        throw Exception('Error parsing OpenAI response: $e. Body: ${response.body}');
      }
    } else {
      throw Exception('${creds.providerId} API Error (${response.statusCode}): ${response.body}');
    }
  }
}

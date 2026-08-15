import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../ai_config/models/ai_active_credentials.dart';
import '../../ai_config/services/ai_config_manager.dart';
import '../models/chat_message.dart';

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
      
      // If it's a quota or auth error, rotate and retry once
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
      // Standard OpenAI format for OpenRouter, Anthropic, DeepSeek, etc.
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
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Google API Error (${response.statusCode}): ${response.body}');
    }
  }

  Future<String> _sendToOpenAICompatible(AIActiveCredentials creds, List<ChatMessage> history) async {
    // Determine Base URL based on provider (this could be improved by adding endpoints to ProviderDefinition)
    String url = 'https://openrouter.ai/api/v1/chat/completions';
    if (creds.providerId == 'anthropic') url = 'https://api.anthropic.com/v1/messages';
    if (creds.providerId == 'deepseek') url = 'https://api.deepseek.com/v1/chat/completions';
    if (creds.providerId == 'xai') url = 'https://api.x.ai/v1/chat/completions';

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
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('${creds.providerId} API Error (${response.statusCode}): ${response.body}');
    }
  }
}

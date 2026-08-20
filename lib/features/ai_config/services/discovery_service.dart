import 'dart:developer' as developer;
import 'package:flutter_ai_subscriptions/features/ai_config/data/provider_definitions.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_model.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/handlers/anthropic_handler.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/handlers/base_provider_handler.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/handlers/deepseek_handler.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/handlers/google_handler.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/handlers/openai_handler.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/handlers/openrouter_handler.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/handlers/xai_handler.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/services/handlers/custom_handler.dart';

class DiscoveryService {
  final Map<String, BaseProviderHandler> _handlers = {
    'openai': OpenAIHandler(),
    'google': GoogleHandler(),
    'openrouter': OpenRouterHandler(),
    'anthropic': AnthropicHandler(),
    'deepseek': DeepSeekHandler(),
    'xai': XAIHandler(),
  };

  final CustomHandler _customHandler = CustomHandler();

  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey) async {
    developer.log('--- START FETCH MODELS: ${provider.name} ---', name: 'DiscoveryService');
    
    // Check if it's a built-in handler or use custom handler
    final handler = _handlers[provider.id] ?? _customHandler;

    try {
      return await handler.fetchModels(provider, apiKey);
    } catch (e, stack) {
      developer.log('Unexpected error in fetchModels for ${provider.id}: $e', name: 'DiscoveryService', error: e, stackTrace: stack);
      rethrow;
    } finally {
      developer.log('--- END FETCH MODELS: ${provider.name} ---', name: 'DiscoveryService');
    }
  }
}

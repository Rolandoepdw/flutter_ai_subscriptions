import '../models/ai_active_credentials.dart';
import '../data/provider_definitions.dart';

enum AIRequestType {
  chat,
  embeddings,
  imageGeneration,
  textToSpeech,
  speechToText,
}

class AIRequestDetails {
  final String url;
  final Map<String, String> headers;
  final Map<String, dynamic> body;

  const AIRequestDetails({
    required this.url,
    required this.headers,
    required this.body,
  });
}

/// Factory to generate request details for different AI providers and types.
class AIRequestFactory {
  /// Generates details for a Chat completion request.
  static AIRequestDetails generateChatRequest({
    required AIActiveCredentials credentials,
    required List<Map<String, dynamic>> messages,
    required List<ProviderDefinition> allProviders,
    Map<String, dynamic>? additionalParams,
  }) {
    final definition = allProviders.firstWhere((p) => p.id == credentials.providerId);
    
    if (credentials.providerId == 'google') {
      return _generateGoogleChatRequest(credentials, messages, additionalParams);
    } else {
      return _generateOpenAICompatibleChatRequest(credentials, definition, messages, additionalParams);
    }
  }

  static AIRequestDetails _generateGoogleChatRequest(
    AIActiveCredentials creds,
    List<Map<String, dynamic>> messages,
    Map<String, dynamic>? additionalParams,
  ) {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/${creds.modelId}:generateContent?key=${creds.apiKey}';
    
    // Convert generic messages to Google format if necessary
    final contents = messages.map((m) {
      return {
        'role': m['role'] == 'user' ? 'user' : 'model',
        'parts': [{'text': m['content']}]
      };
    }).toList();

    return AIRequestDetails(
      url: url,
      headers: {'Content-Type': 'application/json'},
      body: {
        'contents': contents,
        ...?additionalParams,
      },
    );
  }

  static AIRequestDetails _generateOpenAICompatibleChatRequest(
    AIActiveCredentials creds,
    ProviderDefinition definition,
    List<Map<String, dynamic>> messages,
    Map<String, dynamic>? additionalParams,
  ) {
    String baseUrl = definition.baseUrl;
    if (!baseUrl.endsWith('/v1') && !baseUrl.contains('/v1/')) {
      if (!baseUrl.endsWith('/')) baseUrl += '/';
      baseUrl += 'v1';
    }

    final url = baseUrl.endsWith('/') ? '${baseUrl}chat/completions' : '$baseUrl/chat/completions';

    final headers = {
      'Authorization': 'Bearer ${creds.apiKey}',
      'Content-Type': 'application/json',
      // Useful for OpenRouter
      'HTTP-Referer': 'https://github.com/Rolandoepdw/flutter_ai_subscriptions',
      'X-OpenRouter-Title': 'Flutter AI Subscriptions',
    };

    return AIRequestDetails(
      url: url,
      headers: headers,
      body: {
        'model': creds.modelId,
        'messages': messages,
        ...?additionalParams,
      },
    );
  }

  // Future extensions placeholder
  /*
  static AIRequestDetails generateEmbeddingsRequest(...) { ... }
  static AIRequestDetails generateImageRequest(...) { ... }
  */
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_ai_subscriptions/features/ai_config/data/provider_definitions.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_model.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_tier.dart';
import 'base_provider_handler.dart';

class AnthropicHandler extends BaseProviderHandler {
  @override
  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) return [];
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        ...getCommonHeaders(),
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? models = data['data'];
      if (models == null) return [];
      return models.map((m) {
        final id = m['id'] as String;
        return AIModel(
          id: id,
          name: m['display_name'] ?? id,
          tier: AITier.paid,
          hasVision: id.contains('claude-3'), 
          hasTools: true, 
        );
      }).toList();
    }
    throw Exception('Anthropic error (${response.statusCode})');
  }
}

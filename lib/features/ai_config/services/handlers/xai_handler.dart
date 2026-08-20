import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_ai_subscriptions/features/ai_config/data/provider_definitions.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_model.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_tier.dart';
import 'base_provider_handler.dart';

class XAIHandler extends BaseProviderHandler {
  @override
  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) return [];
    
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...getCommonHeaders(),
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? rawModels = data['data'] ?? data['models'];
      
      if (rawModels == null) return [];

      return rawModels.map((m) {
        final id = m['id'] as String;
        final name = m['name'] ?? id;
        final description = (m['description'] ?? '').toString().toLowerCase();
        
        return AIModel(
          id: id,
          name: name,
          tier: AITier.paid,
          contextTokens: id.contains('128k') ? 131072 : 32768,
          inputPrice: 5.0,
          outputPrice: 15.0,
          hasVision: id.contains('vision') || description.contains('vision'),
          hasTools: true,
          hasReasoning: id.contains('reason') || description.contains('reason'),
        );
      }).toList();
    } else {
      throw Exception('xAI error (${response.statusCode}): ${response.body}');
    }
  }
}

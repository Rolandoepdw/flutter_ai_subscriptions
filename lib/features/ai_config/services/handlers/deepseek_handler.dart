import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_ai_subscriptions/features/ai_config/data/provider_definitions.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_model.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_tier.dart';
import 'base_provider_handler.dart';

class DeepSeekHandler extends BaseProviderHandler {
  @override
  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey) async {
    if (apiKey == null) return [];
    final url = '${provider.baseUrl}${provider.discoveryEndpoint}';
    final response = await http.get(
      Uri.parse(url),
      headers: {...getCommonHeaders(), 'Authorization': 'Bearer $apiKey'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List? rawModels = data['data'];
      
      if (rawModels == null) return [];

      return rawModels.map((m) {
        final id = m['id'] as String;
        return AIModel(
          id: id,
          name: id.contains('pro') ? 'DeepSeek V4 Pro' : 'DeepSeek V4 Flash',
          tier: AITier.paid,
          contextTokens: 1000000, 
          inputPrice: id.contains('pro') ? 1.32 : 0.44, 
          outputPrice: id.contains('pro') ? 1.32 : 0.44, 
          hasVision: false, 
          hasTools: true,
          hasReasoning: true, 
        );
      }).toList();
    }
    throw Exception('DeepSeek error (${response.statusCode})');
  }
}

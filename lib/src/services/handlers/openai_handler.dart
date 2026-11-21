import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/provider_definitions.dart';
import '../../models/ai_model.dart';
import '../../models/ai_tier.dart';
import 'base_provider_handler.dart';

class OpenAIHandler extends BaseProviderHandler {
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
          name: id.toUpperCase(),
          tier: AITier.paid,
          hasVision: id.contains('gpt-4o') || id.contains('vision'),
          hasTools: true,
          hasReasoning: id.startsWith('o1') || id.startsWith('o3'),
        );
      }).toList();
    } else {
      throw Exception('OpenAI error (${response.statusCode}): ${response.body}');
    }
  }
}

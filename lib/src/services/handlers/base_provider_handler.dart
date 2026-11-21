import '../../data/provider_definitions.dart';
import '../../models/ai_model.dart';

abstract class BaseProviderHandler {
  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey);

  Map<String, String> getCommonHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json',
    };
  }

  double parsePrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

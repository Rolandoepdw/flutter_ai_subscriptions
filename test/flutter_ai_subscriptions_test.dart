import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ai_subscriptions/flutter_ai_subscriptions.dart';
import 'package:flutter_ai_subscriptions/src/data/provider_definitions.dart';

// --- Mocks & Fakes ---

class MockStorage extends SecureStorageService {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> saveSelectedProvider(String id) async => _data['active_provider_id'] = id;
  @override
  Future<String?> loadSelectedProvider() async => _data['active_provider_id'];

  @override
  Future<void> saveKeyPool(APIKeyPool pool) async => _data['pool_${pool.providerId}'] = pool;
  @override
  Future<APIKeyPool?> loadKeyPool(String providerId) async => _data['pool_$providerId'];

  @override
  Future<void> saveCustomProviders(List<CustomProvider> providers) async => _data['custom_providers'] = providers;
  @override
  Future<List<CustomProvider>> loadCustomProviders() async => _data['custom_providers'] ?? [];

  @override
  Future<void> saveModels(String providerId, List<AIModel> models) async => _data['models_$providerId'] = models;
  @override
  Future<List<AIModel>> loadModels(String providerId) async => _data['models_$providerId'] ?? [];

  @override
  Future<void> saveSelectedModel(String providerId, String modelId) async => _data['sel_model_$providerId'] = modelId;
  @override
  Future<String?> loadSelectedModel(String providerId) async => _data['sel_model_$providerId'];
}

class MockDiscovery extends DiscoveryService {
  bool shouldFail = false;
  int callCount = 0;

  @override
  Future<List<AIModel>> fetchModels(ProviderDefinition provider, String? apiKey) async {
    callCount++;
    if (shouldFail) throw Exception('Validation Failed');
    return [
      AIModel(id: 'model-1', name: 'Model 1', tier: AITier.free),
      AIModel(id: 'model-2', name: 'Model 2', tier: AITier.paid),
    ];
  }
}

// --- Tests ---

void main() {
  group('AIConfigManager', () {
    late AIConfigManager manager;
    late MockStorage storage;
    late MockDiscovery discovery;

    setUp(() {
      storage = MockStorage();
      discovery = MockDiscovery();
      manager = AIConfigManager(
        storage: storage,
        discovery: discovery,
        exhaustionTimeout: const Duration(seconds: 1),
      );
    });

    test('Initializes with default providers', () async {
      await manager.init();
      final providers = manager.getAllProviders();
      expect(providers.any((p) => p.id == 'openai'), true);
      expect(providers.any((p) => p.id == 'google'), true);
    });

    test('Add key with proactive validation', () async {
      await manager.addKey('openai', 'valid-key');
      // It calls fetchModels during validation and then twice for refreshing/selecting.
      expect(discovery.callCount, greaterThanOrEqualTo(1));
      expect(manager.getPool('openai')?.keys.length, 1);
    });

    test('Add key fails if validation fails', () async {
      discovery.shouldFail = true;
      expect(() => manager.addKey('openai', 'invalid-key'), throwsException);
      expect(manager.getPool('openai'), isNull);
    });

    test('Key rotation logic', () async {
      // Add two keys
      await manager.addKey('openai', 'key-1');
      await manager.addKey('openai', 'key-2');
      await manager.selectModel('openai', 'model-1');

      expect(manager.getActiveCredentials()?.apiKey, 'key-1');

      // Key 1 exhausted
      await manager.reportKeyExhausted();
      expect(manager.getActiveCredentials()?.apiKey, 'key-2');

      // Key 2 exhausted -> No keys available
      await manager.reportKeyExhausted();
      expect(manager.getActiveCredentials(), isNull);
    });

    test('Cool-down recovery', () async {
      await manager.addKey('openai', 'key-1');
      await manager.selectModel('openai', 'model-1');

      await manager.reportKeyExhausted();
      expect(manager.getActiveCredentials(), isNull);

      // Wait for exhaustionTimeout
      await Future.delayed(const Duration(milliseconds: 1100));

      expect(manager.getActiveCredentials()?.apiKey, 'key-1');
      expect(manager.getPool('openai')?.keys.first.isExhausted, false);
    });

    test('Custom Provider CRUD', () async {
      final custom = CustomProvider(id: 'local', name: 'Local AI', baseUrl: 'http://localhost');
      await manager.addCustomProvider(custom);

      expect(manager.customProviders.length, 1);
      expect(manager.getAllProviders().any((p) => p.id == 'local'), true);

      await manager.removeCustomProvider('local');
      expect(manager.customProviders.length, 0);
    });
  });

  group('AIRequestFactory', () {
    final creds = AIActiveCredentials(providerId: 'openai', modelId: 'gpt-4', apiKey: 'sk-123');
    final providers = ProviderDefinitions.definitions;

    test('Generates OpenAI compatible request', () {
      final details = AIRequestFactory.generateChatRequest(
        credentials: creds,
        allProviders: providers,
        messages: [{'role': 'user', 'content': 'hi'}],
      );

      expect(details.url, 'https://api.openai.com/v1/chat/completions');
      expect(details.headers['Authorization'], 'Bearer sk-123');
      expect(details.body['model'], 'gpt-4');
    });

    test('Generates Google AI request', () {
      final googleCreds = AIActiveCredentials(providerId: 'google', modelId: 'gemini-pro', apiKey: 'g-123');
      final details = AIRequestFactory.generateChatRequest(
        credentials: googleCreds,
        allProviders: providers,
        messages: [{'role': 'user', 'content': 'hi'}],
      );

      expect(details.url, contains('gemini-pro:generateContent'));
      expect(details.url, contains('key=g-123'));
      expect(details.body['contents'], isList);
    });
  });

  group('AIConfigNotifier', () {
    late AIConfigManager manager;
    late MockStorage storage;
    late MockDiscovery discovery;
    late AIConfigNotifier notifier;

    setUp(() async {
      storage = MockStorage();
      discovery = MockDiscovery();
      manager = AIConfigManager(storage: storage, discovery: discovery);
      await manager.init();
      notifier = AIConfigNotifier(manager);
    });

    test('Filters models by search query', () async {
      await manager.addKey('openai', 'key-1'); // Discovery returns model-1 and model-2
      
      notifier.updateSearchQuery('model-1');
      final filtered = notifier.getFilteredModels('openai');
      
      expect(filtered.length, 1);
      expect(filtered.first.id, 'model-1');
    });

    test('Filters models by free tier', () async {
      await manager.addKey('openai', 'key-1');
      
      notifier.toggleOnlyFree(true);
      final filtered = notifier.getFilteredModels('openai');
      
      expect(filtered.every((m) => m.tier == AITier.free), true);
    });
  });
}

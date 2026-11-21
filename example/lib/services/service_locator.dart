import 'package:get_it/get_it.dart';
import 'package:flutter_ai_subscriptions/flutter_ai_subscriptions.dart';
import 'package:example/state/chat_notifier.dart';
import 'package:example/services/chat_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  sl.registerLazySingleton(() => SecureStorageService());
  sl.registerLazySingleton(() => DiscoveryService());
  sl.registerLazySingleton(() => ChatService(sl()));
  
  // Managers from package
  sl.registerLazySingleton(() => AIConfigManager(
    storage: sl(),
    discovery: sl(),
    exhaustionTimeout: const Duration(hours: 8),
  ));
  
  // Notifiers
  sl.registerFactory(() => AIConfigNotifier(sl()));
  sl.registerFactory(() => ChatNotifier(sl()));
  
  // Initialization
  await sl<AIConfigManager>().init();
}

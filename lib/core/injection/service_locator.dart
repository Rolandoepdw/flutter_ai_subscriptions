import 'package:get_it/get_it.dart';
import '../../features/ai_config/cubit/ai_config_cubit.dart';
import '../../features/ai_config/services/ai_config_manager.dart';
import '../../features/ai_config/services/discovery_service.dart';
import '../../features/ai_config/services/secure_storage_service.dart';
import '../../features/chat/cubit/chat_cubit.dart';
import '../../features/chat/services/chat_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  sl.registerLazySingleton(() => SecureStorageService());
  sl.registerLazySingleton(() => DiscoveryService());
  sl.registerLazySingleton(() => ChatService(sl()));
  
  // Managers
  sl.registerLazySingleton(() => AIConfigManager(sl(), sl()));
  
  // Cubits
  sl.registerFactory(() => AIConfigCubit(sl()));
  sl.registerFactory(() => ChatCubit(sl()));
  
  // Initialization
  await sl<AIConfigManager>().init();
}

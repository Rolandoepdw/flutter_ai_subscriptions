import 'package:get_it/get_it.dart';
import '../../features/ai_config/cubit/ai_config_cubit.dart';
import '../../features/ai_config/services/ai_config_manager.dart';
import '../../features/ai_config/services/secure_storage_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  sl.registerLazySingleton(() => SecureStorageService());
  
  // Managers
  sl.registerLazySingleton(() => AIConfigManager(sl()));
  
  // Cubits
  sl.registerFactory(() => AIConfigCubit(sl()));
  
  // Initialization
  await sl<AIConfigManager>().init();
}

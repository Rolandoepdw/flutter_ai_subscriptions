import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/injection/service_locator.dart';
import 'features/ai_config/cubit/ai_config_cubit.dart';
import 'features/ai_config/ui/provider_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AIConfigCubit>()..loadConfig(),
      child: MaterialApp(
        title: 'AI Subscriptions',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ProviderListScreen(),
      ),
    );
  }
}

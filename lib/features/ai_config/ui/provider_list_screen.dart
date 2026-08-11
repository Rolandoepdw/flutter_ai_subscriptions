import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/ai_config_cubit.dart';
import '../cubit/ai_config_state.dart';
import 'provider_detail_screen.dart';

class ProviderListScreen extends StatelessWidget {
  const ProviderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de IA'),
      ),
      body: BlocBuilder<AIConfigCubit, AIConfigState>(
        builder: (context, state) {
          if (state.status == AIConfigStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AIConfigStatus.error) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }

          return ListView.builder(
            itemCount: state.providers.length,
            itemBuilder: (context, index) {
              final provider = state.providers[index];
              final isSelected = state.selectedProviderId == provider.id;
              final pool = state.keyPools[provider.id];
              final keyCount = pool?.keys.length ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: provider.iconPath.endsWith('.png') 
                      ? const Icon(Icons.psychology) // Fallback for icons not in assets yet
                      : Text(provider.name[0]),
                ),
                title: Text(provider.name),
                subtitle: Text('$keyCount claves configuradas'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (provider.hasFreeModels)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Free',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.blue),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderDetailScreen(providerId: provider.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

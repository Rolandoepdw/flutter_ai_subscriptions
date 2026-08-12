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
        backgroundColor: Theme.of(context).primaryColor,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
        title: const Text('AI Configuration'),
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
              final models = state.providerModels[provider.id] ?? [];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.psychology),
                ),
                title: Text(provider.name),
                subtitle: Text('$keyCount keys • ${models.length} models'),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
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

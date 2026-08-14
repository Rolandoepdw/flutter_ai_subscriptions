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
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('AI Providers'),
      ),
      body: BlocBuilder<AIConfigCubit, AIConfigState>(
        builder: (context, state) {
          if (state.status == AIConfigStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AIConfigStatus.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error: ${state.errorMessage}', textAlign: TextAlign.center),
            ));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.providers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final provider = state.providers[index];
              final isSelected = state.selectedProviderId == provider.id;
              final pool = state.keyPools[provider.id];
              final keyCount = pool?.keys.length ?? 0;
              final models = state.providerModels[provider.id] ?? [];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Colors.blue.shade100 : Colors.grey[200],
                  child: Icon(Icons.psychology, color: isSelected ? Colors.blue : Colors.grey),
                ),
                title: Text(provider.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text('$keyCount keys • ${models.length} models'),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : const Icon(Icons.chevron_right),
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

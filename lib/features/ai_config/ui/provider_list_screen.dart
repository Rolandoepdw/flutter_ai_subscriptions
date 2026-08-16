import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_cubit.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_state.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/ui/provider_detail_screen.dart';

class ProviderListScreen extends StatelessWidget {
  const ProviderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('AI Providers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: BlocBuilder<AIConfigCubit, AIConfigState>(
        builder: (context, state) {
          if (state.status == AIConfigStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AIConfigStatus.error) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error: ${state.errorMessage}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            ));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.providers.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (context, index) {
              final provider = state.providers[index];
              final isSelected = state.selectedProviderId == provider.id;
              final pool = state.keyPools[provider.id];
              final keyCount = pool?.keys.length ?? 0;
              final models = state.providerModels[provider.id] ?? [];

              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[100],
                  child: Icon(Icons.psychology_outlined, color: isSelected ? Colors.blue : Colors.grey[600], size: 20),
                ),
                title: Text(
                  provider.name, 
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.blue[800] : Colors.black87,
                  )
                ),
                subtitle: Text(
                  '$keyCount keys • ${models.length} models',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
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

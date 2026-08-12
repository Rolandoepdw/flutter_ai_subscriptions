import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/ai_config_cubit.dart';
import '../cubit/ai_config_state.dart';
import '../models/ai_tier.dart';

class ProviderDetailScreen extends StatelessWidget {
  final String providerId;

  const ProviderDetailScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AIConfigCubit, AIConfigState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
          );
          context.read<AIConfigCubit>().clearMessages();
        }
        if (state.errorMessage != null && state.status != AIConfigStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
          );
          context.read<AIConfigCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final provider = state.providers.firstWhere((p) => p.id == providerId);
        final selectedModelId = state.selectedModelIds[providerId];
        final pool = state.keyPools[providerId];
        final models = state.providerModels[providerId] ?? [];
        final isSelectedProvider = state.selectedProviderId == providerId;
        final isDiscovering = state.status == AIConfigStatus.discoveryInProgress;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
            actionsPadding: const EdgeInsets.all(8),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(provider.name),
            actions: [
              if (isDiscovering)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<AIConfigCubit>().refreshModels(providerId),
                ),
              if (!isSelectedProvider)
                const SizedBox(width: 8),
              if (!isSelectedProvider)
                IconButton(
                  icon: const Icon(Icons.check_circle),
                  onPressed: () => context.read<AIConfigCubit>().selectProvider(providerId),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Model',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (models.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        const Text('Add a key to discover available models.'),
                        if (isDiscovering)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 8),
                ...models.map((model) {
                  final tokens = model.contextTokens != null 
                    ? (model.contextTokens! >= 1000 
                        ? '${(model.contextTokens! / 1000).toStringAsFixed(0)}K' 
                        : '${model.contextTokens}')
                    : '---';

                  return RadioListTile<String>(
                    title: Text(model.name, overflow: TextOverflow.ellipsis),
                    subtitle: Row(
                      children: [
                        Text(model.tier == AITier.free ? 'Free' : 'Paid'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tokens,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        model.tier == AITier.free 
                            ? const Icon(Icons.money_off, color: Colors.green, size: 16)
                            : const Icon(Icons.attach_money, color: Colors.orange, size: 16),
                      ],
                    ),
                    value: model.id,
                    groupValue: selectedModelId,
                    onChanged: (val) {
                      if (val != null) {
                        context.read<AIConfigCubit>().selectModel(providerId, val);
                      }
                    },
                  );
                }),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'API Key Pool',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: isDiscovering ? null : () => _showAddKeyDialog(context, providerId),
                    ),
                  ],
                ),
                if (pool == null || pool.keys.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('No keys configured for this provider.'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pool.keys.length,
                    itemBuilder: (context, index) {
                      final key = pool.keys[index];
                      final isActive = pool.activeIndex == index;

                      return ListTile(
                        leading: Icon(
                          key.isExhausted ? Icons.error_outline : Icons.vpn_key,
                          color: key.isExhausted ? Colors.red : (isActive ? Colors.blue : Colors.grey),
                        ),
                        title: Text('••••${key.value.substring(key.value.length > 4 ? key.value.length - 4 : 0)}'),
                        subtitle: Text(key.isExhausted ? 'Exhausted' : (isActive ? 'Active' : 'Standby')),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddKeyDialog(BuildContext context, String providerId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Paste your key here'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<AIConfigCubit>().addKey(providerId, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

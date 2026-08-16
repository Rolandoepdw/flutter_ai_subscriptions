import 'package:flutter/material.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/ui/widgets/model_selection_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_cubit.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_state.dart';

class ProviderDetailScreen extends StatefulWidget {
  final String providerId;

  const ProviderDetailScreen({super.key, required this.providerId});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        final provider = state.providers.firstWhere((p) => p.id == widget.providerId);
        final selectedModelId = state.selectedModelIds[widget.providerId];
        final pool = state.keyPools[widget.providerId];
        final filteredModels = state.getFilteredModels(widget.providerId);
        final isSelectedProvider = state.selectedProviderId == widget.providerId;
        final isDiscovering = state.status == AIConfigStatus.discoveryInProgress;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                  onPressed: () => context.read<AIConfigCubit>().refreshModels(widget.providerId),
                ),
              if (!isSelectedProvider)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () => context.read<AIConfigCubit>().selectProvider(widget.providerId),
                    child: const Text('Activate'),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search models...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => context.read<AIConfigCubit>().updateSearchQuery(val),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('Free Only', style: TextStyle(fontSize: 12)),
                          selected: state.onlyFree,
                          onSelected: (val) => context.read<AIConfigCubit>().toggleOnlyFree(val),
                        ),
                        const Spacer(),
                        Text(
                          '${filteredModels.length} models found',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredModels.length + 3,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Select Model',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      );
                    }
                    
                    if (index <= filteredModels.length) {
                      final model = filteredModels[index - 1];
                      return ModelSelectionTile(
                        model: model,
                        isSelected: model.id == selectedModelId,
                        onTap: () => context.read<AIConfigCubit>().selectModel(widget.providerId, model.id),
                      );
                    }

                    if (index == filteredModels.length + 1) {
                      return const Divider(height: 48);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'API Key Pool',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                              onPressed: isDiscovering ? null : () => _showAddKeyDialog(context, widget.providerId),
                            ),
                          ],
                        ),
                        if (pool == null || pool.keys.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('No keys configured for this provider.', style: TextStyle(color: Colors.grey)),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pool.keys.length,
                            itemBuilder: (context, poolIndex) {
                              final key = pool.keys[poolIndex];
                              final isActive = pool.activeIndex == poolIndex;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  key.isExhausted ? Icons.error_outline : Icons.vpn_key,
                                  color: key.isExhausted ? Colors.red : (isActive ? Colors.blue : Colors.grey),
                                ),
                                title: Text('••••${key.value.substring(key.value.length > 4 ? key.value.length - 4 : 0)}'),
                                subtitle: Text(key.isExhausted ? 'Exhausted' : (isActive ? 'Active' : 'Standby')),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => context.read<AIConfigCubit>().removeKey(widget.providerId, key.value),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
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
          ElevatedButton(
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

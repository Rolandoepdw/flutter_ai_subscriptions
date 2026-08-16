import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_cubit.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_state.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/ui/widgets/model_selection_tile.dart';

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
            SnackBar(
              content: Text(state.successMessage!), 
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          context.read<AIConfigCubit>().clearMessages();
        }
        if (state.errorMessage != null && state.status != AIConfigStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!), 
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          context.read<AIConfigCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final provider = state.providers.firstWhere((p) => p.id == widget.providerId);
        final selectedModelId = state.selectedModelIds[widget.providerId];
        final pool = state.keyPools[widget.providerId];
        final filteredModels = state.getFilteredModels(widget.providerId);
        final isDiscovering = state.status == AIConfigStatus.discoveryInProgress;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(provider.name),
            actions: [
              if (isDiscovering)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => context.read<AIConfigCubit>().refreshModels(widget.providerId),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: Colors.grey[200]),
            ),
          ),
          body: Column(
            children: [
              // Key Pool Section (Top anchored)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'API KEY POOL',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2),
                        ),
                        InkWell(
                          onTap: isDiscovering ? null : () => _showAddKeyDialog(context, widget.providerId),
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 14, color: Colors.blue),
                              SizedBox(width: 4),
                              Text('Add Key', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (pool == null || pool.keys.isEmpty)
                      const Text('No keys configured.', style: TextStyle(color: Colors.grey, fontSize: 12))
                    else
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: pool.keys.length,
                          itemBuilder: (context, poolIndex) {
                            final key = pool.keys[poolIndex];
                            final isActive = pool.activeIndex == poolIndex;

                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isActive ? Colors.blue : Colors.grey[300]!),
                                boxShadow: [
                                  if (isActive) BoxShadow(color: Colors.blue.withValues(alpha: 0.05), blurRadius: 4)
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    key.isExhausted ? Icons.error_outline : Icons.vpn_key_outlined,
                                    color: key.isExhausted ? Colors.red : (isActive ? Colors.blue : Colors.grey),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '••••${key.value.substring(key.value.length > 4 ? key.value.length - 4 : 0)}',
                                    style: TextStyle(
                                      fontSize: 12, 
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      color: isActive ? Colors.blue.shade900 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                                    onPressed: () => context.read<AIConfigCubit>().removeKey(widget.providerId, key.value),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Search models and Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search models...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) => context.read<AIConfigCubit>().updateSearchQuery(val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CustomFilterButton(
                      label: 'Free',
                      isSelected: state.onlyFree,
                      onTap: () => context.read<AIConfigCubit>().toggleOnlyFree(!state.onlyFree),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredModels.isEmpty
                    ? Center(child: Text(isDiscovering ? 'Discovering models...' : 'No models found', style: const TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredModels.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final model = filteredModels[index];
                          return ModelSelectionTile(
                            model: model,
                            isSelected: model.id == selectedModelId,
                            onTap: () => context.read<AIConfigCubit>().selectModel(widget.providerId, model.id),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add API Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Paste your key here',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        context.read<AIConfigCubit>().addKey(providerId, controller.text);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add Key'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomFilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomFilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

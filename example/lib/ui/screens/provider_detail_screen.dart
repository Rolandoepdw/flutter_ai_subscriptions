import 'package:flutter/material.dart';
import 'package:flutter_ai_subscriptions/flutter_ai_subscriptions.dart';
import '../widgets/model_selection_tile.dart';

class ProviderDetailScreen extends StatefulWidget {
  final AIConfigNotifier notifier;
  final String providerId;

  const ProviderDetailScreen({
    super.key, 
    required this.notifier, 
    required this.providerId,
  });

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
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final notifier = widget.notifier;
        
        // Handle messages
        if (notifier.successMessage != null || notifier.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (notifier.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(notifier.successMessage!), 
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (notifier.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(notifier.errorMessage!), 
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            notifier.clearMessages();
          });
        }

        final provider = notifier.providers.firstWhere((p) => p.id == widget.providerId);
        final selectedModelId = notifier.getSelectedModelId(widget.providerId);
        final pool = notifier.getPool(widget.providerId);
        final filteredModels = notifier.getFilteredModels(widget.providerId);
        final isDiscovering = notifier.status == AIConfigStatus.discoveryInProgress;
        
        final isCustom = widget.providerId.startsWith('custom_');
        final customProvider = isCustom ? notifier.customProviders.firstWhere((p) => p.id == widget.providerId) : null;

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
              if (isCustom)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditCustomProviderDialog(context, customProvider!),
                  tooltip: 'Edit Provider',
                ),
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
                  onPressed: () => notifier.refreshModels(widget.providerId),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: Colors.grey[200]),
            ),
          ),
          body: SafeArea(
            top: false,
            bottom: true,
            child: Column(
              children: [
                // Key Pool Section
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
                                Icon(Icons.add, size: 14, color: Colors.blue),
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
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: pool.keys.length,
                            itemBuilder: (context, poolIndex) {
                              final key = pool.keys[poolIndex];
                              final isActive = pool.activeIndex == poolIndex;
  
                              return Container(
                                margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive ? Colors.blue : Colors.grey[300]!, 
                                    width: isActive ? 1.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    if (isActive) BoxShadow(color: Colors.blue.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                                    else BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      key.isExhausted ? Icons.error_outline : Icons.vpn_key_outlined,
                                      color: key.isExhausted ? Colors.red : (isActive ? Colors.blue : Colors.grey),
                                      size: 16,
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
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => notifier.removeKey(widget.providerId, key.value),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 12, color: Colors.grey),
                                      ),
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
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: false,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Search models...',
                              prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (val) => notifier.updateSearchQuery(val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CustomFilterButton(
                        label: 'Free',
                        isSelected: notifier.onlyFree,
                        onTap: () => notifier.toggleOnlyFree(!notifier.onlyFree),
                      ),
                    ],
                  ),
                ),
  
                Expanded(
                  child: filteredModels.isEmpty
                      ? Center(child: Text(isDiscovering ? 'Discovering models...' : 'No models found', style: const TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          itemCount: filteredModels.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final model = filteredModels[index];
                            return ModelSelectionTile(
                              model: model,
                              isSelected: model.id == selectedModelId,
                              onTap: () => notifier.selectModel(widget.providerId, model.id),
                            );
                          },
                        ),
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
    _showStyledDialog(
      context: context,
      title: 'Add API Key',
      content: [
        _buildField('API Key', controller, autofocus: true, hint: 'Paste your key here'),
      ],
      onConfirm: () {
        if (controller.text.isNotEmpty) {
          widget.notifier.addKey(providerId, controller.text);
          Navigator.pop(context);
        }
      },
      confirmLabel: 'Add Key',
    );
  }

  void _showEditCustomProviderDialog(BuildContext context, CustomProvider provider) {
    final nameController = TextEditingController(text: provider.name);
    final urlController = TextEditingController(text: provider.baseUrl);
    
    _showStyledDialog(
      context: context,
      title: 'Edit Custom Provider',
      content: [
        _buildField('Name', nameController),
        const SizedBox(height: 12),
        _buildField('Base URL', urlController),
      ],
      onConfirm: () {
        if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
          final updated = CustomProvider(
            id: provider.id,
            name: nameController.text,
            baseUrl: urlController.text,
          );
          widget.notifier.updateCustomProvider(updated);
          Navigator.pop(context);
        }
      },
      confirmLabel: 'Save Changes',
    );
  }

  void _showStyledDialog({
    required BuildContext context,
    required String title,
    required List<Widget> content,
    required VoidCallback onConfirm,
    required String confirmLabel,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...content,
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onConfirm,
                    child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool autofocus = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
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

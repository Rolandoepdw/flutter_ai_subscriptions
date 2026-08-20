import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_cubit.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_state.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/custom_provider.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/ui/provider_detail_screen.dart';
import 'package:uuid/uuid.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: () => _showAddCustomProviderDialog(context),
            tooltip: 'Add Custom Provider',
          ),
        ],
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
              final isCustom = provider.iconPath.contains('custom');

              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[100],
                  child: Icon(
                    isCustom ? Icons.lan_outlined : Icons.psychology_outlined,
                    color: isSelected ? Colors.blue : Colors.grey[600],
                    size: 20
                  ),
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
                trailing: isCustom
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      onPressed: () => context.read<AIConfigCubit>().removeCustomProvider(provider.id),
                    )
                  : Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
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

  void _showAddCustomProviderDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController(text: 'http://localhost:1234');
    
    _showStyledDialog(
      context: context,
      title: 'Add Custom Provider',
      content: [
        _buildField('Name', nameController, autofocus: true, hint: 'e.g. LM Studio'),
        const SizedBox(height: 16),
        _buildField('Base URL', urlController, hint: 'http://localhost:1234'),
      ],
      onConfirm: () {
        if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
          final provider = CustomProvider(
            id: 'custom_${const Uuid().v4()}',
            name: nameController.text,
            baseUrl: urlController.text,
          );
          context.read<AIConfigCubit>().addCustomProvider(provider);
          Navigator.pop(context);
        }
      },
      confirmLabel: 'Add Provider',
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

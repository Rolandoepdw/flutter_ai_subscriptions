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
    return BlocBuilder<AIConfigCubit, AIConfigState>(
      builder: (context, state) {
        final provider = state.providers.firstWhere((p) => p.id == providerId);
        final selectedModelId = state.selectedModelIds[providerId];
        final pool = state.keyPools[providerId];
        final isSelectedProvider = state.selectedProviderId == providerId;

        return Scaffold(
          appBar: AppBar(
            title: Text(provider.name),
            actions: [
              if (!isSelectedProvider)
                TextButton(
                  onPressed: () => context.read<AIConfigCubit>().selectProvider(providerId),
                  child: const Text('Activar', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccionar Modelo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...provider.models.map((model) {
                  return RadioListTile<String>(
                    title: Text(model.name),
                    subtitle: Text(model.tier == AITier.free ? 'Gratuito' : 'De pago'),
                    secondary: model.tier == AITier.free 
                        ? const Icon(Icons.money_off, color: Colors.green)
                        : const Icon(Icons.attach_money, color: Colors.orange),
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
                      'Pool de Claves API',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddKeyDialog(context, providerId),
                    ),
                  ],
                ),
                if (pool == null || pool.keys.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('No hay claves configuradas para este proveedor.'),
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
                        subtitle: Text(key.isExhausted ? 'Agotada' : (isActive ? 'Activa' : 'En reserva')),
                        trailing: isActive && isSelectedProvider 
                          ? const Icon(Icons.play_arrow, color: Colors.blue)
                          : null,
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
        title: const Text('Añadir Clave API'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Pega aquí tu clave'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<AIConfigCubit>().addKey(providerId, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_cubit.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/cubit/ai_config_state.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/models/ai_model.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/ui/provider_list_screen.dart';
import 'package:flutter_ai_subscriptions/features/ai_config/ui/widgets/model_selection_tile.dart';
import 'package:flutter_ai_subscriptions/features/chat/cubit/chat_cubit.dart';
import 'package:flutter_ai_subscriptions/features/chat/cubit/chat_state.dart';
import 'package:flutter_ai_subscriptions/features/chat/models/chat_message.dart';
import 'package:flutter_ai_subscriptions/core/injection/service_locator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ChatCubit>(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'AI Assistant',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatCubit, ChatState>(
                listener: (context, state) {
                  if (state.status == ChatStatus.success || state.status == ChatStatus.loading) {
                    _scrollToBottom();
                  }
                },
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 48, color: Colors.blue[200]),
                          const SizedBox(height: 16),
                          Text(
                            'How can I help you today?',
                            style: TextStyle(color: Colors.grey[400], fontSize: 16)
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      if (message.isSystemLog) {
                        return _SystemLogTile(content: message.content);
                      }
                      return _MessageTile(message: message);
                    },
                  );
                },
              ),
            ),
            _AdvancedInputPanel(controller: _controller),
          ],
        ),
      ),
    );
  }
}

class _SystemLogTile extends StatelessWidget {
  final String content;
  const _SystemLogTile({required this.content});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          content,
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final ChatMessage message;
  const _MessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.content));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message copied'), duration: Duration(seconds: 1)),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser) Icon(Icons.smart_toy_outlined, size: 14, color: Colors.blue[600]),
                  if (!isUser) const SizedBox(width: 6),
                  Text(
                    isUser ? 'You' : 'AI Assistant',
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser ? Colors.blue[600] : Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: SelectableText(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87, 
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedInputPanel extends StatelessWidget {
  final TextEditingController controller;
  const _AdvancedInputPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIConfigCubit, AIConfigState>(
      builder: (context, configState) {
        final providerId = configState.selectedProviderId;
        final selectedModelId = configState.selectedModelIds[providerId];
        final allModelsMap = configState.getGlobalFilteredModels();
        
        AIModel? selectedModel;
        for (final entry in allModelsMap.values) {
          final found = entry.where((m) => m.id == selectedModelId).toList();
          if (found.isNotEmpty) {
            selectedModel = found.first;
            break;
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _ModelSelectorButton(selectedModel: selectedModel),
                    const Spacer(),
                    if (selectedModel != null) ...[
                      _LargeCapabilityIcon(icon: Icons.visibility_outlined, active: selectedModel.hasVision),
                      _LargeCapabilityIcon(icon: Icons.build_outlined, active: selectedModel.hasTools),
                      _LargeCapabilityIcon(icon: Icons.psychology_outlined, active: selectedModel.hasReasoning),
                    ]
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Ask anything...',
                            border: InputBorder.none,
                          ),
                          maxLines: 6,
                          minLines: 1,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      BlocBuilder<ChatCubit, ChatState>(
                        builder: (context, chatState) {
                          final isLoading = chatState.status == ChatStatus.loading;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: IconButton(
                              icon: isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                                : const Icon(Icons.arrow_upward, color: Colors.blue),
                              onPressed: isLoading 
                                ? null 
                                : () {
                                    final text = controller.text;
                                    if (text.isNotEmpty) {
                                      context.read<ChatCubit>().sendMessage(text);
                                      controller.clear();
                                    }
                                  },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class _ModelSelectorButton extends StatelessWidget {
  final AIModel? selectedModel;

  const _ModelSelectorButton({this.selectedModel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showAdvancedSelector(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedModel?.name ?? 'Select Model',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_up, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  void _showAdvancedSelector(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ModelSelector',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return const _AdvancedModelSelectorDialog();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim1),
            child: child,
          ),
        );
      },
    );
  }
}

class _AdvancedModelSelectorDialog extends StatefulWidget {
  const _AdvancedModelSelectorDialog();

  @override
  State<_AdvancedModelSelectorDialog> createState() => _AdvancedModelSelectorDialogState();
}

class _AdvancedModelSelectorDialogState extends State<_AdvancedModelSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIConfigCubit, AIConfigState>(
      builder: (context, state) {
        final groupedModels = state.getGlobalFilteredModels();

        return Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: TextField(
                              controller: _searchController,
                              autofocus: false, // Quitado el autofoco
                              textAlignVertical: TextAlignVertical.center,
                              decoration: const InputDecoration(
                                hintText: 'Search models...',
                                prefixIcon: Icon(Icons.search, size: 20),
                                isCollapsed: true,
                                border: InputBorder.none,
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
                    child: ListView.builder(
                      itemCount: groupedModels.length,
                      itemBuilder: (context, index) {
                        final providerName = groupedModels.keys.elementAt(index);
                        final models = groupedModels[providerName]!;
                        final providerId = state.providers.firstWhere((p) => p.name == providerName).id;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                              child: Text(
                                providerName.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.5),
                              ),
                            ),
                            ...models.map((model) => ModelSelectionTile(
                              model: model,
                              isSelected: state.selectedModelIds[providerId] == model.id && state.selectedProviderId == providerId,
                              onTap: () {
                                context.read<AIConfigCubit>().selectModel(providerId, model.id);
                                Navigator.pop(context);
                              },
                            )),
                          ],
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        child: const Icon(Icons.settings_outlined, size: 20, color: Colors.blue),
                      ),
                      title: const Text('Manage Providers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProviderListScreen()));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class _LargeCapabilityIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _LargeCapabilityIcon({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 14, color: Colors.blue),
    );
  }
}

class _CustomFilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomFilterButton({required this.label, required this.isSelected, required this.onTap});

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
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[600]),
        ),
      ),
    );
  }
}

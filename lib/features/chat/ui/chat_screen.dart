import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../ai_config/cubit/ai_config_cubit.dart';
import '../../ai_config/cubit/ai_config_state.dart';
import '../../ai_config/ui/provider_list_screen.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../models/chat_message.dart';
import '../../../core/injection/service_locator.dart';

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
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: BlocBuilder<AIConfigCubit, AIConfigState>(
            builder: (context, state) {
              final providerId = state.selectedProviderId;
              final modelId = state.selectedModelIds[providerId];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Chat', style: TextStyle(color: Colors.white, fontSize: 18)),
                  if (modelId != null)
                    Text(
                      modelId,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProviderListScreen()),
              ),
            ),
          ],
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
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      if (message.isSystemLog) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message.content,
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        );
                      }
                      return _MessageTile(message: message);
                    },
                  );
                },
              ),
            ),
            _InputPanel(controller: _controller),
          ],
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 12),
          ),
        ),
        child: Text(message.content),
      ),
    );
  }
}

class _InputPanel extends StatelessWidget {
  final TextEditingController controller;
  const _InputPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              maxLines: null,
            ),
          ),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              final isLoading = state.status == ChatStatus.loading;
              return IconButton(
                icon: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.blue),
                onPressed: isLoading 
                  ? null 
                  : () {
                      final text = controller.text;
                      if (text.isNotEmpty) {
                        context.read<ChatCubit>().sendMessage(text);
                        controller.clear();
                      }
                    },
              );
            },
          ),
        ],
      ),
    );
  }
}

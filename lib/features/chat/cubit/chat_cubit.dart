import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;
  final _uuid = const Uuid();

  ChatCubit(this._chatService) : super(const ChatState());

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(state.messages)..add(userMessage);
    emit(state.copyWith(messages: updatedMessages, status: ChatStatus.loading));

    try {
      final response = await _chatService.sendMessage(updatedMessages);
      
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: response,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: List<ChatMessage>.from(state.messages)..add(assistantMessage),
        status: ChatStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void addSystemLog(String log) {
    final logMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.system,
      content: log,
      timestamp: DateTime.now(),
      isSystemLog: true,
    );
    emit(state.copyWith(messages: List<ChatMessage>.from(state.messages)..add(logMessage)));
  }

  void clearChat() {
    emit(const ChatState());
  }
}

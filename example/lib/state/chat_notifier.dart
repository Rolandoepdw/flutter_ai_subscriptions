import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:example/models/chat_message.dart';
import 'package:example/services/chat_service.dart';

enum ChatStatus { initial, loading, success, error }

class ChatNotifier extends ChangeNotifier {
  final ChatService _chatService;
  final _uuid = const Uuid();

  ChatNotifier(this._chatService);

  List<ChatMessage> _messages = [];
  ChatStatus _status = ChatStatus.initial;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  ChatStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    _messages = List<ChatMessage>.from(_messages)..add(userMessage);
    _status = ChatStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _chatService.sendMessage(_messages);
      
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: response,
        timestamp: DateTime.now(),
      );

      _messages = List<ChatMessage>.from(_messages)..add(assistantMessage);
      _status = ChatStatus.success;
    } catch (e) {
      _status = ChatStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void addSystemLog(String log) {
    final logMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.system,
      content: log,
      timestamp: DateTime.now(),
      isSystemLog: true,
    );
    _messages = List<ChatMessage>.from(_messages)..add(logMessage);
    notifyListeners();
  }

  void clearChat() {
    _messages = [];
    _status = ChatStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}

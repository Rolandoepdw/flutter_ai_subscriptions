import 'package:equatable/equatable.dart';

enum MessageRole { system, user, assistant }

class ChatMessage extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<String>? imageUrls;
  final bool isSystemLog; // For internal service logs like "Rotating key..."

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.imageUrls,
    this.isSystemLog = false,
  });

  @override
  List<Object?> get props => [id, role, content, timestamp, imageUrls, isSystemLog];
}

class ChatMessage {
  final String role; // "user" or "ai"
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: map['role'] ?? '',
      content: map['content'] ?? '',
    );
  }
}

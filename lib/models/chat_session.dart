class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content};
  }
}

class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime updatedAt;
  final String? folder; // matches desktop schema: 'wealth', 'health', etc.

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
    this.folder,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    var msgs = <ChatMessage>[];
    if (json['messages'] != null) {
      if (json['messages'] is List) {
        msgs = (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m))
            .toList();
      }
    }

    return ChatSession(
      id: json['id'],
      title: json['title'] ?? 'New Chat',
      messages: msgs,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      folder: json['folder'],
    );
  }
}

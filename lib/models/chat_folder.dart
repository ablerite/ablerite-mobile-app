class ChatFolder {
  final String id;
  final String name;
  final String userId;
  // final int orderIndex; // Optional if needed

  ChatFolder({required this.id, required this.name, required this.userId});

  factory ChatFolder.fromJson(Map<String, dynamic> json) {
    return ChatFolder(
      id: json['id'],
      name: json['name'] ?? 'Untitled Folder',
      userId: json['user_id'] ?? '',
    );
  }
}

class JournalEntry {
  final String id;
  final String title; // Mapped from 'text' (e.g. "Monday, Jan 19")
  final String content; // Mapped from 'why' (The actual entry)
  final DateTime date;
  final DateTime createdAt;
  final String? parentId;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.createdAt,
    this.parentId,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic val) => val?.toString() ?? '';

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return JournalEntry(
      id: safeString(json['id']),
      title: safeString(json['text']),
      content: safeString(json['why']),
      date: json['date'] != null
          ? parseDate(json['date'])
          : parseDate(json['created_at']),
      createdAt: parseDate(json['created_at']),
      parentId: json['parent_id'] as String?,
    );
  }
}

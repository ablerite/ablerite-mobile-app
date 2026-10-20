class Item {
  final String id;
  final String text;
  final bool? completed;
  final String? status;
  final String section;
  final String userId;
  final int? orderIndex;
  final String? boardId;
  final String? listId;
  final String? parentId;
  final String? imageUrl;
  final String? why;
  final String? category;
  final String? dueDate;
  final String? startDate;
  final int? value;
  final String? date;
  final bool? archived;
  final String? createdAt;
  final String? targetDate;
  final List<String>? relatedIds;

  Item({
    required this.id,
    required this.text,
    this.completed,
    this.status,
    required this.section,
    required this.userId,
    this.orderIndex,
    this.boardId,
    this.listId,
    this.parentId,
    this.imageUrl,
    this.why,
    this.category,
    this.dueDate,
    this.startDate,
    this.value,
    this.date,
    this.archived,
    this.createdAt,
    this.targetDate,
    this.relatedIds,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      text: json['text'] ?? '',
      completed: json['is_completed'] ?? json['completed'],
      status: json['status'],
      section: json['section'] ?? '',
      userId: json['user_id'] ?? '',
      orderIndex: json['order_index'],
      boardId: json['board_id'],
      listId: json['list_id'],
      parentId: json['parent_id'],
      imageUrl: json['image_url'],
      why: json['why'],
      category: json['category'],
      dueDate: json['due_date'],
      startDate: json['start_date'],
      value: json['value'],
      date: json['date'],
      archived: json['archived'],
      createdAt: json['created_at'],
      targetDate: json['target_date'],
      relatedIds: json['related_ids'] != null
          ? List<String>.from(json['related_ids'] as List)
          : null,
    );
  }

  Item copyWith({
    String? id,
    String? text,
    bool? completed,
    String? status,
    String? section,
    String? userId,
    int? orderIndex,
    String? boardId,
    String? listId,
    String? parentId,
    String? imageUrl,
    String? why,
    String? category,
    String? dueDate,
    String? startDate,
    int? value,
    String? date,
    bool? archived,
    String? createdAt,
    String? targetDate,
    List<String>? relatedIds,
  }) {
    return Item(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      status: status ?? this.status,
      section: section ?? this.section,
      userId: userId ?? this.userId,
      orderIndex: orderIndex ?? this.orderIndex,
      boardId: boardId ?? this.boardId,
      listId: listId ?? this.listId,
      parentId: parentId ?? this.parentId,
      imageUrl: imageUrl ?? this.imageUrl,
      why: why ?? this.why,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      value: value ?? this.value,
      date: date ?? this.date,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      relatedIds: relatedIds ?? this.relatedIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
      'status': status,
      'section': section,
      'user_id': userId,
      'order_index': orderIndex,
      'parent_id': parentId,
      'image_url': imageUrl,
      'why': why,
      'category': category,
      'due_date': dueDate,
      'start_date': startDate,
      'value': value,
      'date': date,
      'archived': archived,
      'created_at': createdAt,
      'target_date': targetDate,
      'related_ids': relatedIds,
    };
  }
}

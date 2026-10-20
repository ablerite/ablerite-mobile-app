class CashItem {
  final String id;
  final String label;
  final int value;
  final bool isCompleted;
  final String userId;
  final String? category; // Made nullable to handle legacy data
  final String? createdAt;
  final int? orderIndex;

  CashItem({
    required this.id,
    required this.label,
    required this.value,
    required this.isCompleted,
    required this.userId,
    this.category,
    this.createdAt,
    this.orderIndex,
  });

  factory CashItem.fromJson(Map<String, dynamic> json) {
    return CashItem(
      id: json['id'] ?? '',
      label: json['text'] ?? json['label'] ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] ?? false,
      userId: json['user_id'] ?? '',
      category: json['category'] as String?,
      createdAt: json['created_at'],
      orderIndex: json['order_index'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': label,
      'value': value,
      'is_completed': isCompleted,
      'user_id': userId,
      'category': category,
      'created_at': createdAt,
      'order_index': orderIndex,
    };
  }

  CashItem copyWith({
    String? id,
    String? label,
    int? value,
    bool? isCompleted,
    String? userId,
    String? category,
    String? createdAt,
    int? orderIndex,
  }) {
    return CashItem(
      id: id ?? this.id,
      label: label ?? this.label,
      value: value ?? this.value,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

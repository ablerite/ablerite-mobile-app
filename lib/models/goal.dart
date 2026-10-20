import 'item.dart';

const int goalTypeAssetValueFallback = -900001;
const int goalTypeLiabilityValueFallback = -900002;

class Goal extends Item {
  final String? goalType; // 'need', 'desire', 'asset', or 'liability'
  final bool isPrimary;
  final double? costEstimate;
  final String? costType; // 'one-time', 'monthly', 'annual'
  final List<String>? relatedVisionBoardIds;
  final String? specific;
  final String? measurable;
  final String? achievable;
  final String? relevant;

  Goal({
    required super.id,
    required super.text,
    required super.userId,
    required super.section,
    super.category,
    super.parentId,
    super.completed,
    super.archived,
    super.orderIndex,
    super.dueDate,
    super.startDate,
    super.value,
    this.goalType,
    super.why,
    this.isPrimary = false,
    this.costEstimate,
    this.costType,
    super.relatedIds,
    this.relatedVisionBoardIds,
    this.specific,
    this.measurable,
    this.achievable,
    this.relevant,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    final rawValue = json['value'] != null
        ? (json['value'] as num).toInt()
        : null;
    final storedGoalType = json['goal_type'] as String?;
    final goalType = switch (rawValue) {
      goalTypeAssetValueFallback => 'asset',
      goalTypeLiabilityValueFallback => 'liability',
      _ => storedGoalType,
    };

    return Goal(
      id: json['id'] as String,
      text: json['text'] as String,
      userId: json['user_id'] as String,
      section: json['section'] as String,
      category: json['category'] as String?,
      parentId: json['parent_id'] as String?,
      completed: json['completed'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      orderIndex: json['order_index'] as int?,
      dueDate: json['due_date'] as String?,
      startDate: json['start_date'] as String?,
      value: rawValue,
      goalType: goalType,
      why: json['why'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      costEstimate: json['cost_estimate'] != null
          ? (json['cost_estimate'] as num).toDouble()
          : null,
      costType: json['cost_type'] as String?,
      relatedIds: json['related_ids'] != null
          ? List<String>.from(json['related_ids'] as List)
          : null,
      relatedVisionBoardIds: json['related_vision_board_ids'] != null
          ? List<String>.from(json['related_vision_board_ids'] as List)
          : null,
      specific: json['specific'] as String?,
      measurable: json['measurable'] as String?,
      achievable: json['achievable'] as String?,
      relevant: json['relevant'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'text': text,
      'section': section,
      'category': category,
      'parent_id': parentId,
      'completed': completed,
      'order_index': orderIndex,
      'due_date': dueDate,
      'start_date': startDate,
      'value': value,
      'goal_type': goalType,
      'why': why,
      'is_primary': isPrimary,
      'cost_estimate': costEstimate,
      'cost_type': costType,
      'related_ids': relatedIds,
      'related_vision_board_ids': relatedVisionBoardIds,
      'specific': specific,
      'measurable': measurable,
      'achievable': achievable,
      'relevant': relevant,
    };
  }

  @override
  Goal copyWith({
    String? id,
    String? text,
    String? userId,
    String? section,
    String? category,
    String? parentId,
    bool? completed,
    String? status,
    int? orderIndex,
    String? boardId,
    String? listId,
    String? imageUrl,
    String? dueDate,
    String? startDate,
    int? value,
    String? date,
    bool? archived,
    String? createdAt,
    String? goalType,
    String? why,
    bool? isPrimary,
    double? costEstimate,
    String? costType,
    List<String>? relatedIds,
    List<String>? relatedVisionBoardIds,
    String? specific,
    String? measurable,
    String? achievable,
    String? relevant,
    String? targetDate,
  }) {
    return Goal(
      id: id ?? this.id,
      text: text ?? this.text,
      userId: userId ?? this.userId,
      section: section ?? this.section,
      category: category ?? this.category,
      parentId: parentId ?? this.parentId,
      completed: completed ?? this.completed,
      orderIndex: orderIndex ?? this.orderIndex,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      value: value ?? this.value,
      goalType: goalType ?? this.goalType,
      why: why ?? this.why,
      isPrimary: isPrimary ?? this.isPrimary,
      costEstimate: costEstimate ?? this.costEstimate,
      costType: costType ?? this.costType,
      relatedIds: relatedIds ?? this.relatedIds,
      relatedVisionBoardIds:
          relatedVisionBoardIds ?? this.relatedVisionBoardIds,
      specific: specific ?? this.specific,
      measurable: measurable ?? this.measurable,
      achievable: achievable ?? this.achievable,
      relevant: relevant ?? this.relevant,
    );
  }
}

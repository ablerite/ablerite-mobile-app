import 'dart:convert';

class VisionItem {
  final String id;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final String? parentId;
  final double? canvasX;
  final double? canvasY;
  final double? canvasWidth;
  final int? canvasZ;

  VisionItem({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.parentId,
    this.canvasX,
    this.canvasY,
    this.canvasWidth,
    this.canvasZ,
  });

  factory VisionItem.fromJson(Map<String, dynamic> json) {
    final layout = _parseCanvasLayout(json['why']);
    return VisionItem(
      id: json['id'],
      text: json['text'] ?? '',
      imageUrl:
          json['image_url'], // Ensure this matches Supabase column snake_case
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      parentId: json['parent_id'],
      canvasX: layout?['x'],
      canvasY: layout?['y'],
      canvasWidth: layout?['width'],
      canvasZ: layout?['z']?.round(),
    );
  }

  static Map<String, double>? _parseCanvasLayout(dynamic raw) {
    if (raw == null) return null;
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return null;
      final canvas = decoded['vision_canvas'];
      if (canvas is! Map) return null;

      double? readDouble(String key) {
        final value = canvas[key];
        if (value is num) return value.toDouble();
        return null;
      }

      final x = readDouble('x');
      final y = readDouble('y');
      final width = readDouble('width');
      if (x == null || y == null || width == null) return null;
      return {'x': x, 'y': y, 'width': width, 'z': readDouble('z') ?? 0};
    } catch (_) {
      return null;
    }
  }
}

import 'package:flutter/material.dart';

/// Mirrors the Supabase `collections` table.
class Collection {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final String? color; // hex string e.g. "#F87171"
  final String? description;
  final int position;
  final bool isPinned;
  final DateTime createdAt;

  const Collection({
    required this.id,
    required this.userId,
    required this.name,
    this.emoji = '📚',
    this.color,
    this.description,
    this.position = 0,
    this.isPinned = false,
    required this.createdAt,
  });

  /// Predefined color palette for the picker.
  static const List<String> palette = [
    '#F87171', // red
    '#FB923C', // orange
    '#FBBF24', // amber
    '#4ADE80', // green
    '#60A5FA', // blue
    '#818CF8', // indigo
    '#E879F9', // pink
    '#94A3B8', // slate
  ];

  /// Common emoji options for the picker.
  static const List<String> emojiOptions = [
    '📚', '🎬', '💼', '✈️', '🎮', '🏠', '🍔', '📖', '🎵', '⚽',
    '🎨', '💡', '🌍', '🔬', '📱', '🎭', '🌿', '💻', '🏋️', '🎯',
  ];

  /// Convert hex color string to Flutter Color.
  Color? get flutterColor {
    if (color == null) return null;
    try {
      return Color(int.parse(color!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  Collection copyWith({
    String? id,
    String? userId,
    String? name,
    String? emoji,
    String? color,
    bool clearColor = false,
    String? description,
    bool clearDescription = false,
    int? position,
    bool? isPinned,
    DateTime? createdAt,
  }) =>
      Collection(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        color: clearColor ? null : color ?? this.color,
        description: clearDescription ? null : description ?? this.description,
        position: position ?? this.position,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt ?? this.createdAt,
      );

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '📚',
        color: json['color'] as String?,
        description: json['description'] as String?,
        position: json['position'] as int? ?? 0,
        isPinned: json['is_pinned'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'emoji': emoji,
        'color': color,
        'description': description,
        'position': position,
        'is_pinned': isPinned,
        'created_at': createdAt.toIso8601String(),
      };

  /// For INSERT — omits id and created_at.
  Map<String, dynamic> toInsertJson() {
    final m = toJson()..remove('id')..remove('created_at');
    return m;
  }
}

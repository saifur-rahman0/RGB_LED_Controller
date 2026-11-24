import 'package:flutter/material.dart';

/// User-saved custom named scene capturing Color, Brightness, and optional Effect Mode/Speed.
class UserScene {
  final String id;
  final String name;
  final Color color;
  final int brightness; // 1..100
  final int? effectMode; // e.g. 0x87 for 7-color crossfade, or null for solid color
  final int? effectSpeed; // 1..100
  final String? iconName;

  const UserScene({
    required this.id,
    required this.name,
    required this.color,
    required this.brightness,
    this.effectMode,
    this.effectSpeed,
    this.iconName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'brightness': brightness,
      'effectMode': effectMode,
      'effectSpeed': effectSpeed,
      'iconName': iconName,
    };
  }

  factory UserScene.fromJson(Map<String, dynamic> json) {
    return UserScene(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Untitled Scene',
      color: Color(json['color'] as int? ?? 0xFFFF0055),
      brightness: (json['brightness'] as int? ?? 100).clamp(1, 100),
      effectMode: json['effectMode'] as int?,
      effectSpeed: json['effectSpeed'] as int?,
      iconName: json['iconName'] as String?,
    );
  }

  UserScene copyWith({
    String? id,
    String? name,
    Color? color,
    int? brightness,
    int? effectMode,
    int? effectSpeed,
    String? iconName,
  }) {
    return UserScene(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      brightness: brightness ?? this.brightness,
      effectMode: effectMode ?? this.effectMode,
      effectSpeed: effectSpeed ?? this.effectSpeed,
      iconName: iconName ?? this.iconName,
    );
  }
}

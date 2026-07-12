import 'package:flutter/material.dart';

class AssetItem {
  int id;
  String name;
  String type;
  double value;
  String iconData;
  int color;
  DateTime createdAt;
  DateTime updatedAt;

  AssetItem({
    this.id = 0,
    required this.name,
    required this.type,
    required this.value,
    this.iconData = 'material:57522',
    this.color = 0xFF2196F3,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  IconData get flutterIcon {
    if (iconData.startsWith('material:')) {
      final code = int.tryParse(iconData.split(':')[1]);
      if (code != null) return IconData(code, fontFamily: 'MaterialIcons');
    }
    return Icons.category;
  }
}

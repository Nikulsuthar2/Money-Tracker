import 'package:flutter/material.dart';

class CategoryIconWidget extends StatelessWidget {
  final String iconData;
  final int fallbackIcon;
  final int color;
  final double size;

  const CategoryIconWidget({
    super.key,
    required this.iconData,
    this.fallbackIcon = 57522,
    required this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (iconData.startsWith('emoji:')) {
      return Text(
        iconData.replaceFirst('emoji:', ''),
        style: TextStyle(fontSize: size),
      );
    } else if (iconData.startsWith('asset:')) {
      return Image.asset(
        iconData.replaceFirst('asset:', ''),
        width: size,
        height: size,
      );
    } else {
      final code = int.tryParse(iconData.replaceFirst('material:', '')) ?? fallbackIcon;
      return Icon(
        IconData(code, fontFamily: 'MaterialIcons'),
        size: size,
        color: Color(color == 0 ? 0xFF9E9E9E : color),
      );
    }
  }
}

import 'package:flutter/material.dart';

class GoalIconWidget extends StatelessWidget {
  final String iconData;
  final Color color;
  final double size;
  final double iconSize;

  const GoalIconWidget({
    super.key,
    required this.iconData,
    required this.color,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (iconData.startsWith('emoji:')) {
      final emoji = iconData.replaceFirst('emoji:', '');
      child = Text(emoji, style: TextStyle(fontSize: iconSize));
    } else if (iconData.startsWith('material:')) {
      final code = int.tryParse(iconData.replaceFirst('material:', ''));
      child = code != null 
          ? Icon(IconData(code, fontFamily: 'MaterialIcons'), color: color, size: iconSize) 
          : Icon(Icons.star, color: color, size: iconSize);
    } else if (iconData.startsWith('asset:')) {
      final assetPath = iconData.replaceFirst('asset:', '');
      child = Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(assetPath, fit: BoxFit.contain, width: iconSize, height: iconSize),
      );
    } else {
      child = Icon(Icons.star, color: color, size: iconSize);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }
}

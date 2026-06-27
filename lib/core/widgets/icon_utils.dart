import 'package:flutter/material.dart';

Widget buildIconWidget(String iconStr, Color color, {double size = 32, bool circle = true}) {
  if (iconStr.startsWith('emoji:')) {
    final emoji = iconStr.replaceFirst('emoji:', '');
    return Container(
      width: size,
      height: size,
      decoration: circle ? BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ) : null,
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * (circle ? 0.5 : 0.7), height: 1.1), textAlign: TextAlign.center),
    );
  } else if (iconStr.startsWith('asset:')) {
    final assetPath = iconStr.replaceFirst('asset:', '');
    return Container(
      width: size,
      height: size,
      decoration: circle ? BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ) : null,
      alignment: Alignment.center,
      child: Image.asset(assetPath, width: size * (circle ? 0.5 : 0.7), height: size * (circle ? 0.5 : 0.7)),
    );
  } else {
    // Normal Icon
    final iconCode = int.tryParse(iconStr);
    return Container(
      width: size,
      height: size,
      decoration: circle ? BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ) : null,
      alignment: Alignment.center,
      child: Icon(
        iconCode != null ? IconData(iconCode, fontFamily: 'MaterialIcons') : Icons.category,
        color: color,
        size: size * (circle ? 0.6 : 0.8),
      ),
    );
  }
}

String formatAmount(double amount) {
  return amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);
}

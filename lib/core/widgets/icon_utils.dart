import 'package:flutter/material.dart';

Widget buildIconWidget(String iconStr, Color color, {double size = 32}) {
  if (iconStr.startsWith('emoji:')) {
    final emoji = iconStr.replaceFirst('emoji:', '');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  } else if (iconStr.startsWith('asset:')) {
    final assetPath = iconStr.replaceFirst('asset:', '');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Image.asset(assetPath, width: size * 0.5, height: size * 0.5),
    );
  } else {
    // Normal Icon
    final iconCode = int.tryParse(iconStr);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        iconCode != null ? IconData(iconCode, fontFamily: 'MaterialIcons') : Icons.category,
        color: color,
        size: size * 0.6,
      ),
    );
  }
}

String formatAmount(double amount) {
  return amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);
}

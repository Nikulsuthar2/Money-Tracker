import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // If it's a mobile platform or web, use standard RefreshIndicator
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: child,
      );
    }
    
    // On desktop, just return the child directly.
    // The refresh button will be placed in the AppBar manually where needed.
    return child;
  }
}

// Helper to check if we are on a desktop platform to conditionally show an AppBar action
bool isDesktopPlatform() {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:money_manager/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MoneyManagerApp()));

    // Verify that the app builds without crashing.
    // Since the app starts with a splash or dashboard, we might not see "0" or "1".
    // Just ensuring it pumps is enough for a smoke test here.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

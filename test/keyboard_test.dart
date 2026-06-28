import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/widgets/custom_amount_keyboard.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Keyboard test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              CustomAmountKeyboard.show(context);
            },
            child: const Text('Show'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('-'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('-'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.text('--'), findsOneWidget); // Will fail if not found
  });
}

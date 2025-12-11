import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:dotted_border/dotted_border.dart';

void main() {
  testWidgets('SmoothButton shows DottedBorder when type is dashed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmoothButton(
            label: 'Dashed',
            type: SmoothButtonType.dashed,
            onPressed: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(DottedBorder), findsOneWidget);
  });
}

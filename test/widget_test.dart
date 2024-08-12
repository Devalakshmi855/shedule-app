import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/main.dart';

void main() {
  testWidgets('Reminder app UI test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Reminder App'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNWidgets(1));
    expect(find.textContaining('Select Time'), findsOneWidget);

    expect(find.byType(DropdownButton<String>), findsNWidgets(1));
    expect(find.widgetWithText(ElevatedButton, 'Set Reminder'), findsOneWidget);
  });
}

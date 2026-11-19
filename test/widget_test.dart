import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safelog/data/incident_db.dart';
import 'package:safelog/screens/incident_form_screen.dart';

/// Checks that the form shows validation errors and does not save
/// when the title is empty or too short.
void main() {
  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: IncidentFormScreen(db: IncidentDb())));
  }

  testWidgets('empty title shows an error', (tester) async {
    await openForm(tester);
    await tester.tap(find.text('Save incident'));
    await tester.pump();
    expect(find.text('Please enter a title'), findsOneWidget);
  });

  testWidgets('short title shows an error', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).first, 'ab');
    await tester.tap(find.text('Save incident'));
    await tester.pump();
    expect(find.text('Title must be at least 3 characters'), findsOneWidget);
  });

  testWidgets('script tag in title is rejected', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).first, '<script>alert(1)</script>');
    await tester.tap(find.text('Save incident'));
    await tester.pump();
    expect(find.text('Only letters, numbers and basic punctuation are allowed'), findsOneWidget);
  });
}

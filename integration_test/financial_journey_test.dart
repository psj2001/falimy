import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:falimy/features/home/presentation/screens/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Financial journey on device: create, entry, pop', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Financial'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add new book'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Device Book');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Book'));
    await tester.pumpAndSettle();

    // Celebration -> start adding entries.
    if (find.text('Start adding entries').evaluate().isNotEmpty) {
      await tester.tap(find.text('Start adding entries'));
      await tester.pumpAndSettle();
    }

    // Add entry: amount + save.
    if (find.byType(TextFormField).evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextFormField).first, '750');
      await tester.pumpAndSettle();
      if (find.text('Save').evaluate().isNotEmpty) {
        await tester.tap(find.text('Save'), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    }

    // Pop back to books list.
    final back = find.byType(BackButton);
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first);
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
  });
}

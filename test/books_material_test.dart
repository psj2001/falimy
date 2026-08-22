import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:falimy/features/financial/presentation/screens/books_screen.dart';
import 'package:falimy/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('BooksScreen quick-add chips build under HomeScreen Scaffold',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Add new book'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BooksScreen renders without an external Scaffold/Material',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // No Scaffold/Material ancestor: relies on BooksScreen being self-sufficient.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BooksScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add new book'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

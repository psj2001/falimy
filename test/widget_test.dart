import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/app.dart';

void main() {
  testWidgets('Splash shows Falimy brand', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FalimyApp(),
      ),
    );

    expect(find.text('Falimy'), findsOneWidget);

    // Splash waits ~1.2s then polls auth init with 50ms delays.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}

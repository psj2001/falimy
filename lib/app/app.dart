import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class FalimyApp extends ConsumerWidget {
  const FalimyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Falimy',
      debugShowCheckedModeBanner: false,
      theme: FalimyTheme.light(),
      routerConfig: router,
    );
  }
}

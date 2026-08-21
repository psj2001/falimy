import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../providers/auth_notifier.dart';
import '../../../onboarding/presentation/providers/onboarding_notifier.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Wait until the saved session is restored from the phone.
    for (var i = 0; i < 200; i++) {
      if (ref.read(authNotifierProvider).isInitialized) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    await ref.read(onboardingNotifierProvider.notifier).ensureLoaded();
    if (!mounted) return;

    final auth = ref.read(authNotifierProvider);
    final profile = ref.read(onboardingNotifierProvider);

    if (!auth.isAuthenticated) {
      context.go(AppRoutes.signIn);
    } else if (profile.onboardingComplete) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.basicInfo);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white, Color(0xFFF1F5F9)],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: FalimyTheme.seed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    size: 44,
                    color: FalimyTheme.seed,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Falimy', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 8),
                Text(
                  'Your family, connected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

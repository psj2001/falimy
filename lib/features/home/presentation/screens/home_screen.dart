import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/constants/app_routes.dart';
import 'package:falimy/features/home/presentation/screens/family_tree_tab.dart';
import 'package:falimy/features/home/presentation/screens/financial_tab.dart';
import 'package:falimy/features/home/presentation/screens/home_tab.dart';
import 'package:falimy/features/home/presentation/screens/profile_tab.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

/// Home shell with bottom circle nav:
/// Home | Family Tree | Profile | Financial
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _homeIndex = 0;
  static const _familyTreeIndex = 1;
  static const _profileIndex = 2;
  static const _financialIndex = 3;

  int _activeIndex = _homeIndex;

  void _openTab(int index) {
    setState(() => _activeIndex = index);
    if (index == _familyTreeIndex) {
      ref.read(onboardingNotifierProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _activeIndex,
        children: [
          HomeTab(
            onOpenFamilyTree: () => _openTab(_familyTreeIndex),
            onOpenProfile: () => _openTab(_profileIndex),
            onOpenFinancial: () => _openTab(_financialIndex),
            onOpenNotifications: () => context.push(AppRoutes.notifications),
            onOpenBudget: () => context.push(AppRoutes.budget),
          ),
          const FamilyTreeTab(),
          const ProfileTab(),
          const FinancialTab(),
        ],
      ),
      bottomNavigationBar: CircleNavBar(
        activeIndex: _activeIndex,
        onTap: _openTab,
        height: 70,
        circleWidth: 60,
        color: Colors.white,
        circleColor: FalimyTheme.seed,
        activeIcons: const [
          Icon(Icons.home_rounded, color: Colors.white),
          Icon(Icons.account_tree_rounded, color: Colors.white),
          Icon(Icons.person_rounded, color: Colors.white),
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
        ],
        inactiveIcons: const [
          _NavLabel('Home'),
          _NavLabel('Family'),
          _NavLabel('Profile'),
          _NavLabel('Financial'),
        ],
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
        shadowColor: FalimyTheme.seed.withValues(alpha: 0.25),
        circleShadowColor: FalimyTheme.seed.withValues(alpha: 0.35),
        elevation: 8,
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: FalimyTheme.muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

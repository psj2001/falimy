import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/constants/app_routes.dart';
import 'package:falimy/features/home/presentation/screens/family_tree_tab.dart';
import 'package:falimy/features/home/presentation/screens/financial_tab.dart';
import 'package:falimy/features/home/presentation/screens/home_tab.dart';
import 'package:falimy/features/home/presentation/screens/profile_tab.dart';
import 'package:falimy/features/home/presentation/widgets/pill_bottom_nav.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

/// Home shell with floating pill bottom nav:
/// Home | Tree | Money | Profile
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _homeIndex = 0;
  static const _familyTreeIndex = 1;
  static const _profileIndex = 3;

  static const _navItems = [
    PillNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    PillNavItem(
      icon: Icons.park_outlined,
      selectedIcon: Icons.park_rounded,
      label: 'Tree',
    ),
    PillNavItem(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      label: 'Money',
    ),
    PillNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  int _activeIndex = _homeIndex;

  void _openTab(int index) {
    setState(() => _activeIndex = index);
    if (index == _familyTreeIndex) {
      ref.read(onboardingNotifierProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    const navClearance = 72.0;
    final contentMedia = media.copyWith(
      padding: media.padding.copyWith(
        bottom: bottomInset + navClearance,
      ),
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: FalimyTheme.mistBlueSoft,
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: contentMedia,
              child: IndexedStack(
                index: _activeIndex,
                children: [
                  HomeTab(
                    onOpenProfile: () => _openTab(_profileIndex),
                    onOpenNotifications: () =>
                        context.push(AppRoutes.notifications),
                    onOpenBudget: () => context.push(AppRoutes.budget),
                  ),
                  FamilyTreeTab(
                    onOpenProfile: () => _openTab(_profileIndex),
                  ),
                  const FinancialTab(),
                  const ProfileTab(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? bottomInset : 16,
            child: Center(
              child: PillBottomNav(
                selectedIndex: _activeIndex,
                onDestinationSelected: _openTab,
                items: _navItems,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

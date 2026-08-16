import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/home/presentation/screens/family_tree_tab.dart';
import 'package:falimy/features/home/presentation/screens/financial_tab.dart';
import 'package:falimy/features/home/presentation/screens/profile_tab.dart';

/// Home shell with bottom circle nav:
/// Family Tree (left) | Profile (center) | Financial (right)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Default to Profile (center).
  int _activeIndex = 1;

  static const _tabs = [
    FamilyTreeTab(),
    ProfileTab(),
    FinancialTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _activeIndex,
        children: _tabs,
      ),
      bottomNavigationBar: CircleNavBar(
        activeIndex: _activeIndex,
        onTap: (index) => setState(() => _activeIndex = index),
        height: 70,
        circleWidth: 60,
        color: Colors.white,
        circleColor: FalimyTheme.seed,
        activeIcons: const [
          Icon(Icons.account_tree_rounded, color: Colors.white),
          Icon(Icons.person_rounded, color: Colors.white),
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
        ],
        inactiveIcons: const [
          Text(
            'Family Tree',
            style: TextStyle(
              color: FalimyTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Profile',
            style: TextStyle(
              color: FalimyTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Financial',
            style: TextStyle(
              color: FalimyTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:falimy/core/constants/app_routes.dart';
import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:falimy/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:falimy/features/auth/presentation/screens/splash_screen.dart';
import 'package:falimy/features/home/domain/family_member_detail.dart';
import 'package:falimy/features/home/presentation/screens/home_screen.dart';
import 'package:falimy/features/home/presentation/screens/member_detail_screen.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:falimy/features/onboarding/presentation/screens/basic_info_screen.dart';
import 'package:falimy/features/onboarding/presentation/screens/children_count_screen.dart';
import 'package:falimy/features/onboarding/presentation/screens/children_details_screen.dart';
import 'package:falimy/features/onboarding/presentation/screens/children_question_screen.dart';
import 'package:falimy/features/onboarding/presentation/screens/married_question_screen.dart';
import 'package:falimy/features/onboarding/presentation/screens/parents_siblings_screen.dart';
import 'package:falimy/features/onboarding/presentation/screens/spouse_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerRefreshProvider = Provider<GoRouterRefresh>((ref) {
  final refresh = GoRouterRefresh();
  ref.listen(authNotifierProvider, (_, _) => refresh.refresh());
  ref.listen(onboardingNotifierProvider, (_, _) => refresh.refresh());
  return refresh;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final profile = ref.read(onboardingNotifierProvider);
      final loc = state.matchedLocation;

      final isAuthRoute =
          loc == AppRoutes.signIn || loc == AppRoutes.signUp || loc == AppRoutes.splash;
      final isOnboarding = loc.startsWith('/onboarding');

      if (loc == AppRoutes.splash) return null;

      if (!auth.isAuthenticated) {
        return isAuthRoute ? null : AppRoutes.signIn;
      }

      if (auth.isAuthenticated &&
          (loc == AppRoutes.signIn || loc == AppRoutes.signUp)) {
        return profile.onboardingComplete
            ? AppRoutes.home
            : AppRoutes.basicInfo;
      }

      if (profile.onboardingComplete && isOnboarding) {
        return AppRoutes.home;
      }

      if (!profile.onboardingComplete && loc == AppRoutes.home) {
        return AppRoutes.basicInfo;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.basicInfo,
        builder: (context, state) => const BasicInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.parents,
        builder: (context, state) => const ParentsSiblingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.married,
        builder: (context, state) => const MarriedQuestionScreen(),
      ),
      GoRoute(
        path: AppRoutes.spouse,
        builder: (context, state) => const SpouseScreen(),
      ),
      GoRoute(
        path: AppRoutes.childrenQuestion,
        builder: (context, state) => const ChildrenQuestionScreen(),
      ),
      GoRoute(
        path: AppRoutes.childrenCount,
        builder: (context, state) => const ChildrenCountScreen(),
      ),
      GoRoute(
        path: AppRoutes.childrenDetails,
        builder: (context, state) {
          final count = state.extra as int? ?? 1;
          return ChildrenDetailsScreen(count: count);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberDetail,
        builder: (context, state) {
          final member = state.extra as FamilyMemberDetail?;
          if (member == null) {
            return const Scaffold(
              body: Center(child: Text('Member not found')),
            );
          }
          return MemberDetailScreen(member: member);
        },
      ),
    ],
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/constants/app_routes.dart';
import 'package:falimy/features/home/presentation/providers/family_search_notifier.dart';
import 'package:falimy/features/home/presentation/widgets/family_search_field.dart';
import 'package:falimy/features/home/presentation/widgets/family_search_results.dart';
import 'package:falimy/features/home/presentation/widgets/home_greeting_header.dart';
import 'package:falimy/features/notifications/presentation/providers/notification_notifier.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({
    super.key,
    required this.isActive,
    this.onOpenProfile,
  });

  final bool isActive;
  final VoidCallback? onOpenProfile;

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
  }

  @override
  void didUpdateWidget(SearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
    if (!widget.isActive && oldWidget.isActive) {
      _searchFocus.unfocus();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(familySearchNotifierProvider.notifier).clear();
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(onboardingNotifierProvider);
    final notifications = ref.watch(notificationNotifierProvider);
    final search = ref.watch(familySearchNotifierProvider);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: FalimyTheme.screenGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                child: HomeGreetingHeader(
                  profile: profile,
                  unreadCount: notifications.unreadCount,
                  onTapAvatar: widget.onOpenProfile,
                  onTapNotifications: () =>
                      context.push(AppRoutes.notifications),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Search',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: FalimyTheme.ink,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FamilySearchField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: ref
                      .read(familySearchNotifierProvider.notifier)
                      .onQueryChanged,
                  onClear: _clearSearch,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  children: [
                    FamilySearchResults(state: search),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

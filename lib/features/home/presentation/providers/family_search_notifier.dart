import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';
import 'package:falimy/features/home/data/api_family_search_repository.dart';
import 'package:falimy/features/home/domain/family_search_result.dart';
import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class FamilySearchState extends Equatable {
  const FamilySearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  final String query;
  final List<FamilySearchResult> results;
  final bool isLoading;
  final String? error;

  bool get isActive => query.trim().isNotEmpty;

  FamilySearchState copyWith({
    String? query,
    List<FamilySearchResult>? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FamilySearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [query, results, isLoading, error];
}

final familySearchRepositoryProvider = Provider<ApiFamilySearchRepository>((
  ref,
) {
  return ApiFamilySearchRepository(apiClient: ref.watch(apiClientProvider));
});

final familySearchNotifierProvider =
    NotifierProvider<FamilySearchNotifier, FamilySearchState>(
      FamilySearchNotifier.new,
    );

class FamilySearchNotifier extends Notifier<FamilySearchState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  FamilySearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const FamilySearchState();
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _requestId++;
      state = const FamilySearchState();
      return;
    }

    state = state.copyWith(
      query: trimmed,
      isLoading: trimmed.length >= 2,
      clearError: true,
    );
    _debounce = Timer(const Duration(milliseconds: 320), () {
      unawaited(_search(trimmed));
    });
  }

  void clear() {
    _debounce?.cancel();
    _requestId++;
    state = const FamilySearchState();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      state = state.copyWith(query: query, results: const [], isLoading: false);
      return;
    }

    final id = ++_requestId;
    state = state.copyWith(query: query, isLoading: true, clearError: true);

    final local = _localMatch(query, ref.read(onboardingNotifierProvider));
    try {
      final remote = await ref.read(familySearchRepositoryProvider).search(query);
      if (id != _requestId) return;
      state = state.copyWith(
        results: _merge(local, remote),
        isLoading: false,
        clearError: true,
      );
    } catch (_) {
      if (id != _requestId) return;
      state = state.copyWith(
        results: local == null ? const [] : [local],
        isLoading: false,
        error: local == null ? 'Could not search families' : null,
      );
    }
  }

  FamilySearchResult? _localMatch(String query, FamilyProfile profile) {
    final familyName = profile.familyName?.trim() ?? '';
    if (familyName.isEmpty) return null;
    if (!familyName.toLowerCase().contains(query.toLowerCase())) return null;
    final result = FamilySearchResult.fromProfile(profile);
    if (result.members.isEmpty) return null;
    return result;
  }

  List<FamilySearchResult> _merge(
    FamilySearchResult? local,
    List<FamilySearchResult> remote,
  ) {
    if (local == null) return remote;
    final merged = <FamilySearchResult>[];
    var includedLocal = false;
    for (final family in remote) {
      if (family.familyName.toLowerCase() == local.familyName.toLowerCase()) {
        merged.add(local.merge(family));
        includedLocal = true;
      } else {
        merged.add(family);
      }
    }
    if (!includedLocal) {
      merged.insert(0, local);
    }
    return merged;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/features/family/family_service.dart';
import 'package:village_app/features/family/models.dart';

/// Family state exposed by the notifier.
class FamilyState {
  final FamilyInfo? family;
  final bool isLoading;
  final String? error;

  const FamilyState({
    this.family,
    this.isLoading = false,
    this.error,
  });

  FamilyState copyWith({
    FamilyInfo? family,
    bool? isLoading,
    String? error,
  }) {
    return FamilyState(
      family: family ?? this.family,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FamilyNotifier extends Notifier<FamilyState> {
  @override
  FamilyState build() => const FamilyState();

  FamilyService get _familyService => ref.read(familyServiceProvider);

  /// Load the current user's family.
  Future<void> loadFamily() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final family = await _familyService.getMyFamily();
      state = FamilyState(family: family, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load family: $e',
      );
    }
  }

  /// Update family settings.
  Future<void> updateFamily({
    String? name,
    String? currencyName,
    String? timezone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _familyService.updateFamily(
        name: name,
        currencyName: currencyName,
        timezone: timezone,
      );
      // Reload to get fresh data
      await loadFamily();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update family: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Join a family by invite code.
  Future<void> joinFamily(String inviteCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _familyService.joinFamily(inviteCode);
      await loadFamily();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join family: $e',
      );
    }
  }
}

final familyProvider = NotifierProvider<FamilyNotifier, FamilyState>(
  FamilyNotifier.new,
);

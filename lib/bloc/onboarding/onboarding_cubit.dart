import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/bloc/onboarding/onboarding_state.dart';
import 'package:hyper_local/screens/introduction_pages/model/onboarding_model.dart';
import 'package:hyper_local/screens/introduction_pages/repo/onboarding_repo.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final OnboardingRepository _repository;

  OnboardingCubit({OnboardingRepository? repository})
      : _repository = repository ?? OnboardingRepository(),
        super(OnboardingInitial());

  /// Helper to determine if the onboarding screen should be presented
  bool get shouldShowOnboarding {
    if (state is OnboardingDisabled) return false;
    if (state is OnboardingLoaded) {
      final loaded = state as OnboardingLoaded;
      return loaded.isEnabled && loaded.screens.isNotEmpty;
    }
    // If not loaded yet or in error, fallback onboarding is available
    return true;
  }

  /// Current active screens list, or fallback screens if none
  List<OnboardingScreenItem> get currentScreens {
    if (state is OnboardingLoaded) {
      return (state as OnboardingLoaded).screens;
    }
    if (state is OnboardingError) {
      return (state as OnboardingError).fallbackScreens;
    }
    final cached = _repository.getCachedConfig();
    if (cached != null && cached.isEnabled && cached.screens.isNotEmpty) {
      return cached.screens;
    }
    return OnboardingRepository.getDefaultScreens();
  }

  /// Preload onboarding config during splash (non-blocking with timeout)
  Future<void> preloadOnboarding() async {
    // 1. Immediately inspect cache so state is available offline
    final cachedConfig = _repository.getCachedConfig();
    if (cachedConfig != null) {
      if (!cachedConfig.isEnabled) {
        emit(const OnboardingDisabled());
      } else if (cachedConfig.screens.isNotEmpty) {
        emit(OnboardingLoaded(
          isEnabled: true,
          screens: cachedConfig.screens,
          isFallback: false,
        ));
      }
    }

    // 2. Fetch fresh config from API with timeout
    try {
      final freshConfig = await _repository.fetchFromApi().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          log('[Onboarding] Customer API fetch timed out on splash, continuing with cache/fallback');
          return null;
        },
      );

      if (freshConfig != null) {
        if (!freshConfig.isEnabled) {
          log('[Onboarding] Disabled by server (is_enabled: false).');
          await _repository.syncCache(freshConfig);
          emit(const OnboardingDisabled());
          return;
        }

        if (freshConfig.screens.isEmpty) {
          log('[Onboarding] Customer onboarding screens list is null/empty. Falling back to default onboarding screens.');
          emit(OnboardingLoaded(
            isEnabled: true,
            screens: OnboardingRepository.getDefaultScreens(),
            isFallback: true,
          ));
          return;
        }

        // Valid dynamic screens received
        await _repository.syncCache(freshConfig);
        emit(OnboardingLoaded(
          isEnabled: true,
          screens: freshConfig.screens,
          isFallback: false,
        ));
        return;
      }
    } catch (e) {
      log('[Onboarding] Customer onboarding API failed ($e) -> Falling back gracefully');
    }

    // If API failed or returned null and we still have no valid state:
    if (state is! OnboardingLoaded && state is! OnboardingDisabled) {
      if (cachedConfig != null &&
          cachedConfig.isEnabled &&
          cachedConfig.screens.isNotEmpty) {
        log('[Onboarding] Using cached customer onboarding screens');
        emit(OnboardingLoaded(
          isEnabled: true,
          screens: cachedConfig.screens,
          isFallback: false,
        ));
      } else {
        log('[Onboarding] Falling back to default customer onboarding screens');
        emit(OnboardingLoaded(
          isEnabled: true,
          screens: OnboardingRepository.getDefaultScreens(),
          isFallback: true,
        ));
      }
    }
  }
}

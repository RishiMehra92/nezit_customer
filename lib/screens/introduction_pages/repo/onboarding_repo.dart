import 'dart:developer';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/introduction_pages/model/onboarding_model.dart';

class OnboardingRepository {
  final BaseCacheManager _cacheManager;

  OnboardingRepository({BaseCacheManager? cacheManager})
      : _cacheManager = cacheManager ?? DefaultCacheManager();

  /// Default fallback screens matching existing customer hardcoded onboarding
  static List<OnboardingScreenItem> getDefaultScreens() {
    return [
      OnboardingScreenItem(
        id: -1,
        title: 'Fast & Reliable Delivery',
        subtitle:
            'Get your daily essentials delivered to your doorstep in minutes',
        media: 'assets/svg/intro-1.svg',
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -2,
        title: 'Wide Selection of Stores',
        subtitle:
            'Shop from your favorite local stores and supermarkets in one place',
        media: 'assets/svg/intro-2.svg',
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -3,
        title: 'Easy & Secure Payments',
        subtitle:
            'Multiple payment options with real-time tracking for peace of mind',
        media: 'assets/svg/intro-3.svg',
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
    ];
  }

  /// Get cached configuration from Global / Hive
  OnboardingConfig? getCachedConfig() {
    try {
      final cachedJson = Global.cachedOnboardingConfig;
      if (cachedJson != null) {
        return OnboardingConfig.fromJson(cachedJson);
      }
    } catch (e) {
      log('[Onboarding] Error reading cached customer onboarding config: $e');
    }
    return null;
  }

  /// Fetch onboarding configuration from remote API
  Future<OnboardingConfig?> fetchFromApi() async {
    log('[Onboarding] API request started for app=customer');
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.onboardingScreensApi,
        {'app': 'customer'},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final onboardingResponse = OnboardingResponse.fromJson(data);
        if (onboardingResponse.data != null) {
          log('[Onboarding] API succeeded. is_enabled: ${onboardingResponse.data!.isEnabled}, screens count: ${onboardingResponse.data!.screens.length}');
          return onboardingResponse.data;
        }
      }
      log('[Onboarding] API response did not contain expected data structure');
      return null;
    } catch (e) {
      log('[Onboarding] Customer API request failed: $e');
      rethrow;
    }
  }

  /// Compare incoming API config with cached config and perform smart cache invalidation & persistence
  Future<void> syncCache(OnboardingConfig newConfig) async {
    try {
      final oldConfig = getCachedConfig();
      if (oldConfig != null) {
        final newScreenMap = {for (var s in newConfig.screens) s.id: s};
        for (final oldScreen in oldConfig.screens) {
          final newScreen = newScreenMap[oldScreen.id];
          if (newScreen == null) {
            // Screen removed -> evict cached asset
            if (oldScreen.isNetworkMedia) {
              await _cacheManager.removeFile(oldScreen.media);
              log('[Onboarding] Evicted cached media for removed screen id ${oldScreen.id}');
            }
          } else if (newScreen.media != oldScreen.media) {
            // Media URL changed -> evict old cached asset
            if (oldScreen.isNetworkMedia) {
              await _cacheManager.removeFile(oldScreen.media);
              log('[Onboarding] Evicted old cached media for modified screen id ${oldScreen.id}');
            }
          }
        }
      }

      await Global.saveCachedOnboardingConfig(newConfig.toJson());
      log('[Onboarding] Customer cached configuration updated successfully.');

      // Warm up cache in background
      _warmupCache(newConfig.screens);
    } catch (e) {
      log('[Onboarding] Error during customer syncCache: $e');
    }
  }

  void _warmupCache(List<OnboardingScreenItem> screens) {
    for (final screen in screens) {
      if (screen.isNetworkMedia && !screen.isVideo && !screen.isTxt) {
        _cacheManager.downloadFile(screen.media).catchError((err) {
          log('[Onboarding] Pre-cache failed for ${screen.media}: $err');
          return null as dynamic;
        });
      }
      final bg = screen.design.background;
      if (bg.isImage && bg.image.isNotEmpty && (bg.image.startsWith('http://') || bg.image.startsWith('https://'))) {
        _cacheManager.downloadFile(bg.image).catchError((err) {
          log('[Onboarding] Pre-cache failed for background image ${bg.image}: $err');
          return null as dynamic;
        });
      }
      final overlay = screen.design.overlay;
      if (overlay != null && overlay.isImage && overlay.image.isNotEmpty && (overlay.image.startsWith('http://') || overlay.image.startsWith('https://'))) {
        _cacheManager.downloadFile(overlay.image).catchError((err) {
          log('[Onboarding] Pre-cache failed for overlay image ${overlay.image}: $err');
          return null as dynamic;
        });
      }
    }
  }
}

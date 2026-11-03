import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/device_sync_bloc/device_sync_bloc.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/bloc/onboarding/onboarding_cubit.dart';
import 'package:hyper_local/bloc/language_bloc/language_bloc.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../../bloc/user_details_bloc/user_details_bloc.dart';
import '../../bloc/user_details_bloc/user_details_state.dart';
import '../../config/global.dart';
import '../../config/helper.dart';
import '../../config/settings_data_instance.dart';
import '../../config/theme.dart';
import '../../services/location/location_service.dart';
import '../../model/user_location/user_location_model.dart';
import '../../utils/app_update/bloc/app_update_bloc.dart';
import '../../utils/app_update/bloc/app_update_event.dart';
import '../../utils/app_update/bloc/app_update_state.dart';
import '../../utils/app_update/model/update_config.dart';
import '../../utils/app_update/widgets/app_update_dialog.dart';
import '../home_page/bloc/category/category_bloc.dart';
import '../home_page/bloc/category/category_event.dart';
import '../home_page/bloc/sub_category/sub_category_bloc.dart';
import '../home_page/bloc/sub_category/sub_category_event.dart';
import '../../app/app_bootstrap.dart';
import '../../config/notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import '../../model/splash_model/splash_config_model.dart';
import '../../services/splash/splash_cache_service.dart';
import '../../services/splash/splash_repository.dart';
import '../../utils/widgets/dominant_colors.dart';
import '../../utils/widgets/custom_toast.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  bool _hasInitialized = false;
  bool _hasNavigated = false;
  bool _lastKnownConnectivity = false;
  bool _settingsRequested = false;
  bool _updateGateResolved = false;
  bool _updateDialogShowing = false;
  Timer? _safetyTimer;
  SplashItemModel? _activeSplash;
  DateTime? _splashStartTime;
  VideoPlayerController? _bgVideoController;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();
    _activeSplash = SplashCacheService().getActiveSplash();
    if (_activeSplash != null) {
      debugPrint('[SplashScreen] 🎨 Loaded active splash from cache: ${_activeSplash!.cacheKey}');
      debugPrint('[SplashScreen]    👉 Background : ${_activeSplash!.background.type} (image: ${_activeSplash!.background.imageUrl}, color: ${_activeSplash!.background.color})');
      debugPrint('[SplashScreen]    👉 Overlay    : enabled=${_activeSplash!.overlay.enabled}, type=${_activeSplash!.overlay.type}, url=${_activeSplash!.overlay.url}');
      debugPrint('[SplashScreen]    👉 Local Paths: bg=${_activeSplash!.localBgPath}, overlay=${_activeSplash!.localOverlayPath}');
    } else {
      debugPrint('[SplashScreen] 🎨 No cached active splash found. Showing fallback while fetching remote...');
    }
    _initVideoIfApplicable();
    WidgetsBinding.instance.addObserver(this);

    // 1. Kick off version check, onboarding preload, and splash sync immediately on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        if (!AppConstant.hasValidBaseUrl) {
          _safetyTimer?.cancel();
          await AppBootstrap.initHeavy();
          if (!mounted) return;
          ToastManager.show(
            context: context,
            message: 'user not found',
            type: ToastType.error,
          );
          return;
        }
        log('[SplashScreen] Firing CheckAppUpdate and preloadOnboarding');
        context.read<AppUpdateBloc>().add(CheckAppUpdate());
        context.read<OnboardingCubit>().preloadOnboarding();
        context.read<LanguageListBloc>().add(FetchLanguageList(locale: Global.currentLanguage));
        context.read<LanguageBloc>().add(const LoadLanguage());
        
        // 0-1 Mechanism: Fetch and sync assets purely in the background for the NEXT launch.
        // Whatever splash screen started on Frame 0 (even the fallback splash) remains locked
        // for this entire session. It will NEVER swap, switch, or morph mid-flight!
        SplashRepository().fetchAndSync();
      }
    });

    // 2. Safety timer: if update check takes > 4s, fail-open so user is never stuck
    if (AppConstant.hasValidBaseUrl) {
      _safetyTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !_updateGateResolved) {
          log('[SplashScreen] Safety timeout: resolving update gate');
          _resolveGate();
        }
      });
    }

    // 3. Run heavy init in background safely
    _runHeavyInit();
  }

  void _initVideoIfApplicable() {
    final bg = _activeSplash?.background;
    if (bg != null && bg.isVideo) {
      // 1. Priority A: Local file on disk (Instant Frame-0 initialization, zero network lag)
      final localPath = _activeSplash?.localBgPath;
      if (localPath != null && File(localPath).existsSync()) {
        debugPrint('⚡ [SplashScreen] Initializing video controller from local file: $localPath');
        _bgVideoController = VideoPlayerController.file(File(localPath))
          ..initialize().then((_) {
            if (mounted) {
              _bgVideoController?.setLooping(true);
              _bgVideoController?.setVolume(0);
              _bgVideoController?.play();
              setState(() {});
            }
          }).catchError((e) {
            log('[SplashScreen] Local video init error: $e');
          });
        return;
      }

      // 2. Priority B: Network URL fallback
      if (bg.videoUrl != null && bg.videoUrl!.isNotEmpty) {
        final uri = Uri.tryParse(bg.videoUrl!);
        if (uri != null) {
          debugPrint('🌐 [SplashScreen] Initializing video controller from network: ${bg.videoUrl}');
          _bgVideoController = VideoPlayerController.networkUrl(uri)
            ..initialize().then((_) {
              if (mounted) {
                _bgVideoController?.setLooping(true);
                _bgVideoController?.setVolume(0);
                _bgVideoController?.play();
                setState(() {});
              }
            }).catchError((e) {
              log('[SplashScreen] Video background init error: $e');
            });
        }
      }
    }
  }

  Future<void> _runHeavyInit() async {
    try {
      await AppBootstrap.initHeavy();
      log('[SplashScreen] AppBootstrap.initHeavy completed successfully');
    } catch (e) {
      log('[SplashScreen] Error during AppBootstrap.initHeavy: $e');
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _bgVideoController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Update gate ───────────────────────────────────────────────────────────

  void _resolveGate() {
    if (!AppConstant.hasValidBaseUrl) return;
    if (_updateGateResolved) return;
    _updateGateResolved = true;
    _startSettingsIfReady();
  }

  /// Called when a soft-update dialog is dismissed via "Do it later".
  void _onSoftUpdateLater() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _updateDialogShowing = false;
    _resolveGate();
  }

  // ── AppUpdate dialog ──────────────────────────────────────────────────────
  void _showUpdateDialog(UpdateConfig config, {required bool isForced}) {
    if (_updateDialogShowing || !mounted) return;
    _updateDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(
        config: config,
        isForced: isForced,
        onLater: _onSoftUpdateLater,
      ),
    );
  }

  // ── Settings & navigation gate ────────────────────────────────────────────
  void _requestSettingsFetch() {
    if (!AppConstant.hasValidBaseUrl || !mounted || _settingsRequested) return;
    _settingsRequested = true;
    context.read<SettingsBloc>().add(FetchSettingsData(context: context));
  }

  Future<void> _startSettingsIfReady() async {
    if (!AppConstant.hasValidBaseUrl) return;
    if (!_updateGateResolved) return;
    if (!_lastKnownConnectivity) {
      try {
        final result = await Connectivity().checkConnectivity();
        if (result.any((r) => r != ConnectivityResult.none)) {
          _lastKnownConnectivity = true;
        }
      } catch (_) {}
    }
    if (!_lastKnownConnectivity) return;
    _requestSettingsFetch();
  }

  // ── Location helpers ──────────────────────────────────────────────────────

  Future<void> _checkAndSetLocation() async {
    if (AppHelpers.isDemo) {
      // --- DEMO MODE PIPELINE ---
      // 1. Hive (stored location)
      if (LocationService.hasStoredLocation()) {
        log("[Demo Mode] Location initialized from Hive storage");
        return;
      }

      // 2. Demo Mode (hardcoded lat/long)
      final lat = AppHelpers.defaultLat;
      final lng = AppHelpers.defaultLng;
      if (lat.isNotEmpty && lng.isNotEmpty) {
        log("[Demo Mode] Location initialized from Demo hardcoded coordinates: $lat, $lng");
        await LocationService.storeLocationFromCoordinates(
          latitude: lat,
          longitude: lng,
        );
        return;
      }

      // 3. Default (backend web settings)
      String? backendLat, backendLng;
      final webSettings = SettingsData.instance.web;
      if (webSettings != null) {
        backendLat = webSettings.defaultLatitude;
        backendLng = webSettings.defaultLongitude;
      }
      if (backendLat != null && backendLng != null && backendLat.isNotEmpty && backendLng.isNotEmpty) {
        log("[Demo Mode] Location initialized from Backend Web Settings: $backendLat, $backendLng");
        await LocationService.storeLocationFromCoordinates(
          latitude: backendLat,
          longitude: backendLng,
        );
        return;
      }

      // 4. Current Location (GPS)
      log("[Demo Mode] Attempting device Current Location (GPS) at last");
      final userLoc = await _tryFetchDeviceLocation();
      if (userLoc != null) return;
    } else {
      // --- NORMAL MODE PIPELINE ---
      // 1. Current Location (GPS first)
      log("[Normal Mode] Attempting device Current Location (GPS) first");
      final userLoc = await _tryFetchDeviceLocation();
      if (userLoc != null) return;

      // 2. Hive (stored location)
      if (LocationService.hasStoredLocation()) {
        log("[Normal Mode] Location initialized from Hive storage");
        return;
      }

      // 3. Default (backend web settings)
      String? backendLat, backendLng;
      final webSettings = SettingsData.instance.web;
      if (webSettings != null) {
        backendLat = webSettings.defaultLatitude;
        backendLng = webSettings.defaultLongitude;
      }
      if (backendLat != null && backendLng != null && backendLat.isNotEmpty && backendLng.isNotEmpty) {
        log("[Normal Mode] Location initialized from Backend Web Settings: $backendLat, $backendLng");
        await LocationService.storeLocationFromCoordinates(
          latitude: backendLat,
          longitude: backendLng,
        );
        return;
      }
    }
  }

  Future<UserLocation?> _tryFetchDeviceLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      // 1. If already granted, fetch the location
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        return await LocationService.requestAndStoreLocationWithRetry();
      }
      
      // 2. If it hasn't been requested yet (denied), trigger the native OS dialog first
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          return await LocationService.requestAndStoreLocationWithRetry();
        }
      }

// 3. If denied or deniedForever, respect the user's choice and do nothing further.
    } catch (e) {
      log("Error fetching device GPS location: $e");
    }
    return null;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> navigate() async {
    if (!mounted || !AppConstant.hasValidBaseUrl) return;
    _dispatchInitialDataFetches();
    _syncDeviceIfLoggedIn();
    if (_hasNavigated) return;
    _hasNavigated = true;

    final minDisplaySecs = _activeSplash?.minDisplaySeconds ?? 2;
    final elapsedMs = DateTime.now().difference(_splashStartTime ?? DateTime.now()).inMilliseconds;
    final remainingMs = (minDisplaySecs * 1000) - elapsedMs;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }

    if (!mounted || !_lastKnownConnectivity) {
      _hasNavigated = false;
      return;
    }

    const bool isDemoMode = AppConstant.isDemoMode;
    final isFirstTime = isDemoMode || Global.isFirstTime;

    if (isFirstTime) {
      final onboardingCubit = context.read<OnboardingCubit>();
      if (onboardingCubit.shouldShowOnboarding) {
        log('[Onboarding] Showing customer onboarding (isDemoMode: $isDemoMode, isFirstTime: ${Global.isFirstTime})');
        GoRouter.of(context).go(AppRoutes.introSlider);
        if (!isDemoMode) {
          Global.setIsFirstTime(false);
        }
        return;
      } else {
        log('[Onboarding] Customer onboarding disabled (is_enabled: false) - skipping');
        if (!isDemoMode) {
          Global.setIsFirstTime(false);
        }
      }
    }

    GoRouter.of(context).go(AppRoutes.home);
  }

  void _handleConnectivityChanged(bool isConnected) {
    if (!AppConstant.hasValidBaseUrl) return;
    _lastKnownConnectivity = isConnected;

    if (!isConnected) {
      _hasNavigated = false;
      return;
    }

    if (!_hasInitialized) {
      _hasInitialized = true;
      if (_updateGateResolved) navigate();
      return;
    }

    if (!_hasNavigated && _updateGateResolved) navigate();
  }

  void _dispatchInitialDataFetches() {
    if (!mounted || !AppConstant.hasValidBaseUrl) return;
    context.read<CategoryBloc>().add(FetchCategory(context: context));
    context.read<SubCategoryBloc>().add(FetchSubCategory(slug: "", isForAllCategory: true));
    context.read<LanguageListBloc>().add(FetchLanguageList(locale: Global.currentLanguage));
    context.read<LanguageBloc>().add(const LoadLanguage());
    context.read<UserProfileBloc>().add(FetchUserProfile());
  }

  void _syncDeviceIfLoggedIn() {
    if (!mounted) return;
    if (Global.userData != null && Global.userData!.token.isNotEmpty) {
      context.read<DeviceSyncBloc>().add(SyncDevice(
            deviceType: Platform.isAndroid ? 'android' : 'ios',
            previousToken: Global.userData?.fcm ?? '',
            roleType: 'customer',
          ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUpdateBloc, AppUpdateState>(
      listener: (context, state) {
        if (state is AppUpdateConfigLoaded) {
          if (!state.isUpdateAvailable) {
            _resolveGate();
          } else {
            final isForced = state.isForced;
            _showUpdateDialog(state.config, isForced: isForced);
          }
        }
        if (state is AppUpdateFailed) {
          _resolveGate();
        }
      },
      child: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) async {
          if (state is MaintenanceModeEnabled) {
            GoRouter.of(context).go(
              AppRoutes.maintenancePage,
              extra: {'message': state.maintenanceModeMessage},
            );
            return;
          }
          if (state is SettingsLoaded) {
            if (!mounted) return;
            if (SettingsData.instance.system?.webMaintenanceMode == true) {
              GoRouter.of(context).go(AppRoutes.maintenancePage);
              return;
            }
            try {
              await _checkAndSetLocation();
            } catch (e) {
              log('[SplashScreen] Location setup error: $e');
            }
            if (!mounted) return;
            try {
              await NotificationService().initFirebaseMessaging();
            } catch (e) {
              log('[SplashScreen] Notification setup error: $e');
            }
            if (!mounted) return;
            _handleConnectivityChanged(true);
          }
          if (state is SettingsFailure) {
            log('[SplashScreen] Settings fetch failed: ${state.error} — proceeding to navigate');
            if (!mounted) return;
            _handleConnectivityChanged(true);
          }
        },
        child: BlocListener<UserDataBloc, UserDataState>(
          listener: (context, state) {},
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      notifyConnectivityStatusOnInit: true,
      onConnectivityChanged: (isConnected, _) {
        if (!mounted) return;
        _lastKnownConnectivity = isConnected;
        if (!_updateGateResolved) {
          if (isConnected) _startSettingsIfReady();
          return;
        }
        if (context.read<SettingsBloc>().state is SettingsLoaded) {
          _handleConnectivityChanged(isConnected);
        } else if (isConnected) {
          _startSettingsIfReady();
        }
      },
      body: _activeSplash != null && _activeSplash!.isValid
          ? _buildDynamicSplash(context, _activeSplash!)
          : _buildFallbackSplash(context),
    );
  }

  Widget _buildDynamicSplash(BuildContext context, SplashItemModel splash) {
    final bg = splash.background;
    final overlay = splash.overlay;
    final bgColor = getColorFromHex(bg.color) ?? AppTheme.primaryColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── LAYER 1: BASE BACKGROUND ──────────────────────────────────
        Positioned.fill(
          child: _buildBackgroundWidget(context, splash, bgColor),
        ),

        // ── LAYER 2: OVERLAY (Image or Lottie) ────────────────────────
        if (overlay.enabled && overlay.url != null && overlay.url!.trim().isNotEmpty)
          _buildOverlayWidget(context, overlay, splash.localOverlayPath),
      ],
    );
  }

  Widget _buildBackgroundWidget(
    BuildContext context,
    SplashItemModel splash,
    Color bgColor,
  ) {
    final bg = splash.background;

    // 1. Image Background
    if (bg.isImage) {
      // Priority A: Direct local file on disk (Instant Frame 0 render, 0ms latency, zero flash)
      if (splash.localBgPath != null && File(splash.localBgPath!).existsSync()) {
        debugPrint('⚡ [SplashScreen] Rendering background image directly from local disk: ${splash.localBgPath}');
        return Image.file(
          File(splash.localBgPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Error loading local background image: $error');
            return const SizedBox.expand();
          },
        );
      }

      // Priority B: CachedNetworkImage (Zero fade transition duration, neutral placeholder)
      if (bg.imageUrl != null && bg.imageUrl!.trim().isNotEmpty) {
        final cleanUrl = bg.imageUrl!.trim();
        return CachedNetworkImage(
          imageUrl: cleanUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) {
            debugPrint('⏳ [SplashScreen] Loading background image from cache/network: $url');
            return const SizedBox.expand();
          },
          imageBuilder: (context, imageProvider) {
            debugPrint('✅ [SplashScreen] Background image rendered successfully!');
            return Image(
              image: imageProvider,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
            );
          },
          errorWidget: (context, url, error) {
            debugPrint('❌ [SplashScreen] Background image failed to load: $url | Error: $error');
            return const SizedBox.expand();
          },
        );
      }
      return const SizedBox.expand();
    }

    // 2. Video Background
    if (bg.isVideo) {
      if (_bgVideoController != null && _bgVideoController!.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _bgVideoController!.value.size.width,
            height: _bgVideoController!.value.size.height,
            child: VideoPlayer(_bgVideoController!),
          ),
        );
      }
      // While video is initializing, show neutral widget — NEVER show color!
      return const SizedBox.expand();
    }

    // 3. Solid Color Background - EXCLUSIVELY rendered when backend explicitly says type is 'color'
    if (bg.isColor) {
      return Container(color: bgColor);
    }

    return const SizedBox.expand();
  }

  Widget _buildOverlayWidget(
    BuildContext context,
    SplashOverlayModel overlay,
    String? localOverlayPath,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rawWidth = screenWidth * (overlay.position.widthPercent / 100.0);
    final clampedWidth = rawWidth.clamp(80.0, 400.0);
    final cleanUrl = overlay.url!.trim();

    debugPrint('🖼️ [SplashScreen] Rendering overlay ${overlay.type} (url: $cleanUrl, width: $clampedWidth, x: ${overlay.position.xPercent}%, y: ${overlay.position.yPercent}%)');

    Widget overlayContent;

    if (overlay.isLottie) {
      if (localOverlayPath != null && File(localOverlayPath).existsSync()) {
        debugPrint('⚡ [SplashScreen] Rendering overlay Lottie directly from local disk: $localOverlayPath');
        overlayContent = Lottie.file(
          File(localOverlayPath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Overlay Local Lottie failed: $error');
            return const SizedBox();
          },
        );
      } else {
        overlayContent = Lottie.network(
          cleanUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Overlay Lottie failed to load: $cleanUrl | Error: $error');
            return const SizedBox();
          },
        );
      }
    } else {
      if (localOverlayPath != null && File(localOverlayPath).existsSync()) {
        debugPrint('⚡ [SplashScreen] Rendering overlay image directly from local disk: $localOverlayPath');
        overlayContent = Image.file(
          File(localOverlayPath),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Overlay Local Image failed: $error');
            return const SizedBox();
          },
        );
      } else {
        overlayContent = CachedNetworkImage(
          imageUrl: cleanUrl,
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) {
            debugPrint('⏳ [SplashScreen] Overlay image loading from cache/network: $url');
            return const SizedBox();
          },
          imageBuilder: (context, imageProvider) {
            debugPrint('✅ [SplashScreen] Overlay image rendered successfully: $cleanUrl');
            return Image(image: imageProvider, fit: BoxFit.contain, gaplessPlayback: true);
          },
          errorWidget: (context, url, error) {
            debugPrint('❌ [SplashScreen] Overlay Image failed to load: $url | Error: $error');
            return const SizedBox();
          },
        );
      }
    }

    return Align(
      alignment: FractionalOffset(
        (overlay.position.xPercent / 100.0).clamp(0.0, 1.0),
        (overlay.position.yPercent / 100.0).clamp(0.0, 1.0),
      ),
      child: SizedBox(
        width: clampedWidth,
        child: overlayContent,
      ),
    );
  }

  Widget _buildFallbackSplash(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            image: DecorationImage(
              image: AssetImage('assets/images/doodle.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: CustomImageContainer(
                imagePath: getAppLogoUrl(context),
                height: 180,
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local/model/user_data_model/user_data_model.dart';
import 'package:hyper_local/services/referral_attribution_service.dart';


class Global {
  static const String _boxName = 'UserDataBox';
  static const String _userKey = 'UserData';

  static UserDataModel? _userData;
  static bool shouldRedirectToHome = false;
  static final ValueNotifier<bool> homeNeedsReferralCheckNotifier = ValueNotifier<bool>(false);


  static final ValueNotifier<String?> tokenNotifier = ValueNotifier<String?>(null);

  /// Emits the latest [UserDataModel] whenever it is set or cleared.
  static final ValueNotifier<UserDataModel?> userDataNotifier = ValueNotifier<UserDataModel?>(null);

  static String? get token => tokenNotifier.value ?? _userData?.token;

  static set token(String? value) {
    tokenNotifier.value = value;
  }

  /// Initialize Hive data (user)
  static Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserDataModelAdapter());
    }
    Box box = await Hive.openBox<UserDataModel>(_boxName);
    _userData = box.get(_userKey);
    userDataNotifier.value = _userData;
    if (_userData != null && _userData!.token.isNotEmpty) {
      if (isUserFirstTimeLogin) {
        setIsUserFirstTimeLogin(false);
      }
    }
    debugPrint('✅ Initialized UserData: $_userData');
    debugPrint('✅ Initialized UserData: ${_userData?.email}');
  }

  // ---------------- App Preferences (stored separately) ----------------
  static const String _prefsBoxName = 'AppPrefsBox';
  static const String _isFirstTimeKey = 'isFirstTime';
  static const String _httpInspectorKey = 'httpInspectorEnabled';
  static const String _isUserFirstTimeLoginKey = 'isUserFirstTimeLogin';
  static const String _onboardingConfigKey = 'onboardingConfig';
  static const String _activeSplashConfigKey = 'activeSplashConfig';
  static const String _stagedSplashConfigKey = 'stagedSplashConfig';
  static bool? _isFirstTime;
  static bool? _isUserFirstTimeLogin;
  static Map<String, dynamic>? _onboardingConfig;
  static Map<String, dynamic>? _activeSplashConfig;
  static Map<String, dynamic>? _stagedSplashConfig;
  static String? _cachedLanguage;

  /// Controls the secret HTTP Inspector overlay visibility
  static final ValueNotifier<bool> httpInspectorEnabledNotifier = ValueNotifier<bool>(false);

  /// Stores whether it is the user's first time logging in (true: first time, false: already logged in)
  static final ValueNotifier<bool> isUserFirstTimeLoginNotifier = ValueNotifier<bool>(true);

  /// Toggle or set HTTP inspector overlay state
  static Future<bool> toggleHttpInspector([bool? enable]) async {
    final newValue = enable ?? !httpInspectorEnabledNotifier.value;
    httpInspectorEnabledNotifier.value = newValue;
    try {
      final Box prefsBox = await Hive.openBox(_prefsBoxName);
      await prefsBox.put(_httpInspectorKey, newValue);
    } catch (e) {
      debugPrint('❌ Failed to save httpInspector setting: $e');
    }
    return newValue;
  }

  /// Initialize preferences (should be called after Hive.initFlutter())
  static Future<void> initializePrefs() async {
    try {
      final Box prefsBox = await Hive.openBox(_prefsBoxName);
      _isFirstTime = prefsBox.get(_isFirstTimeKey, defaultValue: true) as bool? ?? true;
      final rawFirstTimeLogin = prefsBox.get(_isUserFirstTimeLoginKey, defaultValue: true);
      final bool firstTimeLoginBool;
      if (rawFirstTimeLogin is bool) {
        firstTimeLoginBool = rawFirstTimeLogin;
      } else if (rawFirstTimeLogin is String) {
        firstTimeLoginBool = rawFirstTimeLogin.toLowerCase() != 'false';
      } else {
        firstTimeLoginBool = true;
      }
      _isUserFirstTimeLogin = firstTimeLoginBool;
      isUserFirstTimeLoginNotifier.value = firstTimeLoginBool;

      final bool isInspectorEnabled = prefsBox.get(_httpInspectorKey, defaultValue: false) as bool? ?? false;
      httpInspectorEnabledNotifier.value = isInspectorEnabled;

      final String? savedLang = prefsBox.get(_languagePrefKey) as String?;
      _cachedLanguage = savedLang ?? (_userData?.language ?? 'en');
      if (savedLang == null && _cachedLanguage != null) {
        await prefsBox.put(_languagePrefKey, _cachedLanguage);
      }

      final rawOnboarding = prefsBox.get(_onboardingConfigKey);
      if (rawOnboarding is Map) {
        _onboardingConfig = Map<String, dynamic>.from(rawOnboarding);
      }

      final rawActiveSplash = prefsBox.get(_activeSplashConfigKey);
      if (rawActiveSplash is String) {
        try {
          _activeSplashConfig = jsonDecode(rawActiveSplash) as Map<String, dynamic>;
        } catch (_) {}
      } else if (rawActiveSplash is Map) {
        try {
          _activeSplashConfig = jsonDecode(jsonEncode(rawActiveSplash)) as Map<String, dynamic>;
        } catch (_) {}
      }

      final rawStagedSplash = prefsBox.get(_stagedSplashConfigKey);
      if (rawStagedSplash is String) {
        try {
          _stagedSplashConfig = jsonDecode(rawStagedSplash) as Map<String, dynamic>;
        } catch (_) {}
      } else if (rawStagedSplash is Map) {
        try {
          _stagedSplashConfig = jsonDecode(jsonEncode(rawStagedSplash)) as Map<String, dynamic>;
        } catch (_) {}
      }

      debugPrint('✅ Initialized prefs: isFirstTime=$_isFirstTime, isUserFirstTimeLogin=$firstTimeLoginBool, httpInspector=$isInspectorEnabled');
    } catch (e) {
      debugPrint('❌ Failed to initialize prefs: $e');
      _isFirstTime = true;
      _isUserFirstTimeLogin = true;
      _activeSplashConfig = null;
      _stagedSplashConfig = null;
      isUserFirstTimeLoginNotifier.value = true;
    }
  }

  /// Get whether this is the first time the user launched the app.
  static bool get isFirstTime => _isFirstTime ?? true;

  /// Set the first-time flag and persist it.
  static Future<void> setIsFirstTime(bool value) async {
    final Box prefsBox = await Hive.openBox(_prefsBoxName);
    await prefsBox.put(_isFirstTimeKey, value);
    _isFirstTime = value;
    debugPrint('🔖 Set isFirstTime = $value');
  }

  // ---------------- Onboarding Config ----------------
  static Map<String, dynamic>? get cachedOnboardingConfig => _onboardingConfig;

  static Future<void> saveCachedOnboardingConfig(Map<String, dynamic>? config) async {
    try {
      final Box prefsBox = await Hive.openBox(_prefsBoxName);
      if (config == null) {
        await prefsBox.delete(_onboardingConfigKey);
      } else {
        await prefsBox.put(_onboardingConfigKey, config);
      }
      _onboardingConfig = config;
    } catch (e) {
      debugPrint('❌ Failed to save onboarding config: $e');
    }
  }

  // ---------------- Splash Config ----------------
  static Map<String, dynamic>? get cachedActiveSplashConfig => _activeSplashConfig;

  static Future<void> saveCachedActiveSplashConfig(Map<String, dynamic>? config) async {
    try {
      final Box prefsBox = await Hive.openBox(_prefsBoxName);
      if (config == null) {
        await prefsBox.delete(_activeSplashConfigKey);
        _activeSplashConfig = null;
      } else {
        final jsonString = jsonEncode(config);
        await prefsBox.put(_activeSplashConfigKey, jsonString);
        _activeSplashConfig = jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('❌ Failed to save active splash config: $e');
    }
  }

  static Map<String, dynamic>? get cachedStagedSplashConfig => _stagedSplashConfig;

  static Future<void> saveCachedStagedSplashConfig(Map<String, dynamic>? config) async {
    try {
      final Box prefsBox = await Hive.openBox(_prefsBoxName);
      if (config == null) {
        await prefsBox.delete(_stagedSplashConfigKey);
        _stagedSplashConfig = null;
      } else {
        final jsonString = jsonEncode(config);
        await prefsBox.put(_stagedSplashConfigKey, jsonString);
        _stagedSplashConfig = jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('❌ Failed to save staged splash config: $e');
    }
  }

  /// Get whether this is the user's first time logging in (true: first time, false: already logged in).
  static bool get isUserFirstTimeLogin => _isUserFirstTimeLogin ?? isUserFirstTimeLoginNotifier.value;

  /// Set and persist the isUserFirstTimeLogin flag as a bool.
  /// This is stored in AppPrefsBox and is NOT cleared on logout.
  static Future<void> setIsUserFirstTimeLogin(bool value) async {
    try {
      final Box prefsBox = await Hive.openBox(_prefsBoxName);
      await prefsBox.put(_isUserFirstTimeLoginKey, value);
      _isUserFirstTimeLogin = value;
      isUserFirstTimeLoginNotifier.value = value;
      debugPrint('🔖 Set isUserFirstTimeLogin = $value');
    } catch (e) {
      debugPrint('❌ Failed to save isUserFirstTimeLogin: $e');
      _isUserFirstTimeLogin = value;
      isUserFirstTimeLoginNotifier.value = value;
    }
  }

  /// Save full user data
  static Future<void> setUserData(UserDataModel userData) async {
    Box box = await Hive.openBox<UserDataModel>(_boxName);
    await box.put(_userKey, userData);
    _userData = userData;
    token = userData.token;
    userDataNotifier.value = userData;
    await setIsUserFirstTimeLogin(false);
    debugPrint('✅ Set UserData: $userData');
  }

  /// Clear user data
  static Future<void> clearUserData() async {
    Box box = await Hive.openBox<UserDataModel>(_boxName);
    await box.delete(_userKey);
    _userData = null;
    token = null;
    userDataNotifier.value = null;

    try {
      final referralAttribution = GetIt.instance<ReferralAttributionService>();
      await referralAttribution.clearCode();
      await referralAttribution.setJustRegistered(false);
      await referralAttribution.setPromptShown(false);
    } catch (e) {
      debugPrint('Error resetting referral attribution on logout: $e');
    }

    debugPrint('🗑️ Cleared UserData');
  }

  /// Get current user (sync, cached)
  static UserDataModel? get userData => userDataNotifier.value ?? _userData;

  // /// Get token directly

  static const String _languagePrefKey = 'appLanguage';

  /// Get language (sync, cached)
  static String get currentLanguage => _cachedLanguage ?? _userData?.language ?? 'en';

  /// Update language inside UserDataModel and persist for guests too
  static Future<void> setLanguage(String languageCode) async {
    _cachedLanguage = languageCode;
    try {
      final Box prefsBox = Hive.isBoxOpen(_prefsBoxName)
          ? Hive.box(_prefsBoxName)
          : await Hive.openBox(_prefsBoxName);
      await prefsBox.put(_languagePrefKey, languageCode);
    } catch (e) {
      debugPrint('Failed to persist language pref: $e');
    }
    if (_userData != null) {
      final updatedUser = _userData!.copyWith(language: languageCode);
      await setUserData(updatedUser);
    }
    debugPrint('🌐 Updated Language: $languageCode');
  }

  /// Read persisted language for guests
  static Future<String> getPersistedLanguage() async {
    if (_cachedLanguage != null && _cachedLanguage!.isNotEmpty) {
      return _cachedLanguage!;
    }
    try {
      final Box prefsBox = Hive.isBoxOpen(_prefsBoxName)
          ? Hive.box(_prefsBoxName)
          : await Hive.openBox(_prefsBoxName);
      _cachedLanguage = (prefsBox.get(_languagePrefKey) as String?) ?? (_userData?.language ?? 'en');
      return _cachedLanguage!;
    } catch (_) {
      return _userData?.language ?? 'en';
    }
  }


  /// Supported languages
  static List<Map<String, String>> get supportedLanguages => [
        {'code': 'en', 'name': 'English', 'nativeName': 'English'},
        {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
        {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
        {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी'},
        {'code': 'gu', 'name': 'Gujarati', 'nativeName': 'ગુજરાતી'},
        {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
      ];

  /// Convert languageCode -> Locale
  static Locale getLocaleFromLanguage(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return const Locale('ar');
      case 'fr':
        return const Locale('fr');
      case 'hi':
        return const Locale('hi');
      case 'gu':
        return const Locale('gu');
      case 'te':
        return const Locale('te');
      default:
        return const Locale('en');
    }
  }

  /// Convert Locale -> languageCode
  static String getLanguageFromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return 'ar';
      case 'fr':
        return 'fr';
      case 'hi':
        return 'hi';
      case 'gu':
        return 'gu';
      case 'te':
        return 'te';
      default:
        return 'en';
    }
  }
}

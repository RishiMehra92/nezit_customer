import 'dart:ui';

class AppConstant {
  static String baseUrl = 'https://api.nezit.in/api/';
  /// Optional override when backend storage/CDN base URL differs from api.nezit.in/storage.
  static String storageBaseUrl = '';
  static String appName = 'Nezit Customer';
  static String packageName = 'com.nezit.customer';
  static String androidMapKey = 'AIzaSyDdR1VzwOBHmtHC2wNTWwDX1d28skxM2Xs';
  static String iosMapKey = 'AIzaSyDdR1VzwOBHmtHC2wNTWwDX1d28skxM2Xs';
  static String unRestrictedPlacesAPIKey = 'AIzaSyDdR1VzwOBHmtHC2wNTWwDX1d28skxM2Xs';
  static String serverClientId = '527902933409-29q1ddtevhmds07nkjaci5oretva1bgp.apps.googleusercontent.com';
  static String systemVersion = '3.3.0';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const String microSoftClarityId = "Your_Clarity_Id";
  static const bool isDemoMode = false;
  static const Color myprimaryColor = Color(0xFFFF6A1A);
  static final RegExp _baseUrlRegex = RegExp(r'^https://', caseSensitive: false);
  static bool get hasValidBaseUrl => _baseUrlRegex.hasMatch(baseUrl.trim());

}

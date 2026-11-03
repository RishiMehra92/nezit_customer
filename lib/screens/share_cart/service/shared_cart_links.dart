import '../../../config/constant.dart';
import '../../../config/settings_data_instance.dart';
import '../../../router/app_routes.dart';

String? sharedCartCodeFromUri(Uri uri) {
  final segments = uri.scheme == 'hyperlocal'
      ? [uri.host, ...uri.pathSegments]
      : uri.pathSegments;
  if (uri.scheme != 'hyperlocal') {
    final configuredHost =
        Uri.tryParse(SettingsData.instance.web?.customerWebUrl ?? '')?.host;
    final hosts = {
      'hyperlocalweb-dev.infinitietech.in',
      Uri.parse(AppConstant.baseUrl).host,
      if (configuredHost != null) configuredHost
    };
    if (uri.scheme != 'https' || !hosts.contains(uri.host)) return null;
  }
  if (segments.length != 3 ||
      segments[0] != 'cart' ||
      segments[1] != 'shared') {
    return null;
  }
  final code = segments[2];
  return RegExp(r'^[a-zA-Z0-9_-]{8,128}$').hasMatch(code) ? code : null;
}

bool canPresentSharedCart(String location) => !{
      AppRoutes.splashScreen,
      AppRoutes.introSlider,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.otpVerification,
      AppRoutes.forgotPassword,
      AppRoutes.mobileOtpLoginPage,
      AppRoutes.referralCodeEntry,
      AppRoutes.emailVerification,
      AppRoutes.mobileVerification,
      AppRoutes.locationPicker,
      AppRoutes.maintenancePage,
      AppRoutes.forceUpdateWaitingScreen,
      AppRoutes.noInternet,
      '/link',
    }.contains(location);

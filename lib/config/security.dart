import 'global.dart';

Map<String, String>? get headers {
  final String? token = Global.token;
  final String locale = Global.currentLanguage;
  if (token != null) {
    return {
      'Content-Type': 'application/json',
      'content-length': '0',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Locale': locale,
    };
  } else {
    return {
      'Content-Type': 'application/json',
      'content-length': '0',
      'Accept': 'application/json',
      'X-Locale': locale,
    };
  }
}
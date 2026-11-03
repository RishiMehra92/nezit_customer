import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class CartNativeShare {
  static const _channel = MethodChannel('hyperlocal/cart_share');

  static Future<void> share(
      {required String url,
      required String message,
      required String title,
      required String copyLabel,
      required String copiedLabel,
      required Rect origin}) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('shareCart', {
        'url': url,
        'message': message,
        'title': title,
        'copyLabel': copyLabel,
        'copiedLabel': copiedLabel,
      });
      return;
    }
    await SharePlus.instance.share(ShareParams(
      text: message,
      title: title,
      sharePositionOrigin: origin,
    ));
  }
}

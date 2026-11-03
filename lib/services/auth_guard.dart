import 'package:flutter/material.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';

import '../config/helper.dart';

class AuthGuard {
  /// Ensure the user is logged in.
  static Future<bool> ensureLoggedIn(BuildContext context) async {
    if (Global.userData != null && Global.userData!.token.isNotEmpty) {
      return true;
    }

    // Show toast message with authGuard type (includes Sign In button)
    ToastManager.show(
      context: context,
      type: ToastType.authGuard,
      fontSize: 14,
      message: AppHelpers.authMessage,
      fromAuthGuard: true,
    );

    return false;
  }
}
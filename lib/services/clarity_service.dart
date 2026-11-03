import 'dart:developer';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../config/constant.dart';

/// Service responsible for managing Microsoft Clarity session recording.
///
/// Initializes Clarity cleanly using the official recommended API [Clarity.initialize],
/// avoiding initialization on the Splash screen to prevent UI freezes, image assertion errors,
/// and isolate payload contention during cold boot.
class ClarityService {
  static bool _isInitialized = false;

  /// Initializes Microsoft Clarity on a stable, mounted screen.
  static void initialize(BuildContext context) {
    if (_isInitialized) return;
    if (AppConstant.microSoftClarityId.trim().isEmpty) return;

    _isInitialized = true;

    // Run after first frame has painted so initial layout/rendering is never blocked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final config = ClarityConfig(
          projectId: AppConstant.microSoftClarityId,
          // Use LogLevel.None to eliminate massive debug logs & isolate serialization lag
          logLevel: LogLevel.None,
        );
        final success = Clarity.initialize(context, config);
        if (kDebugMode) {
          log('[ClarityService] Initialized: $success');
        }
      } catch (e) {
        if (kDebugMode) {
          log('[ClarityService] Initialization failed: $e');
        }
      }
    });
  }
}

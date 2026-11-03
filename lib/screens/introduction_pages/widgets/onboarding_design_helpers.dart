import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hyper_local/screens/introduction_pages/model/onboarding_model.dart';

class HexColorHelper {
  /// Safely parse hex color strings (#RRGGBB, #AARRGGBB, #RGB, RRGGBB)
  static Color parse(String? hex, {Color fallback = Colors.transparent}) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    String cleanHex = hex.trim().replaceAll('#', '');
    if (cleanHex.length == 3) {
      // Expand 3-digit shorthand (e.g. #FFF -> #FFFFFF)
      cleanHex = cleanHex.split('').map((c) => '$c$c').join();
    }
    if (cleanHex.length == 6) {
      // Add default alpha channel
      cleanHex = 'FF$cleanHex';
    }
    if (cleanHex.length == 8) {
      final value = int.tryParse(cleanHex, radix: 16);
      if (value != null) {
        return Color(value);
      }
    }
    return fallback;
  }

  /// Estimates the luminance of the screen background to guarantee text/button legibility
  static double estimateBackgroundLuminance(OnboardingBackground bg, [OnboardingOverlay? overlay]) {
    double baseLuminance = 1.0;
    if (bg.isSolid) {
      baseLuminance = parse(bg.color, fallback: Colors.white).computeLuminance();
    } else if (bg.isGradient) {
      final start = parse(bg.gradientStartColor, fallback: const Color(0xFF0D6EFD)).computeLuminance();
      final end = parse(bg.gradientEndColor, fallback: const Color(0xFF20C997)).computeLuminance();
      baseLuminance = (start + end) / 2.0;
    } else {
      // Image background default
      baseLuminance = 0.5;
    }

    // Blend with overlay if enabled
    if (overlay != null && overlay.enabled) {
      final overlayLum = parse(overlay.color, fallback: Colors.black).computeLuminance();
      final op = overlay.opacity.clamp(0.0, 1.0);
      baseLuminance = (overlayLum * op) + (baseLuminance * (1.0 - op));
    }

    return baseLuminance;
  }

  /// Returns high contrast foreground color based on background luminance
  static Color getContrastColor(Color background, {Color darkText = const Color(0xFF1F2937), Color lightText = Colors.white}) {
    return background.computeLuminance() > 0.5 ? darkText : lightText;
  }
}

class GradientAngleHelper {
  /// Converts CSS gradient angle in degrees (where 0deg = to top, 90deg = to right,
  /// 180deg = to bottom, 270deg = to left) to Flutter's (begin, end) Alignment pair.
  static (Alignment begin, Alignment end) alignmentsForAngle(double angleInDegrees) {
    // Normalize angle to [0, 360)
    final double normalized = (angleInDegrees % 360 + 360) % 360;
    final double rad = normalized * math.pi / 180.0;

    // Flutter Alignment coordinate system:
    // x: -1 (left) to +1 (right)
    // y: -1 (top) to +1 (bottom) [inverted from standard Cartesian]
    // 0deg = to top -> dx = 0, dy = -1
    // 90deg = to right -> dx = 1, dy = 0
    // 180deg = to bottom -> dx = 0, dy = 1
    // 270deg = to left -> dx = -1, dy = 0
    double dx = math.sin(rad);
    double dy = -math.cos(rad);

    // Scale so gradient touches bounding box edges (like CSS)
    final double maxCoord = math.max(dx.abs(), dy.abs());
    if (maxCoord > 0) {
      dx /= maxCoord;
      dy /= maxCoord;
    }

    return (
      Alignment(-dx, -dy), // begin
      Alignment(dx, dy),   // end
    );
  }
}

class DesignMapper {
  static BoxFit mapBoxFit(String? fit) {
    switch (fit?.toLowerCase().trim()) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitwidth':
      case 'fit_width':
        return BoxFit.fitWidth;
      case 'fitheight':
      case 'fit_height':
        return BoxFit.fitHeight;
      case 'scaledown':
      case 'scale_down':
        return BoxFit.scaleDown;
      default:
        return BoxFit.cover;
    }
  }

  static Alignment mapAlignment(String? position) {
    switch (position?.toLowerCase().trim()) {
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      case 'topleft':
      case 'top_left':
        return Alignment.topLeft;
      case 'topright':
      case 'top_right':
        return Alignment.topRight;
      case 'bottomleft':
      case 'bottom_left':
        return Alignment.bottomLeft;
      case 'bottomright':
      case 'bottom_right':
        return Alignment.bottomRight;
      case 'center':
      default:
        return Alignment.center;
    }
  }

  static TextAlign mapTextAlign(String? alignment) {
    switch (alignment?.toLowerCase().trim()) {
      case 'left':
      case 'start':
        return TextAlign.left;
      case 'right':
      case 'end':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  static CrossAxisAlignment mapCrossAxisAlignment(String? alignment) {
    switch (alignment?.toLowerCase().trim()) {
      case 'left':
      case 'start':
        return CrossAxisAlignment.start;
      case 'right':
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
      default:
        return CrossAxisAlignment.center;
    }
  }
}

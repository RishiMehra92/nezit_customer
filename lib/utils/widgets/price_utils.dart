import 'package:flutter/widgets.dart';
import 'adaptive_price_text.dart';
import 'money_display.dart';

export 'adaptive_price_text.dart';

class PriceUtils {
  /// Calculate discount percentage
  static int calculateDiscountPercentage(double originalPrice, double salePrice) {
    if (originalPrice <= 0 || salePrice <= 0) return 0;
    if (salePrice >= originalPrice) return 0;

    final discount = ((originalPrice - salePrice) / originalPrice) * 100;
    return discount.round();
  }

  /// Format price with currency symbol or backend formatted string
  static String formatPrice(
    double price, {
    String? formatted,
    String? currencyCode,
    String? snapshotFormatted,
    String? legacySymbol,
  }) {
    return MoneyDisplay.format(
      price,
      formatted: formatted,
      snapshotFormatted: snapshotFormatted,
      currencyCode: currencyCode,
      legacySymbol: legacySymbol,
    );
  }

  /// Creates an adaptive price text widget that automatically reduces font size
  /// down to the comfortable viewing threshold before showing ellipsis.
  static Widget adaptivePriceText(
    String priceText, {
    Key? key,
    TextStyle? style,
    double? maxFontSize,
    double? minFontSize,
    double stepGranularity = 0.5,
    int maxLines = 1,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextAlign textAlign = TextAlign.start,
  }) {
    return AdaptivePriceText(
      priceText,
      key: key,
      style: style,
      maxFontSize: maxFontSize,
      minFontSize: minFontSize,
      stepGranularity: stepGranularity,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  /// Check if there's a valid discount
  static bool hasDiscount(double originalPrice, double salePrice) {
    return originalPrice > 0 && salePrice > 0 && salePrice < originalPrice;
  }

  /// Get discount amount
  static double getDiscountAmount(double originalPrice, double salePrice) {
    if (!hasDiscount(originalPrice, salePrice)) return 0.0;
    return originalPrice - salePrice;
  }
}


import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:hyper_local/utils/widgets/adaptive_shrink_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config/helper.dart';
import '../../../utils/widgets/price_utils.dart';

class PriceRowWidget extends StatelessWidget {
  final double originalPrice;
  final double? salePrice;
  final String? formattedDisplayPrice;
  final String? formattedOriginalPrice;
  final String? currencyCode;
  final double? fontSize;
  final double? originalFontSize;
  final double? discountFontSize;
  final FontWeight? fontWeight;
  final Color? priceColor;
  final Color? originalPriceColor;
  final Color? discountBackgroundColor;
  final Color? discountTextColor;

  const PriceRowWidget({
    super.key,
    required this.originalPrice,
    this.salePrice,
    this.formattedDisplayPrice,
    this.formattedOriginalPrice,
    this.currencyCode,
    this.fontSize,
    this.originalFontSize,
    this.discountFontSize,
    this.fontWeight,
    this.priceColor,
    this.originalPriceColor,
    this.discountBackgroundColor,
    this.discountTextColor,
  });

  @override
  Widget build(BuildContext context) {
    // ────────────────────────────────────────────────
    final displayPrice = salePrice != null && salePrice! > 0 ? salePrice! : originalPrice;

    // Only show discount UI if there's a meaningful discount
    final hasRealDiscount = salePrice != null &&
        salePrice! > 0 &&
        salePrice! < originalPrice &&
        (originalPrice - salePrice!).abs() > 0.01; // avoid floating-point noise

    final discountPercentage = hasRealDiscount
        ? PriceUtils.calculateDiscountPercentage(originalPrice, salePrice!)
        : 0;

    // ────────────────────────────────────────────────
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Main (effective) price ─ always shown
        Flexible(
          fit: FlexFit.loose,
          flex: hasRealDiscount ? 3 : 1,
          child: AdaptivePriceText(
            formattedDisplayPrice != null && formattedDisplayPrice!.isNotEmpty
                ? formattedDisplayPrice!
                : PriceUtils.formatPrice(displayPrice, currencyCode: currencyCode),
            style: TextStyle(
              fontSize: fontSize ?? (isTablet(context) ? 22 : 18),
              fontWeight: fontWeight ?? FontWeight.bold,
              color: priceColor ?? Theme.of(context).colorScheme.tertiary,
              letterSpacing: 0.2,
            ),
            minFontSize: isTablet(context) ? 14 : 12,
          ),
        ),

        // Only show crossed price + badge when there is a real discount
        if (hasRealDiscount) ...[
          const SizedBox(width: 8),

          // Original (struck-through) price
          Flexible(
            fit: FlexFit.loose,
            flex: 2,
            child: AdaptivePriceText(
              formattedOriginalPrice != null && formattedOriginalPrice!.isNotEmpty
                  ? formattedOriginalPrice!
                  : PriceUtils.formatPrice(originalPrice, currencyCode: currencyCode),
              style: TextStyle(
                fontSize: originalFontSize ?? (isTablet(context) ? 18 : 15),
                fontWeight: FontWeight.w400,
                color: originalPriceColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
                decorationColor: Theme.of(context).colorScheme.onSurfaceVariant,
                decorationThickness: 1.5,
              ),
              minFontSize: isTablet(context) ? 12 : 10,
            ),
          ),

          const SizedBox(width: 8),

          // Discount badge
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: discountBackgroundColor ?? Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: AdaptiveShrinkText(
                context.tr('percentOff', positionalArgs: [discountPercentage.toString()]),
                style: TextStyle(
                  fontSize: isTablet(context) ? 14 : 10.sp,
                  fontWeight: FontWeight.w500,
                  color: discountTextColor ?? Theme.of(context).colorScheme.error,
                  height: 1.1,
                ),
                maxLines: 1,
                minFontSize: isTablet(context) ? 11 : 8.5.sp,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
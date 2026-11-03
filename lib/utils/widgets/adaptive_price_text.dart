import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config/helper.dart';
import 'adaptive_shrink_text.dart';

/// A specialized adaptive text widget for displaying prices comfortably.
///
/// If the price string exceeds available width (common when currency codes like
/// "USD", "EUR", "AED" or longer formatted amounts are used instead of short 1-char symbols),
/// this widget dynamically scales down the font size until it reaches a
/// comfortable minimum viewing threshold ([minFontSize]).
///
/// Only if the text still exceeds available space *after* reaching the minimum
/// comfortable threshold will it truncate with an ellipsis ([TextOverflow.ellipsis]),
/// preventing premature ellipses like "USD..." and ensuring maximum readable information.
class AdaptivePriceText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? maxFontSize;
  final double? minFontSize;
  final double stepGranularity;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  const AdaptivePriceText(
    this.text, {
    super.key,
    this.style,
    this.maxFontSize,
    this.minFontSize,
    this.stepGranularity = 0.5,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final bool tablet = isTablet(context);
    final TextStyle effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final double baseFontSize = maxFontSize ?? effectiveStyle.fontSize ?? (tablet ? 22.0 : 16.sp);

    // Determine the minimum comfortable viewing threshold:
    // If caller specifies minFontSize, respect it.
    // Otherwise, scale based on base font size:
    // - Prominent/main prices (base >= 14): min comfortable is 11.sp (mobile) or 14 (tablet)
    // - Smaller secondary/strikethrough prices (base < 14): min comfortable is 9.sp (mobile) or 11 (tablet)
    final double comfortableMin = minFontSize ?? (
      baseFontSize < 14.0
          ? (tablet ? 11.0 : 9.0.sp)
          : (tablet ? 14.0 : 11.0.sp)
    );

    return AdaptiveShrinkText(
      text,
      style: effectiveStyle,
      maxFontSize: baseFontSize,
      minFontSize: comfortableMin,
      stepGranularity: stepGranularity,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

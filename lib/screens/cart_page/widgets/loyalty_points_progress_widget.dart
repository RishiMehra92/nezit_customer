import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/animation_helper.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';
class LoyaltyPointsProgressWidget extends StatelessWidget {
  final double itemsTotal;
  final double minOrderValueToRedeem;
  final int userPointsBalance;
  final double potentialPointsToEarn;
  final bool isLoyaltyPointsUsed;
  final VoidCallback? onTap;
  final String? currencyCode;

  const LoyaltyPointsProgressWidget({
    super.key,
    required this.itemsTotal,
    required this.minOrderValueToRedeem,
    required this.userPointsBalance,
    required this.potentialPointsToEarn,
    required this.isLoyaltyPointsUsed,
    this.onTap,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final currency = MoneyDisplay.resolveCurrencySymbol(currencyCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isFilled = itemsTotal >= minOrderValueToRedeem;
    final progressValue = minOrderValueToRedeem > 0 ? (itemsTotal / minOrderValueToRedeem).clamp(0.0, 1.0) : 0.0;

    final neededAmount = minOrderValueToRedeem - itemsTotal;

    final shouldHighlight = isFilled && !isLoyaltyPointsUsed;

    final Color containerColor = (isDark ? const Color(0xFF2E2200) : const Color(0xFFFFF8E1));

    final Color borderColor = const Color(0xFFFFD700).withValues(alpha: 0.3);

    Widget containerWidget = Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Center(
                  child: CustomImageContainer(
                    imagePath: 'assets/images/coin.png',
                    width: 24.w,
                    height: 24.w,
                    fit: BoxFit.cover,
                  ).FlipAnimate(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLoyaltyPointsUsed
                          ? (context.tr('discountApplied', fallback: "Discount Applied"))
                          : (context.tr('useCoinsForDiscount', fallback: "Use Coins for Discount")),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: isFilled ? const Color(0xFFFFA000) : const Color(0xFFEEAB18),
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isFilled
                          ? (isLoyaltyPointsUsed
                              ? (context.tr('tapToRemoveDiscount', fallback: "Tap to remove discount"))
                              : (context.tr('tapToApplyDiscount', fallback: "Tap to apply discount")))
                          : (context.tr('addProductsMoreToRedeem', positionalArgs: [currency, neededAmount.toStringAsFixed(0)], fallback: "Add products worth $currency${neededAmount.toStringAsFixed(0)} more")),
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: shouldHighlight ? FontWeight.bold : FontWeight.w500,
                        color: isLoyaltyPointsUsed
                            ? Colors.grey
                            : (isFilled
                                ? (isDark ? Colors.greenAccent : const Color(0xFF007A3E))
                                : (isDark ? Colors.amber[200] : Colors.amber[800])),
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: progressValue),
              builder: (context, animatedValue, child) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 5.h,
                  backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFFFFDE7),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFilled ? const Color(0xFFFFA000) : const Color(0xFFEEAB18),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (shouldHighlight) {
      containerWidget = containerWidget
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .slideY(
            begin: 0.0,
            end: -0.08,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuad,
          )
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.02, 1.02),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuad,
          );
    }

    return GestureDetector(
      onTap: isFilled ? onTap : null,
      child: containerWidget,
    );
  }
}

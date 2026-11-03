import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/cart_page/bloc/promo_code/promo_code_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/promo_code/promo_code_state.dart';
import 'package:hyper_local/utils/widgets/animated_button.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/animation_helper.dart';
import '../../../config/helper.dart';
import '../../../utils/widgets/custom_dotted_divider.dart';
import '../../../utils/widgets/money_display.dart';

class BillSummaryWidget extends StatelessWidget {
  final double itemsOriginalPrice;
  final double itemsDiscountedPrice;
  final double itemsSavings;
  final double deliveryChargeOriginal;
  final double handlingCharge;
  final double grandTotal;
  final double totalSavings;
  final double? perStoreDropOffFees;
  final bool? isFromOrderDetail;
  final VoidCallback? downloadInvoice;
  final String? promoCode;
  final double? promoDiscount;
  final String? promoError;
  final VoidCallback? removeCoupon;
  final String? promoMode;
  final String? discountAmount;
  final bool? isRushDelivery;
  final double? walletBalanceUsed;
  final String? freeDeliverySubtext;

  final double? totalPayable;
  final double? riderTip;
  final String? paymentMethod;
  final double? potentialPointsToEarn;
  final double? codCharges;
  final double? loyaltyDiscount;

  const BillSummaryWidget({
    super.key,
    required this.itemsOriginalPrice,
    required this.itemsDiscountedPrice,
    required this.itemsSavings,
    required this.deliveryChargeOriginal,
    required this.handlingCharge,
    required this.grandTotal,
    required this.totalSavings,
    this.perStoreDropOffFees,
    this.isFromOrderDetail = false,
    this.downloadInvoice,
    this.promoCode,
    this.promoDiscount,
    this.promoError,
    this.removeCoupon,
    this.promoMode,
    this.discountAmount,
    this.isRushDelivery,
    this.totalPayable,
    this.walletBalanceUsed,
    this.freeDeliverySubtext,
    this.riderTip,
    this.paymentMethod,
    this.potentialPointsToEarn,
    this.loyaltyDiscount,
    this.codCharges,
    this.currencyCode,
  });

  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    final currency = MoneyDisplay.resolveCurrencySymbol(currencyCode);
    final perStoreDropOffFees = this.perStoreDropOffFees;
    final promoCode = this.promoCode;
    final promoDiscount = this.promoDiscount;
    final promoError = this.promoError;
    final promoMode = this.promoMode;
    final discountAmount = this.discountAmount;
    final totalPayable = this.totalPayable;
    final potentialPointsToEarn = this.potentialPointsToEarn;
    final loyaltyDiscount = this.loyaltyDiscount ?? 0.0;
    final codCharges = this.codCharges;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final billCard = Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.mainDarkContainerBgColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 12.0.w, right: 12.0.w, top: 12.h, bottom: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('billDetails', fallback: 'Bill details'),
              style: TextStyle(
                fontSize: isTablet(context) ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 20),

            // Items total row
            _buildItemRow(
              context: context,
              icon: Icons.receipt_long,
              label: context.tr('itemsTotal', fallback: 'Items total'),
              originalPrice: itemsOriginalPrice >= 0 ? '$currency${itemsOriginalPrice.toStringAsFixed(2)}' : null,
              finalPrice: '$currency${itemsDiscountedPrice.toStringAsFixed(2)}',
              hasDiscount: itemsOriginalPrice >= 0 ? false : true,
            ),
            const SizedBox(height: 16),

            if (loyaltyDiscount > 0) ...[
              _buildItemRow(
                context: context,
                icon: Icons.toll,
                label: 'Coins Discount',
                finalPrice: '-$currency${loyaltyDiscount.toStringAsFixed(2)}',
                finalPriceColor: Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            // Delivery charge row
            _buildItemRow(
              context: context,
              icon: Icons.delivery_dining,
              label: context.tr('deliveryCharge', fallback: 'Delivery charge'),
              additionalInfo: freeDeliverySubtext,
              additionalInfoColor: AppTheme.primaryColor,
              originalPrice: deliveryChargeOriginal.toStringAsFixed(2),
              finalPrice: deliveryChargeOriginal <= 0
                  ? (context.tr('free', fallback: 'FREE'))
                  : '$currency${deliveryChargeOriginal.toStringAsFixed(2)}',
              finalPriceColor: deliveryChargeOriginal <= 0 ? Colors.green : null,
            ),
            const SizedBox(height: 16),

            // Rush Delivery Indicator
            if (isRushDelivery == true) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                      AppTheme.primaryColor.withValues(alpha: 0.05),
                      AppTheme.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('rushDeliveryActive', fallback: 'Rush Delivery Active'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.tr('on', fallback: 'ON'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (perStoreDropOffFees != null)
              _buildItemRow(
                context: context,
                icon: Icons.shopping_bag,
                label: context.tr('perStoreDropOffFees', fallback: 'Per store drop off fees'),
                finalPrice: perStoreDropOffFees <= 0
                    ? (context.tr('free', fallback: 'FREE'))
                    : '$currency${perStoreDropOffFees.toStringAsFixed(2)}',
              ),

            if (perStoreDropOffFees != null) const SizedBox(height: 16),

            // Handling charge row
            _buildItemRow(
              context: context,
              icon: Icons.shopping_bag,
              label: context.tr('handlingCharge', fallback: 'Handling charge'),
              finalPrice:
                  handlingCharge <= 0 ? (context.tr('free', fallback: 'FREE')) : '$currency${handlingCharge.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 16),

            if (paymentMethod?.toLowerCase().trim() == 'cod' && codCharges != null && codCharges > 0) ...[
              _buildItemRow(
                context: context,
                icon: Icons.payments_outlined,
                label: context.tr('cashOnDeliveryFee', fallback: 'Cash on Delivery Fee'),
                finalPrice: '$currency${codCharges.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
            ],

            if (riderTip != null && riderTip! > 0) ...[
              _buildItemRow(
                context: context,
                icon: Icons.monetization_on_outlined,
                label: context.tr('riderTip', fallback: 'Rider tip'),
                finalPrice: '$currency${riderTip!.toStringAsFixed(2)}',
              ),
              if (paymentMethod?.toLowerCase().trim() == 'cod') ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        context.tr('codTipPostOrderWarning', fallback: "Tip is excluded from COD total (Tip added post-order)."),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],

            if (walletBalanceUsed != null && walletBalanceUsed! > 0.01) ...[
              _buildItemRow(
                context: context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet Balance used',
                finalPrice: '-$currency${walletBalanceUsed!.toStringAsFixed(2)}',
                finalPriceColor: Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            /// For Cart Bill Promo Preview
            if (isFromOrderDetail == false) ...[
              // Enhanced Promo code section
              if (promoCode != null && promoCode.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getPromoGradientColors(promoMode),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPromoBorderColor(promoMode),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getPromoIconColor(promoMode),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getPromoIcon(promoMode),
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getPromoTitle(context, promoMode),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getPromoTextColor(promoMode),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      promoCode.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getPromoMainTextColor(promoMode),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (promoMode != null && discountAmount != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getPromoBadgeColor(promoMode),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getDiscountText(context, promoMode, discountAmount, currency),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '-$currency${(promoDiscount ?? 0).toInt()}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getPromoMainTextColor(promoMode),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<PromoCodeBloc, PromoCodeState>(
                  builder: (BuildContext context, PromoCodeState state) {
                    return AnimatedButton(
                      onTap: removeCoupon,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('removeCoupon', fallback: 'Remove Coupon'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Promo error message (if present)
              if (promoError != null && promoError.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          promoError,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

            /// For Order Detail Page Promo Preview
            if (isFromOrderDetail == true) ...[
              if (promoCode != null && promoCode.isNotEmpty && promoDiscount != null && promoDiscount >= 0.0) ...[
                _buildItemRow(
                  context: context,
                  icon: TablerIcons.discount_filled,
                  label: context.tr('promoDiscount', fallback: 'Promo Discount'),
                  finalPrice:
                      promoDiscount <= 0 ? (context.tr('free', fallback: 'FREE')) : '-$currency${promoDiscount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 16),
              ],
            ],

            const Divider(),
            const SizedBox(height: 8),
            // Grand total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('grandTotal', fallback: 'Grand total'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$currency${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dotted line separator

            // Total payable row (order detail page only)
            if (isFromOrderDetail == true && totalPayable != null) ...[
              buildDottedLine(context),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('totalPayable', fallback: 'Total payable'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$currency${totalPayable.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            /*if (isFromOrderDetail ?? false) ...[

              GestureDetector(
                onTap: downloadInvoice,
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    Container(
                      height: 30,
                      alignment: Alignment.center,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            TablerIcons.download,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('downloadInvoice', fallback: 'Download Invoice'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]*/
          ],
        ),
      ),
    );

    if (isFromOrderDetail == false && potentialPointsToEarn != null && potentialPointsToEarn > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2A10) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.green.shade800 : Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const CustomImageContainer(
                  imagePath: 'assets/images/coin.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                ).FlipAnimate(),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.tr(
                      'getCoinsOnOrder',
                      positionalArgs: [potentialPointsToEarn.toInt().toString()],
                      fallback: "Get ${potentialPointsToEarn.toInt()} Coins on this order",
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.green[200] : Colors.green[800],
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          billCard,
        ],
      );
    }

    return billCard;
  }

  String _getDiscountText(BuildContext context, String promoMode, String discountAmount, String currency) {
    final mode = promoMode.toLowerCase();
    if (mode == 'percentage' || mode == 'percent') {
      return context.tr('percentOff', positionalArgs: [discountAmount], fallback: '$discountAmount% OFF');
    } else if (mode == 'cashback') {
      return '$currency$discountAmount CASHBACK';
    } else if (mode == 'instant') {
      return '$currency$discountAmount INSTANT';
    } else {
      return '$currency$discountAmount OFF';
    }
  }

  List<Color> _getPromoGradientColors(String? promoMode) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return [
          Colors.purple.shade50,
          Colors.purple.shade100.withValues(alpha: 0.3),
        ];
      case 'instant':
        return [
          Colors.green.shade50,
          Colors.green.shade100.withValues(alpha: 0.3),
        ];
      default:
        return [
          Colors.blue.shade50,
          Colors.blue.shade100.withValues(alpha: 0.3),
        ];
    }
  }

  Color _getPromoBorderColor(String? promoMode) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return Colors.purple.shade300;
      case 'instant':
        return Colors.green.shade300;
      default:
        return Colors.blue.shade300;
    }
  }

  Color _getPromoIconColor(String? promoMode) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return Colors.purple.shade600;
      case 'instant':
        return Colors.green;
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _getPromoIcon(String? promoMode) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return Icons.account_balance_wallet;
      case 'instant':
        return Icons.check;
      default:
        return Icons.local_offer;
    }
  }

  String _getPromoTitle(BuildContext context, String? promoMode) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return context.tr('cashbackApplied', fallback: 'Cashback Applied');
      case 'instant':
        return context.tr('instantDiscountApplied', fallback: 'Instant Discount Applied');
      default:
        return context.tr('promoApplied', fallback: 'Promo Applied');
    }
  }

  Color _getPromoTextColor(String? promoMode) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return Colors.purple.shade700;
      case 'instant':
        return Colors.green.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  Color _getPromoMainTextColor(String? promoMode) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return Colors.purple.shade900;
      case 'instant':
        return Colors.green.shade900;
      default:
        return Colors.blue.shade900;
    }
  }

  Color _getPromoBadgeColor(String? promoMode) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return Colors.purple.shade700;
      case 'instant':
        return Colors.green.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  Widget _buildItemRow({
    IconData? icon,
    Widget? leadingWidget,
    required String label,
    required BuildContext context,
    String? additionalInfo,
    Color? additionalInfoColor,
    String? originalPrice,
    required String finalPrice,
    bool hasDiscount = false,
    Color? finalPriceColor,
  }) {
    return Row(
      children: [
        if (leadingWidget != null)
          leadingWidget
        else if (icon != null)
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              if (additionalInfo != null) ...[
                const SizedBox(height: 2),
                Text(
                  additionalInfo,
                  style: TextStyle(
                    fontSize: 11,
                    color: additionalInfoColor ?? AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            if (hasDiscount && originalPrice != null) ...[
              Text(
                originalPrice,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary(context),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              finalPrice,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: finalPriceColor ?? Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

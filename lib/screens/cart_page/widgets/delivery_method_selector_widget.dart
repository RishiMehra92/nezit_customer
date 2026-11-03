import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';
import '../../../config/helper.dart';
import '../../../utils/widgets/custom_toast.dart';

/// Combined Delivery Type + Delivery Speed — one card, old visual style.
///
/// - Pickup / Delivery shown as vertical column cards (same look as before)
/// - When Delivery is selected the Rush/Regular speed options expand inline
///   using the same visual style as the old DeliveryTypeWidget (bordered cards,
///   radio buttons, "Fastest Option" badge, charge label).
enum DeliveryType { rush, regular }

class DeliveryMethodSelectorWidget extends StatelessWidget {
  final String selectedMethod;
  final bool isPickupEnabled;
  final List<String>? blockedPickupStores;
  final ValueChanged<String> onMethodChanged;

  // Speed options — only relevant when selectedMethod == 'delivery'
  final DeliveryType? selectedDeliveryType;
  final ValueChanged<DeliveryType>? onDeliveryTypeChanged;
  final double rushDeliveryCharge;
  final double regularDeliveryCharge;
  final bool isRushDeliveryDisabled;
  final String? currencyCode;

  const DeliveryMethodSelectorWidget({
    super.key,
    required this.selectedMethod,
    this.isPickupEnabled = true,
    this.blockedPickupStores,
    required this.onMethodChanged,
    this.selectedDeliveryType,
    this.onDeliveryTypeChanged,
    this.rushDeliveryCharge = 0,
    this.regularDeliveryCharge = 0,
    this.isRushDeliveryDisabled = false,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
        final dark = isDarkMode(context);

    final isPickup = selectedMethod == 'pickup';
    final isDelivery = selectedMethod == 'delivery';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: dark ? AppTheme.mainDarkContainerBgColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: isTablet(context) ? 22 : 16.sp,
                color: dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                context.tr('deliveryType', fallback: 'Delivery Type'),
                style: TextStyle(
                  fontSize: isTablet(context) ? 22 : 15.sp,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // ── Pickup card ───────────────────────────────────────
          if (AppHelpers.pickupEnabled) ...[
            _buildMethodCard(
              context: context,
              isSelected: isPickup,
              label: context.tr('pickup', fallback: 'Pickup'),
              icon: isPickupEnabled ? Icons.storefront_outlined : Icons.lock_outline,
              isEnabled: isPickupEnabled,
              onTap: () => onMethodChanged('pickup'),
              onDisabledTap: () {
                final storesText = (blockedPickupStores != null && blockedPickupStores!.isNotEmpty)
                    ? blockedPickupStores!.join(', ')
                    : 'selected store';
                ToastManager.show(
                  context: context,
                  message: 'The following store(s) do not support Pickup: $storesText',
                  type: ToastType.error,
                );
              },
            ),
            SizedBox(height: 8.h),
          ],

          // ── Delivery card ─────────────────────────────────────
          _buildMethodCard(
            context: context,
            isSelected: isDelivery,
            label: context.tr('delivery', fallback: 'Delivery'),
            icon: Icons.delivery_dining_outlined,
            isEnabled: true,
            onTap: () => onMethodChanged('delivery'),
          ),

          // ── Inline speed options (calm, clear tone) ─
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSpeedSection(context),
            crossFadeState: isDelivery && onDeliveryTypeChanged != null
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 260),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  // ── Method card ───────────────────────────────────────────────────────────
  Widget _buildMethodCard({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required IconData icon,
    bool isEnabled = true,
    required VoidCallback onTap,
    VoidCallback? onDisabledTap,
  }) {
    const primaryColor = AppTheme.primaryColor;
    final dark = isDarkMode(context);
    final accentColor = dark ? const Color(0xFF64B5F6) : primaryColor;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: isEnabled ? onTap : onDisabledTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (dark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300),
              width: isSelected ? 1.5 : 1.0,
            ),
            color: isSelected
                ? (dark ? primaryColor.withValues(alpha: 0.16) : primaryColor.withValues(alpha: 0.08))
                : (dark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50),
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (dark ? primaryColor.withValues(alpha: 0.28) : primaryColor.withValues(alpha: 0.12))
                      : (dark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  size: isTablet(context) ? 26 : 21.sp,
                  color: isSelected
                      ? (dark ? Colors.white : primaryColor)
                      : (dark ? Colors.white70 : Colors.grey.shade700),
                ),
              ),
              SizedBox(width: 14.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet(context) ? 18 : 14.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (dark ? Colors.white : primaryColor)
                      : (dark ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade800),
                ),
              ),
              const Spacer(),
              RadioGroup<String>(
                groupValue: selectedMethod,
                onChanged: (String? value) {
                  if (!isEnabled) {
                    onDisabledTap?.call();
                    return;
                  }
                  if (value != null) {
                    onMethodChanged(value);
                  }
                },
                child: Radio<String>(
                  value: label.toLowerCase(),
                  side: BorderSide(
                    color: isSelected
                        ? accentColor
                        : (dark ? Colors.white38 : Colors.grey.shade400),
                    width: 1.5,
                  ),
                  activeColor: accentColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Speed section ────────────────────────────────────────────────────────
  Widget _buildSpeedSection(BuildContext context) {
    final dark = isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Divider(
            height: 1,
            color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            children: [
              Icon(
                Icons.speed_outlined,
                size: 15.sp,
                color: dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor,
              ),
              SizedBox(width: 6.w),
              Text(
                context.tr('deliverySpeed', fallback: 'Delivery Speed'),
                style: TextStyle(
                  color: dark ? Colors.white.withValues(alpha: 0.92) : Colors.grey.shade800,
                  fontSize: isTablet(context) ? 20 : 13.5.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        _buildSpeedOption(
          context: context,
          deliveryType: DeliveryType.rush,
          title: context.tr('rushDelivery', fallback: 'Rush Delivery'),
          subtitle: context.tr('prioritizedDeliveryForYourUrgentNeeds', fallback:
              'Prioritized delivery for your urgent needs.'),
          extraCharge: rushDeliveryCharge,
        ),
        SizedBox(height: 8.h),
        _buildSpeedOption(
          context: context,
          deliveryType: DeliveryType.regular,
          title: context.tr('regularDelivery', fallback: 'Regular Delivery'),
          subtitle: context.tr('standardDeliveryWithNoExtraCharges', fallback:
              'Standard delivery with no extra charges.'),
          extraCharge: regularDeliveryCharge,
        ),
      ],
    );
  }

  Widget _buildSpeedOption({
    required BuildContext context,
    required DeliveryType deliveryType,
    required String title,
    required String subtitle,
    double? extraCharge,
    }) {
    final dark = isDarkMode(context);
    const primaryColor = AppTheme.primaryColor;
    final accentColor = dark ? const Color(0xFF64B5F6) : primaryColor;
    final bool isEnabled = deliveryType == DeliveryType.regular || !isRushDeliveryDisabled;
    final bool isSelected = selectedDeliveryType == deliveryType;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: isEnabled
            ? () {
                if (deliveryType == DeliveryType.rush && isRushDeliveryDisabled) return;
                onDeliveryTypeChanged?.call(deliveryType);
              }
            : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (dark ? Colors.white.withValues(alpha: 0.10) : Colors.grey.shade300),
              width: isSelected ? 1.4 : 1.0,
            ),
            color: isSelected
                ? (dark ? primaryColor.withValues(alpha: 0.14) : primaryColor.withValues(alpha: 0.06))
                : (dark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEnabled)
                RadioGroup<DeliveryType>(
                  groupValue: selectedDeliveryType,
                  onChanged: (DeliveryType? value) {
                    if (value != null) onDeliveryTypeChanged?.call(value);
                  },
                  child: Radio<DeliveryType>(
                    value: deliveryType,
                    side: BorderSide(
                      color: isSelected
                          ? accentColor
                          : (dark ? Colors.white38 : Colors.grey.shade400),
                      width: 1.5,
                    ),
                    activeColor: accentColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                Radio<DeliveryType>(
                  value: deliveryType,
                  side: BorderSide(
                    color: isSelected
                        ? accentColor
                        : (dark ? Colors.white38 : Colors.grey.shade400),
                    width: 1.5,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isTablet(context) ? 17 : 13.sp,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected
                                    ? (dark ? Colors.white : primaryColor)
                                    : (dark ? Colors.white.withValues(alpha: 0.92) : Colors.black87),
                              ),
                            ),
                            if (deliveryType == DeliveryType.rush) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.22 : 0.12),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      color: dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                      size: 13.sp,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Fastest',
                                      style: TextStyle(
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (extraCharge != null && extraCharge > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: dark
                                  ? primaryColor.withValues(alpha: 0.22)
                                  : primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '+${MoneyDisplay.format(extraCharge, currencyCode: currencyCode)}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: dark ? const Color(0xFF90CAF9) : AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isTablet(context) ? 14 : 11.sp,
                        color: dark ? Colors.white.withValues(alpha: 0.65) : Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

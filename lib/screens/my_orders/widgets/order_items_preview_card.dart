import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_local/screens/my_orders/model/order_status.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_items_bottom_sheet.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_items_row.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';

const int _kVisibleCount = 5;
const int _kCapThreshold = 7;

class OrderItemsPreviewCard extends StatelessWidget {
  final List<OrderItems> items;
  final String? subtotal;
  final String? deliveryOtp;
  final String? deliveryOtpMode;
  final bool? deliveryOtpRequired;
  final bool? deliveryOtpVerified;
  final OrderStatus? orderStatus;
  final String? currencyCode;

  const OrderItemsPreviewCard({
    super.key,
    required this.items,
    this.subtotal,
    this.deliveryOtp,
    this.deliveryOtpMode,
    this.deliveryOtpRequired,
    this.deliveryOtpVerified,
    this.orderStatus,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showCap = items.length >= _kCapThreshold;
    final visible = showCap ? items.take(_kVisibleCount).toList() : items;
    final hidden = showCap ? items.length - _kVisibleCount : 0;

    final isOrderWise = deliveryOtpMode?.toLowerCase().trim() == 'order_wise';
    final cleanOtp = (deliveryOtp ?? '').trim();
    final isTerminal = orderStatus?.isTerminal == true ||
        orderStatus == OrderStatus.delivered ||
        orderStatus == OrderStatus.cancelled ||
        orderStatus == OrderStatus.failed ||
        orderStatus == OrderStatus.returned;

    final showOverallOtp = isOrderWise &&
        cleanOtp.isNotEmpty &&
        deliveryOtpVerified != true &&
        !isTerminal;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('itemsCount', positionalArgs: [items.length], fallback: '${items.length} items'),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (showOverallOtp) ...[
                    SizedBox(width: 8.w),
                    _Chip(
                      label: 'OTP: $cleanOtp',
                      bg: AppTheme.warningColor.withValues(alpha: 0.18),
                      fg: AppTheme.warningColor,
                    ),
                  ],
                ],
              ),
              if (subtotal != null && subtotal!.isNotEmpty)
                Text(
                  '${context.tr('subtotalLabel', fallback: 'Subtotal')} ${MoneyDisplay.format(subtotal, currencyCode: currencyCode)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          ...List.generate(visible.length, (i) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: scheme.outline,
                    width: 0.5,
                  ),
                ),
              ),
              child: OrderItemsRow(
                item: visible[i],
                showProductOtp: !isOrderWise,
                currencyCode: currencyCode,
                onTap: () => showOrderItemsBottomSheet(
                  context: context,
                  items: items,
                  deliveryOtpMode: deliveryOtpMode,
                  currencyCode: currencyCode,
                ),
              ),
            );
          }),
          if (showCap)
            _ViewMoreRow(
              hiddenCount: hidden,
              hiddenItems: items.skip(_kVisibleCount).toList(),
              onTap: () => showOrderItemsBottomSheet(
                context: context,
                items: items,
                deliveryOtpMode: deliveryOtpMode,
                currencyCode: currencyCode,
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _ViewMoreRow extends StatelessWidget {
  final int hiddenCount;
  final List<OrderItems> hiddenItems;
  final VoidCallback onTap;

  const _ViewMoreRow({
    required this.hiddenCount,
    required this.hiddenItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = hiddenItems.take(3).toList();
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(top: 10.h, bottom: 2.h),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.outline, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _StackedThumbs(items: preview),
                SizedBox(width: 8.w),
                Text(
                  context.tr('viewMoreItems', positionalArgs: [hiddenCount], fallback: 'View $hiddenCount more items'),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            Icon(
              TablerIcons.chevron_right,
              size: 14.sp,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _StackedThumbs extends StatelessWidget {
  final List<OrderItems> items;
  const _StackedThumbs({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty) return const SizedBox.shrink();

    final stack = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final url = items[i].product?.image ?? '';
      stack.add(Padding(
        padding: EdgeInsetsDirectional.only(start: i * 14.w),
        child: Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: scheme.surface, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: url.trim().isEmpty
              ? Icon(
                  TablerIcons.package,
                  size: 12.sp,
                  color: scheme.onSurfaceVariant,
                )
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(
                    TablerIcons.package,
                    size: 12.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
      ));
    }
    return SizedBox(
      width: 22.w + (stack.length - 1) * 14.w,
      height: 22.w,
      child: Stack(children: stack),
    );
  }
}

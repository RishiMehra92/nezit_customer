import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';

({String label, Color bg, Color fg})? _itemPillConfig(String? status, bool dark) {
  if (status == null || status.trim().isEmpty) return null;
  switch (status.toLowerCase().trim()) {
    case 'pending':
      return dark
          ? (label: 'Pending', bg: const Color(0xFF0C4A6E), fg: const Color(0xFFBAE6FD))
          : (label: 'Pending', bg: const Color(0xFFE0F2FE), fg: const Color(0xFF075985));
    case 'awaiting_store_response':
      return dark
          ? (label: 'Awaiting Store Response', bg: const Color(0xFF78350F), fg: const Color(0xFFFCD34D))
          : (label: 'Awaiting Store Response', bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E));
    case 'accepted':
      return dark
          ? (label: 'Accepted', bg: const Color(0xFF14532D), fg: const Color(0xFF86EFAC))
          : (label: 'Accepted', bg: const Color(0xFFDCFCE7), fg: const Color(0xFF166534));
    case 'rejected':
      return dark
          ? (label: 'Rejected', bg: const Color(0xFF881337), fg: const Color(0xFFFDA4AF))
          : (label: 'Rejected', bg: const Color(0xFFFFE4E6), fg: const Color(0xFF9F1239));
    case 'preparing':
      return dark
          ? (label: 'Preparing', bg: const Color(0xFF134E4A), fg: const Color(0xFF99F6E4))
          : (label: 'Preparing', bg: const Color(0xFFCCFBF1), fg: const Color(0xFF0F766E));
    case 'collected':
      return dark
          ? (label: 'Collected', bg: const Color(0xFF1E1B4B), fg: const Color(0xFFA5B4FC))
          : (label: 'Collected', bg: const Color(0xFFE0E7FF), fg: const Color(0xFF4338CA));
    case 'delivered':
      return dark
          ? (label: 'Delivered', bg: const Color(0xFF14532D), fg: const Color(0xFF86EFAC))
          : (label: 'Delivered', bg: const Color(0xFFDCFCE7), fg: const Color(0xFF166534));
    case 'returned':
      return dark
          ? (label: 'Returned', bg: const Color(0xFF4C1D95), fg: const Color(0xFFC4B5FD))
          : (label: 'Returned', bg: const Color(0xFFEDE9FE), fg: const Color(0xFF5B21B6));
    case 'refunded':
      return dark
          ? (label: 'Refunded', bg: const Color(0xFF4C1D95), fg: const Color(0xFFC4B5FD))
          : (label: 'Refunded', bg: const Color(0xFFEDE9FE), fg: const Color(0xFF5B21B6));
    case 'cancelled':
      return dark
          ? (label: 'Cancelled', bg: const Color(0xFF881337), fg: const Color(0xFFFDA4AF))
          : (label: 'Cancelled', bg: const Color(0xFFFFE4E6), fg: const Color(0xFF9F1239));
    case 'failed':
      return dark
          ? (label: 'Failed', bg: const Color(0xFF881337), fg: const Color(0xFFFDA4AF))
          : (label: 'Failed', bg: const Color(0xFFFFE4E6), fg: const Color(0xFF9F1239));
    default:
      return null;
  }
}

class OrderItemsRow extends StatelessWidget {
  final OrderItems item;
  final VoidCallback? onTap;
  final bool showProductOtp;
  final String? currencyCode;

  const OrderItemsRow({
    super.key,
    required this.item,
    this.onTap,
    this.showProductOtp = true,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
    final hasOtp = showProductOtp && ((item.product?.requiresOtp == 1) || (item.otp != null && item.otp.toString().trim().isNotEmpty));
    final hasAttachments = item.attachments.where((u) => u.trim().isNotEmpty).isNotEmpty;
    final status = getItemStatus(item, currencyCode: currencyCode);
    final hasStatus = status.color != Colors.transparent;
    final mrp = _mrpAmount();
    final subtotalAmount = _subtotalAmount();
    final showStrike = mrp > subtotalAmount && mrp > 0;
    final subline = _buildSubline(context);
    final hasComplexSubline = item.addons.isNotEmpty || hasOtp;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: hasStatus ? status.color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: hasStatus ? 8.w : 0,
          vertical: 9.h,
        ),
        child: Row(
          crossAxisAlignment: hasComplexSubline ? CrossAxisAlignment.start : CrossAxisAlignment.start,
          children: [
            _thumbnail(context),
            SizedBox(width: 10.w),
            Expanded(child: _buildTextColumn(context, hasOtp, hasAttachments, subline)),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showStrike)
                  Text(
                    MoneyDisplay.format(mrp, currencyCode: currencyCode),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      decoration: TextDecoration.lineThrough,
                      height: 1,
                    ),
                  ),
                Text(
                  MoneyDisplay.format(subtotalAmount, currencyCode: currencyCode),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(BuildContext context) {
    final imageUrl = item.product?.image ?? '';
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 56.w,
        height: 56.w,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: scheme.outline.withValues(alpha: isDark ? 0.15 : 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          TablerIcons.package,
          size: 20.sp,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      );
    }

    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.15 : 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.r),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 56.w,
          height: 56.w,
          fit: BoxFit.contain,
          placeholder: (_, __) => Container(
            color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5),
          ),
          errorWidget: (_, __, ___) => Icon(
            TablerIcons.package,
            size: 20.sp,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTextColumn(
    BuildContext context,
    bool hasOtp,
    bool hasAttachments,
    String subline,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final name = item.product?.name ?? item.title ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: SizedBox(
                width: 180.w,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            if (hasAttachments) ...[
              SizedBox(width: 6.w),
              Icon(
                TablerIcons.paperclip,
                size: 12.sp,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
        if (subline.isNotEmpty) ...[
          SizedBox(height: 2.h),
          SizedBox(
            width: 200.w,
            child: Text(
              subline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.sp,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 2.h),

          if (hasOtp &&
              item.status != 'delivered' &&
              item.status != 'returned' &&
              item.status != 'cancelled' &&
              item.status != 'refunded') ...[
            SizedBox(width: 6.w),
            _Chip(
              label: item.otp != null ? '${context.tr('otpChip', fallback: 'OTP')}: ${item.otp}' : context.tr('otpChip', fallback: 'OTP'),
              bg: AppTheme.warningColor.withValues(alpha: 0.18),
              fg: AppTheme.warningColor,
            ),
          ],
        ],
        if (item.returns.isNotEmpty &&
            item.returns.last.pickupOtp != null &&
            item.returns.last.pickupOtp!.isNotEmpty &&
            item.returns.last.pickupOtpVerified != true) ...[
          SizedBox(height: 4.h),
          _Chip(
            label: '${context.tr('returnOtp', fallback: 'Return OTP')}: ${item.returns.last.pickupOtp}',
            bg: AppTheme.warningColor.withValues(alpha: 0.12),
            fg: AppTheme.warningColor,
          ),
        ],
        () {
          final pill = _itemPillConfig(
            item.status,
            Theme.of(context).brightness == Brightness.dark,
          );
          if (pill == null) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: _Chip(label: pill.label, bg: pill.bg, fg: pill.fg),
          );
        }(),
        if (item.status == 'cancelled' && item.cancellationReason != null && item.cancellationReason!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              '${context.tr('reason', fallback: 'Reason')}: ${item.cancellationReason}',
              style: TextStyle(
                fontSize: 10.sp,
                color: scheme.error,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  String _buildSubline(BuildContext context) {
    final variant = item.variant?.title ?? item.variantTitle;
    final addons = item.addons.map((a) => a.item?.title ?? '').where((t) => t.trim().isNotEmpty).join(', ');
    final qty = item.quantity ?? 1;
    final qtyLabel = context.tr('qtyShort', positionalArgs: [qty], fallback: 'Qty $qty');

    final parts = <String>[];
    if (variant != null && variant.trim().isNotEmpty) parts.add(variant);
    if (addons.isNotEmpty) parts.add(addons);
    parts.add(qtyLabel);
    return parts.join(' · ');
  }

  double _subtotalAmount() {
    final raw = item.subtotal;
    if (raw == null) return 0;
    return double.tryParse(raw) ?? 0;
  }

  double _mrpAmount() {
    final priceRaw = item.price;
    final qty = item.quantity ?? 1;
    if (priceRaw == null) return 0;
    final unit = double.tryParse(priceRaw) ?? 0;
    return unit * qty;
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

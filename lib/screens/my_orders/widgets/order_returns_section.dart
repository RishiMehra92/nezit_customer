import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';
import 'package:intl/intl.dart';

class OrderReturnsSection extends StatelessWidget {
  final List<OrderItems> items;
  final String? currencyCode;

  const OrderReturnsSection({super.key, required this.items, this.currencyCode});

  @override
  Widget build(BuildContext context) {
    // Flatten all returns from all items
    final List<({OrderItems item, ItemReturn ret})> allReturns = [];
    for (final item in items) {
      for (final ret in item.returns) {
        allReturns.add((item: item, ret: ret));
      }
    }

    if (allReturns.isEmpty) return const SizedBox.shrink();

        final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.orange.withValues(alpha: dark ? 0.25 : 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: dark ? 0.06 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xFF2D1A00), const Color(0xFF1C1C2E)]
                    : [const Color(0xFFFFF7ED), const Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(7.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    TablerIcons.package_export,
                    size: 16.sp,
                    color: Colors.orange[700],
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('returnRequests'),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : const Color(0xFF1C1917),
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      context.tr('nReturnsInitiated', positionalArgs: [allReturns.length]),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: dark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Return Cards ────────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allReturns.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, i) {
              final entry = allReturns[i];
              return _ReturnCard(
                item: entry.item,
                ret: entry.ret,
                currencyCode: currencyCode,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Single return card ────────────────────────────────────────────────────────
class _ReturnCard extends StatelessWidget {
  final OrderItems item;
  final ItemReturn ret;
  final String? currencyCode;

  const _ReturnCard({
    required this.item,
    required this.ret,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final productName = item.product?.name ?? item.title ?? context.tr('product');
    final refundAmount = ret.refundAmount;
    final returnStatus = ret.returnStatus ?? ret.pickupStatus ?? '';
    final reason = ret.reason ?? '';
    final createdAt = _formatDate(ret.createdAt);
    final statusConfig = _returnStatusConfig(context, returnStatus, dark);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product row
          Row(
            children: [
              // Product image
              _ProductThumb(imageUrl: item.product?.image ?? '', dark: dark),
              SizedBox(width: 12.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (item.variantTitle != null &&
                        item.variantTitle!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        item.variantTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    // Status pill
                    _StatusPill(
                      label: statusConfig.label,
                      bg: statusConfig.bg,
                      fg: statusConfig.fg,
                      icon: statusConfig.icon,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Refund amount
              if (refundAmount != null && refundAmount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: dark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.20),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.tr('refundLabel'),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        MoneyDisplay.format(
                          refundAmount,
                          formattedAmount: ret.formattedRefundAmount,
                          currencyCode: currencyCode ?? ret.currencyCode,
                        ),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Details section
          SizedBox(height: 12.h),
          _DetailGrid(
            dark: dark,
            reason: reason,
            createdAt: createdAt,
            sellerApprovedAt: _formatDate(ret.sellerApprovedAt),
            pickedUpAt: _formatDate(ret.pickedUpAt),
            receivedAt: _formatDate(ret.receivedAt),
            refundProcessedAt: _formatDate(ret.refundProcessedAt),
            sellerComment: ret.sellerComment,
          ),
        ],
      ),
    );
  }

  String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return DateFormat('d MMM yyyy, h:mm a').format(dt.toLocal());
  }

  ({String label, Color bg, Color fg, IconData icon}) _returnStatusConfig(
      BuildContext context, String status, bool dark) {
    switch (status.toLowerCase().trim()) {
      case 'requested':
        return (
          label: context.tr('returnRequested'),
          bg: dark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
          fg: dark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
          icon: TablerIcons.clock,
        );
      case 'approved':
      case 'seller_approved':
        return (
          label: context.tr('approved'),
          bg: dark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
          fg: dark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
          icon: TablerIcons.circle_check,
        );
      case 'picked_up':
      case 'pickup_done':
        return (
          label: context.tr('pickedUp'),
          bg: dark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
          fg: dark ? const Color(0xFF99F6E4) : const Color(0xFF0F766E),
          icon: TablerIcons.truck,
        );
      case 'delivered_to_seller':
      case 'received_by_seller':
        return (
          label: context.tr('receivedBySeller'),
          bg: dark ? const Color(0xFF1E1B4B) : const Color(0xFFE0E7FF),
          fg: dark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
          icon: TablerIcons.building_store,
        );
      case 'refund_processed':
      case 'refunded':
        return (
          label: context.tr('refundProcessed'),
          bg: dark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
          fg: dark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
          icon: TablerIcons.currency_rupee,
        );
      case 'rejected':
      case 'store_rejected':
        return (
          label: context.tr('rejected'),
          bg: dark ? const Color(0xFF7F1D1D) : const Color(0xFFFFE4E6),
          fg: dark ? const Color(0xFFFCA5A5) : const Color(0xFF9F1239),
          icon: TablerIcons.x,
        );
      default:
        final label = status
            .split('_')
            .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
        return (
          label: label.isEmpty ? context.tr('inProgress') : label,
          bg: dark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
          fg: dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
          icon: TablerIcons.refresh,
        );
    }
  }
}

// ── Product thumbnail ─────────────────────────────────────────────────────────
class _ProductThumb extends StatelessWidget {
  final String imageUrl;
  final bool dark;
  const _ProductThumb({required this.imageUrl, required this.dark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: scheme.outline.withValues(alpha: dark ? 0.15 : 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.12 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: imageUrl.isNotEmpty
          ? CustomImageContainer(
              imagePath: imageUrl,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(11.r),
              errorWidget: Icon(
                TablerIcons.package,
                size: 20.sp,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            )
          : Icon(
              TablerIcons.package,
              size: 20.sp,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _StatusPill({required this.label, required this.bg, required this.fg, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: fg),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail grid ───────────────────────────────────────────────────────────────
class _DetailGrid extends StatelessWidget {
  final bool dark;
  final String reason;
  final String? createdAt;
  final String? sellerApprovedAt;
  final String? pickedUpAt;
  final String? receivedAt;
  final String? refundProcessedAt;
  final String? sellerComment;

  const _DetailGrid({
    required this.dark,
    required this.reason,
    this.createdAt,
    this.sellerApprovedAt,
    this.pickedUpAt,
    this.receivedAt,
    this.refundProcessedAt,
    this.sellerComment,
  });

  @override
  Widget build(BuildContext context) {
        final rows = <({IconData icon, String label, String value})>[];

    if (reason.isNotEmpty) {
      rows.add((
        icon: TablerIcons.message_circle_question,
        label: context.tr('reason'),
        value: reason,
      ));
    }
    if (createdAt != null) {
      rows.add((
        icon: TablerIcons.calendar_plus,
        label: context.tr('requestedOn'),
        value: createdAt!,
      ));
    }
    if (sellerApprovedAt != null) {
      rows.add((
        icon: TablerIcons.circle_check,
        label: context.tr('approvedOn'),
        value: sellerApprovedAt!,
      ));
    }
    if (pickedUpAt != null) {
      rows.add((
        icon: TablerIcons.truck,
        label: context.tr('pickedUp'),
        value: pickedUpAt!,
      ));
    }
    if (receivedAt != null) {
      rows.add((
        icon: TablerIcons.building_store,
        label: context.tr('receivedBySeller'),
        value: receivedAt!,
      ));
    }
    if (refundProcessedAt != null) {
      rows.add((
        icon: TablerIcons.currency_rupee,
        label: context.tr('refundProcessed'),
        value: refundProcessedAt!,
      ));
    }
    if (sellerComment != null && sellerComment!.isNotEmpty) {
      rows.add((
        icon: TablerIcons.message_2,
        label: context.tr('sellerNote'),
        value: sellerComment!,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1A2E) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: scheme.outline.withValues(alpha: dark ? 0.10 : 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: rows.map((row) {
          final isLast = row == rows.last;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(row.icon, size: 13.sp, color: AppTheme.primaryColor),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 110.w,
                    child: Text(
                      row.label,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                SizedBox(height: 8.h),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: scheme.outline.withValues(alpha: 0.08),
                ),
                SizedBox(height: 8.h),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}

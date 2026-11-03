import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_local/screens/my_orders/model/order_status.dart';
import 'package:intl/intl.dart';

class OrderStatusHeroCard extends StatelessWidget {
  final OrderDetailData order;
  final OrderStatus status;

  const OrderStatusHeroCard({
    super.key,
    required this.order,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final palette = status.palette(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    
    final headline = _buildHeadline(context);
    final secondary = _buildSecondary(context);
    final pill = _statusLabel(context);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.bg,
            Color.lerp(palette.bg, palette.accent, dark ? 0.18 : 0.12)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: palette.accent.withValues(alpha: dark ? 0.25 : 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: dark ? 0.12 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background icon
          Positioned(
            right: -8.w,
            bottom: -10.h,
            child: Icon(
              status.icon,
              size: 72.sp,
              color: palette.accent.withValues(alpha: dark ? 0.10 : 0.08),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Frosted-glass status pill
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: dark
                            ? palette.fg.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(
                          color: palette.fg.withValues(alpha: dark ? 0.20 : 0.12),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        pill,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: palette.fg,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (order.id != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: palette.accent.withValues(alpha: dark ? 0.15 : 0.10),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '#${order.id}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.accent,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: palette.fg,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  secondary,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w400,
                    color: palette.accent,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context) {
        switch (status) {
      case OrderStatus.placed:
        return context.tr('statusPlaced');
      case OrderStatus.partiallyAccepted:
        return context.tr('statusPartiallyAccepted');
      case OrderStatus.partiallyRejected:
        return context.tr('statusPartiallyRejected');
      case OrderStatus.confirmed:
        return context.tr('statusConfirmed');
      case OrderStatus.preparing:
        return context.tr('statusPreparing');
      case OrderStatus.readyForPickup:
        return context.tr('statusReadyForPickup');
      case OrderStatus.assigned:
        return context.tr('statusAssigned');
      case OrderStatus.shipped:
        return context.tr('statusShipped');
      case OrderStatus.outForDelivery:
        return context.tr('statusOutForDelivery');
      case OrderStatus.delivered:
        return context.tr('statusDelivered');
      case OrderStatus.cancelled:
        return context.tr('statusCancelled');
      case OrderStatus.returned:
        return context.tr('statusReturned');
      case OrderStatus.failed:
        return context.tr('statusFailed');
      case OrderStatus.needsReschedule:
        return context.tr('needsReschedule');
      case OrderStatus.unknown:
        return status.name.toUpperCase();
    }
  }

  String _buildHeadline(BuildContext context) {
    final eta = _formattedEta();
    final isLate = _isRunningLate();
    final isPickup = order.deliveryType?.toLowerCase() == 'pickup' ||
        order.fulfillmentType?.toLowerCase() == 'pickup';

    if (isLate && status.isInTransit && !isPickup) {
      return context.tr('heroRunningLate', fallback: 'Running a bit late');
    }

    switch (status) {
      case OrderStatus.placed:
        return context.tr('heroAwaitingConfirmation', fallback: 'Awaiting confirmation');
      case OrderStatus.partiallyAccepted:
        return context.tr('heroPartiallyAccepted', fallback: 'Some items unavailable');
      case OrderStatus.partiallyRejected:
        return context.tr('heroPartiallyRejected', fallback: 'Order partially rejected');
      case OrderStatus.confirmed:
        if (order.scheduledDate != null && order.scheduledDate!.isNotEmpty) {
          String displayScheduledDate = order.scheduledDate!;
          try {
            final parsedDate = DateTime.parse(order.scheduledDate!);
            displayScheduledDate = DateFormat('dd-MMM-yy').format(parsedDate);
          } catch (e) {
            // Ignore parsing error, fallback to raw value
          }
          final timeSlot = order.scheduledTimeSlotLabel;
          final hasTimeSlot = timeSlot != null && timeSlot.isNotEmpty;
          final dateWithTime = hasTimeSlot ? '$displayScheduledDate,\n$timeSlot' : displayScheduledDate;
          return context.tr('arrivingOn', positionalArgs: [dateWithTime], fallback: 'Arriving on $dateWithTime');
        }
        if (eta != null && !isPickup) {
          return context.tr('heroArrivingBy', positionalArgs: [eta], fallback: 'Arriving by $eta');
        }
        return context.tr('heroOrderConfirmed', fallback: 'Order confirmed');
      case OrderStatus.preparing:
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        if (isPickup) {
          return context.tr('heroStorePreparing', fallback: 'Store is preparing your order');
        }
        if (order.scheduledDate != null && order.scheduledDate!.isNotEmpty) {
          String displayScheduledDate = order.scheduledDate!;
          try {
            final parsedDate = DateTime.parse(order.scheduledDate!);
            displayScheduledDate = DateFormat('dd-MMM-yy').format(parsedDate);
          } catch (e) {
            // Ignore parsing error, fallback to raw value
          }
          final timeSlot = order.scheduledTimeSlotLabel;
          final hasTimeSlot = timeSlot != null && timeSlot.isNotEmpty;
          final dateWithTime = hasTimeSlot ? '$displayScheduledDate,\n$timeSlot' : displayScheduledDate;
          return context.tr('arrivingOn', positionalArgs: [dateWithTime], fallback: 'Arriving on $dateWithTime');
        }
        if (eta != null) {
          return context.tr('heroArrivingBy', positionalArgs: [eta], fallback: 'Arriving by $eta');
        }
        return context.tr('heroOnTheWay', fallback: 'On the way');
      case OrderStatus.readyForPickup:
        return context.tr('heroReadyForPickup', fallback: 'Your order is ready for pickup');
      case OrderStatus.assigned:
        return context.tr('heroAssigned', fallback: 'Delivery partner assigned');
      case OrderStatus.delivered:
        if (isPickup) {
          return context.tr('heroDelivered', fallback: 'Delivered');
        }
        return _wasDeliveredOnTime()
            ? context.tr('heroDeliveredOnTime', fallback: 'Delivered on time') : context.tr('heroDelivered', fallback: 'Delivered');
      case OrderStatus.cancelled:
        return context.tr('heroOrderCancelled', fallback: 'Order cancelled');
      case OrderStatus.returned:
        return context.tr('heroReturnedAndRefunded', fallback: 'Returned & refunded');
      case OrderStatus.failed:
        return context.tr('heroPaymentFailed', fallback: 'Payment failed');
      case OrderStatus.needsReschedule:
        return 'Reschedule Required';
      case OrderStatus.unknown:
        final rawStatus = order.status ?? '';
        if (rawStatus.isEmpty) return '';
        return rawStatus.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  String _buildSecondary(BuildContext context) {
    final placedTime = _formattedTime(order.createdAt);
    final eta = _formattedEta();
    final isPickup = order.deliveryType?.toLowerCase() == 'pickup' ||
        order.fulfillmentType?.toLowerCase() == 'pickup';

    switch (status) {
      case OrderStatus.placed:
        if (order.scheduledDate != null && order.scheduledDate!.isNotEmpty) {
          String displayScheduledDate = order.scheduledDate!;
          try {
            final parsedDate = DateTime.parse(order.scheduledDate!);
            displayScheduledDate = DateFormat('dd-MMM-yy').format(parsedDate);
          } catch (e) {
            // Ignore
          }
          final timeSlot = order.scheduledTimeSlotLabel;
          final hasTimeSlot = timeSlot != null && timeSlot.isNotEmpty;
          final dateWithTime = hasTimeSlot ? '$displayScheduledDate, $timeSlot' : displayScheduledDate;
          return context.tr('arrivingOn', positionalArgs: [dateWithTime], fallback: 'Arriving on $dateWithTime');
        }
        if (placedTime != null && eta != null && !isPickup) {
          return context.tr('secondaryPlacedAndEta', positionalArgs: [placedTime, eta], fallback:
              'Placed $placedTime · ETA $eta');
        }
        return context.tr('secondaryUsuallyAccepted', fallback: 'Usually accepted in 2 min');
      case OrderStatus.partiallyAccepted:
      case OrderStatus.partiallyRejected:
        final rejectedCount = order.items
            .where((i) => i.status == 'rejected' || i.status == 'cancelled')
            .length;
        final acceptedCount = order.items
            .where((i) => i.status == 'accepted')
            .length;
        final preparingCount = order.items
            .where((i) => i.status == 'preparing')
            .length;
        final pendingCount = order.items
            .where((i) =>
                i.status == 'pending' ||
                i.status == 'awaiting_store_response')
            .length;
        final parts = <String>[
          if (acceptedCount > 0)
            context.tr('itemCountAccepted', positionalArgs: [acceptedCount], fallback: '$acceptedCount accepted'),
          if (preparingCount > 0)
            context.tr('itemCountPreparing', positionalArgs: [preparingCount], fallback: '$preparingCount preparing'),
          if (rejectedCount > 0)
            context.tr('itemCountRejected', positionalArgs: [rejectedCount], fallback: '$rejectedCount rejected'),
          if (pendingCount > 0)
            context.tr('itemCountPending', positionalArgs: [pendingCount], fallback: '$pendingCount pending'),
        ];
        if (parts.isNotEmpty) return parts.join(' · ');
        return context.tr('secondaryPartialItems', positionalArgs: [order.items.length], fallback:
            '${order.items.length} items');
      case OrderStatus.confirmed:
        if (isPickup) {
          return 'We will notify you when it\'s ready for pickup';
        }
        return context.tr('secondaryOrderConfirmed', fallback: 'Store has accepted your order');
      case OrderStatus.preparing:
        if (isPickup) {
          return 'We will notify you when it\'s ready for pickup';
        }
        return context.tr('heroStorePreparing', fallback: 'Store is preparing your order');
      case OrderStatus.readyForPickup:
        return context.tr('secondaryReadyForPickup', fallback: 'Head to the store to collect your order');
      case OrderStatus.assigned:
        return context.tr('secondaryAssigned', fallback: 'A delivery partner is heading to pick up your order');
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return context.tr('heroOnTheWay', fallback: 'On the way');
      case OrderStatus.delivered:
        final date = _formattedDate(order.updatedAt ?? order.createdAt);
        final time = _formattedTime(order.updatedAt ?? order.createdAt);
        if (date != null && time != null) {
          return context.tr('secondaryDeliveredOn', positionalArgs: [date, time], fallback: '$date · $time');
        }
        return '';
      case OrderStatus.cancelled:
      case OrderStatus.failed:
        final date = _formattedDate(order.updatedAt ?? order.createdAt);
        if (date != null) {
          final isStoreCancel = order.status?.toLowerCase().contains('store') == true ||
                                order.status?.toLowerCase().contains('seller') == true ||
                                order.status?.toLowerCase().contains('reject') == true;
          if (isStoreCancel) {
            return context.tr('secondaryCancelledByStore', positionalArgs: [date], fallback: 'Cancelled by store · $date');
          }
          return context.tr('secondaryCancelledByYou', positionalArgs: [date], fallback: 'Cancelled · $date');
        }
        return '';
      case OrderStatus.returned:
        final date = _formattedDate(order.updatedAt ?? order.createdAt);
        final count = order.items.length;
        if (date != null) {
          return context.tr('secondaryItemsReturned', positionalArgs: [count, date], fallback:
              '$count items returned · $date');
        }
        return '';
      case OrderStatus.needsReschedule:
        String displayRescheduleDeadline = '';
        if (order.rescheduleDeadline != null && order.rescheduleDeadline!.isNotEmpty) {
          try {
            final parsedDate = DateTime.parse(order.rescheduleDeadline!);
            displayRescheduleDeadline = DateFormat('dd-MMM-yy, hh:mm a').format(parsedDate);
          } catch (e) {
            displayRescheduleDeadline = order.rescheduleDeadline!;
          }
        }
        return displayRescheduleDeadline.isNotEmpty
            ? 'Reschedule deadline: $displayRescheduleDeadline'
            : 'Reschedule is required';
      case OrderStatus.unknown:
        return '';
    }
  }

  bool _isRunningLate() {
    final eta = _etaDateTime();
    if (eta == null) return false;
    return DateTime.now().isAfter(eta);
  }

  bool _wasDeliveredOnTime() {
    final eta = _etaDateTime();
    final deliveredAt = order.updatedAt;
    if (eta == null || deliveredAt == null) return true;
    final delivered = DateTime.tryParse(deliveredAt);
    if (delivered == null) return true;
    return delivered
        .isBefore(eta.add(const Duration(minutes: 15)));
  }

  DateTime? _etaDateTime() {
    final created = order.createdAt;
    final minutes = order.estimatedDeliveryTime;
    if (created == null || minutes == null) return null;
    final base = DateTime.tryParse(created);
    if (base == null) return null;
    return base.add(Duration(minutes: minutes));
  }

  String? _formattedEta() {
    final eta = _etaDateTime();
    if (eta == null) return null;
    return DateFormat('h:mm a').format(eta.toLocal());
  }

  String? _formattedTime(String? raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  String? _formattedDate(String? raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return DateFormat('d MMM').format(dt.toLocal());
  }
}

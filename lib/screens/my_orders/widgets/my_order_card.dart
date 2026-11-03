import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/my_orders/model/my_order_model.dart';
import 'package:hyper_local/screens/my_orders/model/order_status.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

import '../../../config/helper.dart';

class OrderDeliveryCard extends StatelessWidget {
  final String status;
  final String dateTime;
  final List<OrderItem> orderItems;
  final VoidCallback onRateOrder;
  final VoidCallback onTrackOrder;
  final bool isDelivered;
  final bool isDeliveryBoyAssigned;
  final String orderSlug;
  final String orderId;
  final String? deliveryType;
  final String? scheduledDate;
  final String? scheduledTimeSlotLabel;
  final int? deliveryTimeSlotId;
  final String? rescheduleStatus;
  final String? rescheduleDeadline;
  final VoidCallback? onRescheduleTap;

  const OrderDeliveryCard({
    super.key,
    required this.status,
    required this.dateTime,
    required this.orderItems,
    required this.onRateOrder,
    required this.onTrackOrder,
    required this.isDelivered,
    required this.isDeliveryBoyAssigned,
    required this.orderSlug,
    required this.orderId,
    this.deliveryType,
    this.scheduledDate,
    this.scheduledTimeSlotLabel,
    this.deliveryTimeSlotId,
    this.rescheduleStatus,
    this.rescheduleDeadline,
    this.onRescheduleTap,
  });

  @override
  Widget build(BuildContext context) {
    final String deliveryTypeDisplay = _getDeliveryTypeDisplay(deliveryType);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final baseStatus = OrderStatusX.fromString(status);
    final orderStatus = baseStatus.isTerminal
        ? baseStatus
        : (rescheduleStatus == 'needs_reschedule' ? OrderStatus.needsReschedule : baseStatus);
    final palette = orderStatus.palette(context);

    String displayScheduledDate = scheduledDate ?? '';
    if (scheduledDate != null && scheduledDate!.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(scheduledDate!);
        displayScheduledDate = DateFormat('dd-MMM-yy').format(parsedDate);
      } catch (e) {
        // Fallback to original string if parsing fails
      }
    }

    // Custom fulfillment badge styling
    final isPickup = deliveryTypeDisplay.toLowerCase() == 'pickup';
    final fulfillmentBg = isPickup
        ? (dark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
        : (dark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE));
    final fulfillmentFg = isPickup
        ? (dark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
        : (dark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF));
    final fulfillmentIcon = isPickup ? TablerIcons.building_store : TablerIcons.truck_delivery;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: dark ? 0.15 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.05 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID + Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('orderNumber', positionalArgs: [orderId]),
                      style: TextStyle(
                        fontSize: isTablet(context) ? 18.sp : 13.sp,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Status badge below order number
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: palette.bg,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: palette.accent.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            orderStatus.icon,
                            size: 12.sp,
                            color: palette.fg,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            orderStatus == OrderStatus.needsReschedule ? context.tr('needsReschedule') : status,
                            style: TextStyle(
                              fontSize: isTablet(context) ? 14.sp : 11.sp,
                              fontWeight: FontWeight.w700,
                              color: palette.fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Fulfillment Type Badge
                if (rescheduleStatus == 'needs_reschedule' || orderStatus == OrderStatus.cancelled)
                  const SizedBox()
                else if (deliveryTypeDisplay.isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: fulfillmentBg,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                fulfillmentIcon,
                                size: 12.sp,
                                color: fulfillmentFg,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                deliveryTypeDisplay,
                                style: TextStyle(
                                  fontSize: isTablet(context) ? 14.sp : 10.sp,
                                  color: fulfillmentFg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (displayScheduledDate.isNotEmpty) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  TablerIcons.calendar_time,
                                  size: 12.sp,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  displayScheduledDate,
                                  style: TextStyle(
                                    fontSize: isTablet(context) ? 14.sp : 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            if (scheduledTimeSlotLabel != null && scheduledTimeSlotLabel!.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    TablerIcons.clock,
                                    size: 10.sp,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 2.w),
                                  Flexible(
                                    child: Text(
                                      scheduledTimeSlotLabel!,
                                      style: TextStyle(
                                        fontSize: isTablet(context) ? 13.sp : 9.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 14.h),
            const Divider(height: 1, thickness: 0.5),
            SizedBox(height: 14.h),

            // Product Image Cards
            SizedBox(
              height: 72.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: orderItems.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final item = orderItems[index];
                  final imageUrl = item.product?.image ?? '';

                  return Container(
                    width: 72.w,
                    height: 72.h,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: dark ? 0.15 : 0.10),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11.r),
                      child: imageUrl.isNotEmpty
                          ? CustomImageContainer(
                              imagePath: imageUrl,
                              fit: BoxFit.contain,
                            )
                          : Center(
                              child: Icon(
                                TablerIcons.package,
                                size: 24.sp,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 14.h),
            const Divider(height: 1, thickness: 0.5),
            SizedBox(height: 14.h),

            // Action Button
            if (isDelivered)
              GestureDetector(
                onTap: onRateOrder,
                child: SizedBox(
                  height: 35.h,
                  width: double.infinity,
                  child: CustomButton(
                    onPressed: onRateOrder,
                    child: Text(
                      context.tr('rateOrder'),
                      style: TextStyle(
                        fontSize: isTablet(context) ? 18.sp : 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else if (!isDelivered && isDeliveryBoyAssigned)
              GestureDetector(
                onTap: onTrackOrder,
                child: SizedBox(
                  height: 35.h,
                  width: double.infinity,
                  child: CustomButton(
                    onPressed: onTrackOrder,
                    child: Text(
                      context.tr('trackYourOrder'),
                      style: TextStyle(
                        fontSize: isTablet(context) ? 18.sp : 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 35.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('viewDetails'),
                      style: TextStyle(
                        fontSize: isTablet(context) ? 18.sp : 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      TablerIcons.chevron_right,
                      size: 15.sp,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDeliveryTypeDisplay(String? type) {
    if (type == null) return '';
    switch (type.toLowerCase()) {
      case 'pos':
        return 'POS';
      case 'regular':
      case 'delivery':
        return 'Delivery';
      case 'pickup':
        return 'Pickup';
      default:
        return capitalizeFirstLetter(type);
    }
  }
}

import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/my_orders/bloc/order_detail/order_detail_bloc.dart';
import 'package:hyper_local/screens/my_orders/model/order_status.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/store_detail/store_detail_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import '../../near_by_stores/model/near_by_store_model.dart';

class ReadyForPickupPage extends StatefulWidget {
  final String orderSlug;
  const ReadyForPickupPage({super.key, required this.orderSlug});

  @override
  State<ReadyForPickupPage> createState() => _ReadyForPickupPageState();
}

class _ReadyForPickupPageState extends State<ReadyForPickupPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    context.read<OrderDetailBloc>().add(FetchOrderDetail(orderSlug: widget.orderSlug));
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        context.read<OrderDetailBloc>().add(
          FetchOrderDetail(orderSlug: widget.orderSlug),
        );
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _navigateToStore(String? lat, String? lng) async {
    if (lat == null || lng == null) return;
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch maps.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderDetailBloc, OrderDetailState>(
      listener: (context, state) {
        if (state is OrderDetailLoaded) {
          final order = state.cartData.first.data;
          final storeSlug = order?.items.isNotEmpty == true ? order!.items.first.store?.slug : null;
          if (storeSlug != null) {
            context.read<StoreDetailBloc>().add(FetchStoreDetail(storeSlug: storeSlug));
          }
        }
      },
      builder: (context, orderState) {
        if (orderState is OrderDetailLoading || orderState is OrderDetailInitial) {
          return const Scaffold(
            body: Center(child: CustomCircularProgressIndicator()),
          );
        }

        if (orderState is OrderDetailFailed) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('statusReadyForPickup', fallback: 'Ready for pickup'))),
            body: Center(child: Text(orderState.error)),
          );
        }

        if (orderState is! OrderDetailLoaded) {
          return const Scaffold(
            body: SizedBox.shrink(),
          );
        }

        final order = orderState.cartData.first.data;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('statusReadyForPickup', fallback: 'Ready for pickup'))),
            body: Center(child: Text(context.tr('errorLoadingOrder', fallback: "Error loading order"))),
          );
        }

        final bool isReady = order.status?.toLowerCase().contains('ready') == true ||
            order.status == 'ready_for_pickup';

        return BlocBuilder<StoreDetailBloc, StoreDetailState>(
          builder: (context, storeState) {
            StoreData? storeDetails;
            if (storeState is StoreDetailLoaded) {
              storeDetails = storeState.storeData;
            }

            final storeName = order.items.isNotEmpty ? order.items.first.store?.name : '';
            final storeAddress = storeDetails?.address ?? order.items.first.store?.address ?? '';
            final storeLatitude = storeDetails?.latitude ?? order.items.first.store?.latitude;
            final storeLongitude = storeDetails?.longitude ?? order.items.first.store?.longitude;

            // Parse OTP
            final otp = order.items.isNotEmpty && order.items.first.otp != null
                ? order.items.first.otp.toString()
                : '';

            final orderStatus = OrderStatusX.fromString(order.status);
            final bool isAccepted = orderStatus != OrderStatus.placed &&
                orderStatus != OrderStatus.cancelled &&
                orderStatus != OrderStatus.failed &&
                orderStatus != OrderStatus.unknown;

            final theme = Theme.of(context);
            final dark = theme.brightness == Brightness.dark;

            return Scaffold(
              backgroundColor: theme.colorScheme.surfaceContainer,
              appBar: AppBar(
                backgroundColor: AppTheme.primaryColor,
                title: Text(
                  context.tr('statusReadyForPickup', fallback: 'Ready for pickup'),
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    TablerIcons.arrow_narrow_left,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                bottom: PreferredSize(
                  preferredSize: Size(double.infinity, 35.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isReady
                            ? (context.tr('heroReadyForPickup', fallback: 'Your order is ready for pickup'))
                            : 'Order will be prepared shortly',
                        style: TextStyle(
                          fontSize: 20.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  children: [
                    // Alert Banner Card
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: dark ? theme.colorScheme.surfaceContainer : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: dark ? Colors.transparent : Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.bell,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              isReady
                                  ? 'Your order is ready for pickup.'
                                  : "We'll notify you once the order is ready to pickup.",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: dark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Store Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: dark ? theme.colorScheme.surfaceContainer : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  TablerIcons.building_store,
                                  color: AppTheme.primaryColor,
                                  size: 22.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      storeName ?? '',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: dark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      storeAddress,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (storeLatitude != null && storeLongitude != null) ...[
                            SizedBox(height: 16.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToStore(
                                  storeLatitude.toString(),
                                  storeLongitude.toString(),
                                ),
                                icon: Icon(
                                  TablerIcons.navigation,
                                  color: Colors.white,
                                  size: 18.sp,
                                ),
                                label: Text(
                                  'Navigate to store',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Pickup OTP Card
                    if (otp.isNotEmpty && isAccepted) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: dark ? theme.colorScheme.surface : AppTheme.primaryColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: dark ? theme.colorScheme.outlineVariant : AppTheme.primaryColor.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Pickup OTP',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: otp.split('').map((digit) {
                                return Container(
                                  width: 42.w,
                                  height: 48.h,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: dark ? theme.colorScheme.surfaceContainer : Colors.white,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: dark ? theme.colorScheme.outlineVariant : AppTheme.primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    digit,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: dark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Share this OTP with the store to collect your order',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],

                    // Order Summary Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: dark ? theme.colorScheme.surfaceContainer : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18.r,
                                backgroundColor: Colors.grey[100],
                                child: Icon(
                                  TablerIcons.shopping_bag,
                                  color: Colors.grey[700],
                                  size: 18.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('orderSummary', fallback: 'Order Summary'),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: dark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Order ID: ${order.id}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // Items Images Horizontal Scroll List
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: order.items.map((item) {
                                return Container(
                                  margin: EdgeInsets.only(right: 8.w),
                                  width: 50.w,
                                  height: 50.h,
                                  decoration: BoxDecoration(
                                    color: dark ? theme.colorScheme.surface : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: dark ? theme.colorScheme.outlineVariant : Colors.grey[200]!),
                                  ),
                                    child: item.product?.image != null
                                        ? CustomImageContainer(
                                            imagePath: item.product!.image!,
                                            fit: BoxFit.cover,
                                            borderRadius: BorderRadius.circular(8.r),
                                          )
                                        : Icon(
                                            TablerIcons.package,
                                            color: Colors.grey[400],
                                          ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                context.push(
                                  AppRoutes.orderDetail,
                                  extra: {
                                    'order-slug': widget.orderSlug,
                                    'allowRedirect': false,
                                  },
                                );
                              },
                              child: Text(
                                context.tr('viewOrderDetails', fallback: 'View order details'),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Order Details Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: dark ? theme.colorScheme.surfaceContainer : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('orderDetails', fallback: 'Order details'),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildDetailRow(
                            context.tr('orderId', fallback: 'Order ID'),
                            '${order.id}',
                          ),
                          const Divider(),
                          _buildDetailRow(
                            context.tr('payment', fallback: 'Payment'),
                            order.paymentMethod?.toLowerCase() == 'cod'
                                ? 'Cash On Delivery'
                                : order.paymentMethod?.toUpperCase() ?? '',
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Order placed',
                            order.createdAt ?? '',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

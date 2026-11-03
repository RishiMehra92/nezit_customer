import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/my_orders/bloc/delivery_tracking/delivery_tracking_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/order_detail/order_detail_bloc.dart';
import 'package:hyper_local/screens/my_orders/model/delivery_tracking_model.dart';
import 'package:hyper_local/screens/my_orders/model/order_status.dart';
import 'package:hyper_local/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/delivery_slot_bottom_sheet.dart';
import '../repo/order_repo.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import '../utils/tracking_route_manager.dart';
import '../widgets/delivery_details_section.dart';
import '../widgets/delivery_partner_not_assigned.dart';
import '../widgets/delivery_partner_section.dart';
import '../widgets/delivery_success_card.dart';
import '../widgets/order_details_section.dart';
import '../widgets/order_summary_widget.dart';
import '../widgets/tracking_map_widget.dart';

class DeliveryTrackingPage extends StatefulWidget {
  final String orderSlug;
  const DeliveryTrackingPage({super.key, required this.orderSlug});

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  Timer? _refreshTimer;
  final TrackingRouteManager _routeManager = TrackingRouteManager();
  final GlobalKey<TrackingMapWidgetState> _mapKey = GlobalKey();

  DeliveryBoyTrackingModel? _currentTracking;
  bool _isDelivered = false;
  bool _trackingUpdateInProgress = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 8));

    context.read<DeliveryTrackingBloc>().add(
          FetchDeliveryTracking(orderSlug: widget.orderSlug),
        );
    context.read<OrderDetailBloc>().add(
          FetchOrderDetail(orderSlug: widget.orderSlug),
        );

    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        context.read<DeliveryTrackingBloc>().add(
              FetchDeliveryTracking(orderSlug: widget.orderSlug),
            );
      }
    });
  }

  void _onRefreshTap() {
    context.read<DeliveryTrackingBloc>().add(
          FetchDeliveryTracking(orderSlug: widget.orderSlug),
        );
  }

  Future<void> _onTrackingLoaded(DeliveryTrackingLoaded state) async {
    if (!mounted || _trackingUpdateInProgress) return;
    _trackingUpdateInProgress = true;
    try {
      setState(() => _currentTracking = state.tracking);
      await _mapKey.currentState?.processTrackingUpdate(state.tracking);
    } finally {
      _trackingUpdateInProgress = false;
    }
  }

  String _getStatusText(String? status) {
    if (status == null || status.isEmpty) return context.tr('trackingOrder');
    final result = status.replaceAll('_', ' ').replaceAll('-', ' ');
    if (result.isEmpty) return context.tr('trackingOrder');
    return result[0].toUpperCase() + result.substring(1).toLowerCase();
  }

  String _getETAText() {
    final eta = _currentTracking?.data?.order?.estimatedDeliveryTime;
    if (eta == null || eta == 0) return context.tr('shortly');
    return '$eta ${context.tr('minutesLabel')}';
  }

  @override
  Widget build(BuildContext context) {
    final orderDetailState = context.watch<OrderDetailBloc>().state;
    final orderDetail = orderDetailState is OrderDetailLoaded && orderDetailState.cartData.isNotEmpty
        ? orderDetailState.cartData.first.data
        : null;
    final bool needsReschedule = orderDetail?.orderStatus == OrderStatus.needsReschedule;

    final isDeliveredStatus = _isDelivered || _currentTracking?.data?.order?.status == 'delivered';

    final TrackedOrder? trackedOrder = _currentTracking?.data?.order;
    final bool isRejectedOrCancelled = OrderStatusX.fromString(trackedOrder?.status).isRejectedOrCancelled;

    final String? scheduledDateStr = trackedOrder?.scheduledDate;
    final bool isScheduled = !isRejectedOrCancelled && scheduledDateStr != null && scheduledDateStr.isNotEmpty;
    final bool shouldHideMap = isScheduled || isRejectedOrCancelled;

    String displayScheduledDate = '';
    bool isScheduledToday = false;
    if (isScheduled) {
      try {
        final parsedDate = DateTime.parse(scheduledDateStr);
        displayScheduledDate = DateFormat('dd-MMM-yy').format(parsedDate);
        final now = DateTime.now();
        if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day) {
          isScheduledToday = true;
        }
      } catch (e) {
        displayScheduledDate = scheduledDateStr;
      }
    }

    return BlocListener<OrderDetailBloc, OrderDetailState>(
      listener: (context, state) {
        if (state is OrderDetailActionLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        } else if (state is OrderDetailActionSuccess) {
          Navigator.of(context, rootNavigator: true).pop();
          ToastManager.show(
            context: context,
            message: state.message,
            type: ToastType.success,
          );
          if (state.actionType == 'cancel' || state.actionType == 'reschedule') {
            context.read<DeliveryTrackingBloc>().add(
                  FetchDeliveryTracking(orderSlug: widget.orderSlug),
                );
            context.read<OrderDetailBloc>().add(
                  FetchOrderDetail(orderSlug: widget.orderSlug),
                );
          }
        } else if (state is OrderDetailActionFailed) {
          Navigator.of(context, rootNavigator: true).pop();
          ToastManager.show(
            context: context,
            message: state.error,
            type: ToastType.error,
          );
        } else if (state is OrderDetailLoaded) {
          final order = state.cartData.first.data;
          if (order?.fulfillmentType?.toLowerCase() == 'pickup') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go(AppRoutes.orderDetail, extra: {'order-slug': widget.orderSlug});
              }
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: AppTheme.primaryColor,
          title: Text(
            needsReschedule
                ? context.tr('needsReschedule')
                : isDeliveredStatus
                    ? context.tr('orderDelivered')
                    : _getStatusText(_currentTracking?.data?.order?.status),
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size(double.infinity, needsReschedule ? 0 : 28),
            child: needsReschedule
                ? const SizedBox.shrink()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isDeliveredStatus
                            ? context.tr('successfullyDelivered')
                            : _currentTracking == null
                                ? context.tr('loading')
                                : isScheduled
                                    ? (isScheduledToday &&
                                            trackedOrder?.scheduledTimeSlotLabel != null &&
                                            trackedOrder?.scheduledTimeSlotLabel?.isNotEmpty == true
                                        ? 'Arriving At ${trackedOrder?.scheduledTimeSlotLabel}'
                                        : context.tr('arrivingOn', positionalArgs: [displayScheduledDate]))
                                    : isRejectedOrCancelled
                                        ? _getStatusText(trackedOrder?.status)
                                        : '${context.tr('arrivingIn')} ${_getETAText()}',
                        style: TextStyle(
                          fontSize: (isScheduled && isScheduledToday) ? 18 : 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (!shouldHideMap)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                  child: Material(
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: isDeliveredStatus
                          ? _SuccessAnimation(
                              confettiController: _confettiController,
                            )
                          : TrackingMapWidget(
                              key: _mapKey,
                              routeManager: _routeManager,
                              tracking: _currentTracking,
                              onRefreshTap: _onRefreshTap,
                            ),
                    ),
                  ),
                ),
              BlocConsumer<DeliveryTrackingBloc, DeliveryTrackingState>(
                listener: (context, state) {
                  if (state is DeliveryTrackingLoaded) {
                    if (state.tracking.data?.order?.fulfillmentType?.toLowerCase() == 'pickup') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          context.go(AppRoutes.orderDetail, extra: {'order-slug': widget.orderSlug});
                        }
                      });
                      return;
                    }
                    if (state.tracking.data?.order?.status == 'delivered') {
                      if (!_isDelivered) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _isDelivered = true);
                            _confettiController.play();
                            _refreshTimer?.cancel();
                          }
                        });
                      }
                    }
                    if (!_trackingUpdateInProgress) _onTrackingLoaded(state);
                  }
                },
                builder: (context, state) {
                  final isFirstLoad = _currentTracking == null && state is DeliveryTrackingLoading;
                  if (isFirstLoad) return _buildLoadingShimmer();
                  if (state is DeliveryTrackingFailed && _currentTracking == null) {
                    return _buildErrorView(state.error);
                  }
                  return _buildContentSections(state, needsReschedule, orderDetail);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: [
        for (final h in [100.0, 180.0, 120.0, 100.0])
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
            child: ShimmerWidget.rectangular(isBorder: true, height: h),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildErrorView(String errorMsg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(TablerIcons.shopping_bag, size: 80, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(errorMsg, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          CustomButton(
            onPressed: _onRefreshTap,
            child: Text(context.tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSections(
    DeliveryTrackingState state,
    bool needsReschedule,
    OrderDetailData? orderDetail,
  ) {
    final tracking = (state is DeliveryTrackingLoaded) ? state.tracking : _currentTracking;

    if (tracking == null || tracking.data?.order == null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ShimmerWidget.rectangular(height: 60, borderRadius: 12, isBorder: true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerWidget.rectangular(
                    height: [80, 140, 100, 120][index % 4].toDouble(),
                    isBorder: true,
                    borderRadius: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      );
    }

    final order = tracking.data!.order;
    final routeDetails = tracking.data?.route?.routeDetails ?? [];
    final deliveryBoys = tracking.data?.deliveryBoys ?? const [];

    final partnerName = order?.deliveryBoyName ??
        (deliveryBoys.isNotEmpty ? deliveryBoys.first.data?.deliveryBoy?.fullName : null) ??
        context.tr('deliveryPartner');
    final partnerPhone = order?.deliveryBoyPhone?.toString();
    final deliveryPartnerProfile = order?.deliveryBoyProfile ?? '';

    final destTitle = order?.shippingAddressType ?? context.tr('destinationLabel');
    final destSubtitle = [
      order?.shippingAddress1,
      order?.shippingLandmark,
      order?.shippingCity,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');

    final orderIdText = order?.id?.toString() ?? '';
    String paymentText = (order?.paymentStatus?.toLowerCase() == 'paid')
        ? '${context.tr('paidLabel')} ${order?.paymentMethod ?? ''}'.trim()
        : (order?.paymentMethod ?? '');
    if (paymentText.toLowerCase() == 'cod') {
      paymentText = 'Cash On Delivery';
    } else if (paymentText.toLowerCase().contains('cod')) {
      paymentText = paymentText.replaceAll(RegExp(r'\bcod\b', caseSensitive: false), 'Cash On Delivery');
    }
    final placedAtText = order?.createdAt ?? '';

    final bool isRejectedOrCancelled = OrderStatusX.fromString(order?.status).isRejectedOrCancelled;
    final rescheduleStatus = orderDetail?.orderStatus == OrderStatus.needsReschedule ? 'needs_reschedule' : null;

    return StaggeredListAnimator(
      type: StaggeredListType.column,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isDelivered)
          const DeliverySuccessCard()
        else if (!isRejectedOrCancelled) ...[
          if (deliveryBoys.isEmpty)
            const DeliveryPartnerNotAssigned()
          else
            DeliveryPartnerSection(
              name: partnerName,
              phone: partnerPhone,
              deliveryBoyProfile: deliveryPartnerProfile,
            ),
        ],
        if (!isRejectedOrCancelled)
          DeliveryDetailsSection(
            stops: routeDetails,
            destTitle: destTitle,
            destSubtitle: destSubtitle,
            isDelivered: _isDelivered,
          ),
        OrderSummaryWidget(
          orderData: order ?? TrackedOrder(),
          rescheduleStatus: rescheduleStatus,
          onRescheduleTap: orderDetail == null ? null : () => _onRescheduleTap(orderDetail),
        ),
        OrderDetailsSection(
          orderId: orderIdText,
          payment: paymentText,
          orderPlaced: paymentText,
          placedAt: placedAtText,
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _onRescheduleTap(OrderDetailData orderDetail) async {
    final orderId = orderDetail.id;
    if (orderId == null) return;

    final storeId = orderDetail.items.firstOrNull?.storeId;
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('storeDetailsNotFoundForRescheduling', fallback: 'Store details not found for rescheduling'))),
      );
      return;
    }

    final result = await DeliverySlotBottomSheet.show(
      context: context,
      initialDate: null,
      initialTimeSlot: null,
      maxDays: orderDetail.store?.maxAdvanceBookingDays ?? 30,
      availableDays: orderDetail.store?.availableDays?.map((e) => e.toString()).toList(),
      rescheduleDeadline: orderDetail.rescheduleDeadline,
      showCancelOrderButton: true,
      onFetchSlots: (date) => OrderRepository().getRecoverySlots(
        orderId: orderId,
        date: date,
      ),
    );

    if (!mounted) return;

    if (result == 'cancel') {
      final confirmCancel = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(TablerIcons.alert_triangle, color: Colors.red[700]),
                const SizedBox(width: 12),
                Text(ctx.tr('cancelOrder', fallback: "Cancel Order")),
              ],
            ),
            content: Text(ctx.tr('areYouSureYouWantToCancelThisOrder', fallback: "Are you sure you want to cancel this order?")),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  ctx.tr('cancel', fallback: "Cancel"),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(ctx.tr('confirm', fallback: "Confirm")),
              ),
            ],
          );
        },
      );

      if (confirmCancel == true && mounted) {
        context.read<OrderDetailBloc>().add(
              CancelOrder(orderId: orderId, orderSlug: widget.orderSlug),
            );
      }
    } else if (result != null && result is! String) {
      final selected = result as ({DateTime? date, String? timeSlot, int? slotId, String? startTime, String? endTime});

      if (selected.date != null) {
        final String formattedDate = DateFormat('yyyy-MM-dd').format(selected.date!);

        context.read<OrderDetailBloc>().add(
              RescheduleOrder(
                orderId: orderId,
                orderSlug: widget.orderSlug,
                date: formattedDate,
                startTime: selected.startTime ?? '',
                endTime: selected.endTime ?? '',
              ),
            );
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class _SuccessAnimation extends StatelessWidget {
  final ConfettiController confettiController;
  const _SuccessAnimation({required this.confettiController});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
            createParticlePath: _drawStar,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('delivered'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('orderDeliveredSuccessfully'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ui.Path _drawStar(Size size) {
    double degToRad(double deg) => deg * (math.pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = ui.Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * math.cos(step), halfWidth + externalRadius * math.sin(step));
      path.lineTo(halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * math.sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}

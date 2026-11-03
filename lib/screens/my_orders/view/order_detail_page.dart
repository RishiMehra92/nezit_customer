import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/payment_config.dart';
import 'package:hyper_local/screens/payment_options/bloc/payment_bloc.dart';
import 'package:hyper_local/screens/payment_options/bloc/payment_state.dart';
import 'package:hyper_local/screens/payment_options/bloc/payment_event.dart';
import 'package:hyper_local/screens/cart_page/widgets/bill_summary_widget.dart';
import 'package:hyper_local/screens/cart_page/widgets/rider_tip_section.dart';
import 'package:hyper_local/screens/my_orders/bloc/get_my_order/get_my_order_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/get_my_order/get_my_order_event.dart';
import 'package:hyper_local/screens/my_orders/bloc/re_order/re_order_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/return_order_item/return_order_item_bloc.dart';
import 'package:hyper_local/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_local/screens/my_orders/model/order_status.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/store_detail/store_detail_bloc.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_action_bar.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_address_card.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_below_hero_section.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_cancel_tile.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_help_link.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_items_preview_card.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_meta_card.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_status_hero_card.dart';
import 'package:hyper_local/screens/my_orders/widgets/return_dialog.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_feedback/product_feedback_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/widgets/dialog_box_animation.dart';
import '../bloc/order_detail/order_detail_bloc.dart';
import '../widgets/order_note_display_widget.dart';
import '../widgets/order_returns_section.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderSlug;
  final bool allowRedirect;
  const OrderDetailPage({
    super.key,
    required this.orderSlug,
    this.allowRedirect = true,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  OrderDetailLoaded? _lastLoadedState;
  int _otpRemainingSeconds = 900;
  Timer? _otpCountdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    _startOtpCountdown();
  }

  @override
  void dispose() {
    _otpCountdownTimer?.cancel();
    super.dispose();
  }

  void _startOtpCountdown() {
    _otpCountdownTimer?.cancel();
    _otpCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_otpRemainingSeconds > 0) {
            _otpRemainingSeconds--;
          } else {
            _otpCountdownTimer?.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  bool _isActionState(OrderDetailState state) =>
      state is OrderDetailActionLoading || state is OrderDetailActionSuccess || state is OrderDetailActionFailed;

  Future<void> _fetchOrder() async {
    if (!mounted) return;
    context.read<OrderDetailBloc>().add(FetchOrderDetail(orderSlug: widget.orderSlug));
  }

  Future<void> _onRated() async {
    if (!mounted) return;
    context.read<ProductFeedbackBloc>().add(ResetProductFeedback());
    await _fetchOrder();
    if (!mounted) return;
        ToastManager.show(
      context: context,
      message: context.tr('orderDetailsRefreshed', fallback: 'Order details refreshed'),
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> _launchInvoice(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      log('Cannot launch URL: $uri');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showReturnDialog(OrderDetailData order) {
    openSlideUpDialog(
      context,
      ReturnItemsDialog(
        items: order.items,
        orderSlug: order.slug ?? widget.orderSlug,
        isDelivered: order.status == 'delivered',
        orderStatus: order.status,
        currencyCode: order.currencyCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ReturnOrderItemBloc, ReturnOrderItemState>(
          listener: _onReturnState,
        ),
        BlocListener<ReOrderBloc, ReOrderState>(listener: _onReOrderState),
        BlocListener<OrderDetailBloc, OrderDetailState>(
          listener: (context, state) {
            if (state is OrderDetailLoaded) {
              _lastLoadedState = state;
              final order = state.cartData.first.data;
              final storeSlug = order?.items.isNotEmpty == true ? order!.items.first.store?.slug : null;
              if (storeSlug != null) {
                context.read<StoreDetailBloc>().add(FetchStoreDetail(storeSlug: storeSlug));
              }
            }
          },
        ),
      ],
      child: BlocBuilder<OrderDetailBloc, OrderDetailState>(
        builder: (context, state) {
          return CustomScaffold(
            showViewCart: false,
            title: context.tr('orderSummary', fallback: 'Order Summary'),
            showAppBar: true,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            body: CustomRefreshIndicator(
              onRefresh: _fetchOrder,
              child: _buildBody(context, state),
            ),
            bottomNavigationBar: _buildBottomBar(state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderDetailState state) {
    final effectiveState = _isActionState(state) ? (_lastLoadedState ?? state) : state;

    if (effectiveState is OrderDetailLoading || effectiveState is OrderDetailInitial) {
      return const CustomCircularProgressIndicator();
    }
    if (effectiveState is OrderDetailFailed) {
      return _ErrorView(message: effectiveState.error, onRetry: _fetchOrder);
    }
    if (effectiveState is! OrderDetailLoaded) return const SizedBox.shrink();
    final order = effectiveState.cartData.first.data;
    if (order == null) {
      return _ErrorView(
        message: context.tr('errorLoadingOrder', fallback: "Couldn't load order details"),
        onRetry: _fetchOrder,
      );
    }
    final status = OrderStatusX.fromString(order.status);
    final isPickup = order.deliveryType?.toLowerCase() == 'pickup' || order.fulfillmentType?.toLowerCase() == 'pickup';

    if (isPickup && widget.allowRedirect && status == OrderStatus.readyForPickup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.replace(AppRoutes.readyForPickup, extra: {'order-slug': widget.orderSlug});
        }
      });
      return const CustomCircularProgressIndicator();
    } else if (!isPickup &&
        widget.allowRedirect &&
        (status != OrderStatus.delivered && status != OrderStatus.cancelled && status != OrderStatus.failed)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.replace(AppRoutes.deliveryTracking, extra: {'order-slug': widget.orderSlug});
        }
      });
      return const CustomCircularProgressIndicator();
    }
    return _LoadedBody(
      order: order,
      status: status,
      onRated: _onRated,
      onReturnTap: () => _showReturnDialog(order),
      onDownloadInvoice: () => _launchInvoice(order.invoice),
      otpRemainingSeconds: _otpRemainingSeconds,
      onRefresh: _fetchOrder,
    );
  }

  Widget? _buildBottomBar(OrderDetailState state) {
    final effectiveState = _isActionState(state) ? (_lastLoadedState ?? state) : state;

    if (effectiveState is! OrderDetailLoaded) return null;
    final order = effectiveState.cartData.first.data;
    if (order == null) return null;
    final status = OrderStatusX.fromString(order.status);
    return OrderActionBar(
      order: order,
      status: status,
      onReturnTap: () => _showReturnDialog(order),
    );
  }

  void _onReturnState(BuildContext context, ReturnOrderItemState state) {
    if (state is ReturnOrderItemSuccess) {
      ToastManager.show(context: context, message: state.message);
      _fetchOrder();
      context.read<GetMyOrderBloc>().add(RefreshMyOrders());
    } else if (state is ReturnOrderItemFailed) {
      ToastManager.show(
        context: context,
        message: state.error,
        type: ToastType.error,
      );
    }
  }

  void _onReOrderState(BuildContext context, ReOrderState state) {
    if (state is ReOrderedSuccess) {
      context.go(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push(AppRoutes.cart);
      });
    } else if (state is ReOrderedFailed) {
      ToastManager.show(
        context: context,
        message: state.errorList.join('\n\n'),
        type: ToastType.error,
        duration: const Duration(seconds: 5),
      );
    }
  }
}

class _LoadedBody extends StatefulWidget {
  final OrderDetailData order;
  final OrderStatus status;
  final Future<void> Function() onRated;
  final VoidCallback onReturnTap;
  final VoidCallback onDownloadInvoice;
  final int otpRemainingSeconds;
  final VoidCallback onRefresh;

  const _LoadedBody({
    required this.order,
    required this.status,
    required this.onRated,
    required this.onReturnTap,
    required this.onDownloadInvoice,
    required this.otpRemainingSeconds,
    required this.onRefresh,
  });

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody> {
  final Set<String> _expandedStores = {};
  double? _selectedTipAmount;
  PaymentMethodType? _lastSelectedPaymentMethodType;

  String _getPaymentMethodName(PaymentMethodType? type) {
    if (type == null) return '';
    switch (type) {
      case PaymentMethodType.razorpay:
        return 'razorpay';
      case PaymentMethodType.stripe:
        return 'stripe';
      case PaymentMethodType.paystack:
        return 'paystack';
      case PaymentMethodType.paypal:
        return 'paypal';
      case PaymentMethodType.flutterwave:
        return 'flutterwave';
      case PaymentMethodType.mercadoPago:
        return 'mercadoPago';
      case PaymentMethodType.xendit:
        return 'xendit';
      case PaymentMethodType.cod:
        return 'cod';
      case PaymentMethodType.phonepe:
        return 'phonepe';
      default:
        return '';
    }
  }

  double avgRatingCalculation() {
    final ratings = widget.order.items.map((data) => data.userReview?.rating?.toDouble() ?? 0.0).toList();

    if (ratings.isEmpty) return 0.0;

    final total = ratings.reduce((a, b) => a + b);
    return total / ratings.length;
  }

  @override
  Widget build(BuildContext context) {
        final isPickup =
        widget.order.deliveryType?.toLowerCase() == 'pickup' || widget.order.fulfillmentType?.toLowerCase() == 'pickup';

    // Group items by store to count how many pickup stops there are
    final Map<String, List<OrderItems>> groupedByStore = {};
    for (final item in widget.order.items) {
      final store = item.store ?? Store(name: 'Unknown Store', slug: 'unknown');
      final slug = store.slug ?? 'unknown';
      if (!groupedByStore.containsKey(slug)) {
        groupedByStore[slug] = [];
      }
      groupedByStore[slug]!.add(item);
    }

    final isOrderWiseOtp = widget.order.deliveryOtpMode?.toLowerCase().trim() == 'order_wise';
    final displayOtp = (widget.order.deliveryOtp ?? widget.order.otp ?? widget.order.pickupOtp ?? '').trim();
    final hasDeliveryOtp = !isPickup &&
        !isOrderWiseOtp &&
        displayOtp.isNotEmpty &&
        widget.status != OrderStatus.delivered &&
        widget.status != OrderStatus.cancelled &&
        widget.status != OrderStatus.failed &&
        widget.status != OrderStatus.returned;

    final children = <Widget>[
      OrderStatusHeroCard(order: widget.order, status: widget.status),
      OrderBelowHeroSection(
        order: widget.order,
        status: widget.status,
        onRated: widget.onRated,
        avgRating: avgRatingCalculation(),
      ),
      if (hasDeliveryOtp) ...[
        SizedBox(height: 10.h),
        _buildDeliveryOtpCard(context, displayOtp),
      ],
      if (isPickup) ...[
        SizedBox(height: 15.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            "${groupedByStore.length} PICKUP STOPS",
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
      if (!isPickup) ...[
        SizedBox(height: 10.h),
        OrderItemsPreviewCard(
          items: widget.order.items,
          subtotal: widget.order.subtotal,
          deliveryOtp: widget.order.deliveryOtp ?? widget.order.otp,
          deliveryOtpMode: widget.order.deliveryOtpMode,
          deliveryOtpRequired: widget.order.deliveryOtpRequired,
          deliveryOtpVerified: widget.order.deliveryOtpVerified,
          orderStatus: widget.status,
          currencyCode: widget.order.currencyCode,
        ),
      ],
      if (!isPickup && widget.status.allowsCancel) ...[
        SizedBox(height: 10.h),
        OrderCancelTile(
          status: widget.status,
          onCancelTap: widget.onReturnTap,
        ),
      ],
      ..._buildAddressOrStoreCard(context),
      if (isPickup && widget.status.allowsCancel) ...[
        SizedBox(height: 10.h),
        OrderCancelTile(
          status: widget.status,
          onCancelTap: widget.onReturnTap,
        ),
      ],
      if ((widget.order.orderNote ?? '').trim().isNotEmpty) ...[
        SizedBox(height: 10.h),
        OrderNoteDisplayWidget(orderNote: widget.order.orderNote ?? ''),
      ],
      SizedBox(height: 10.h),
      _BillSummaryGuard(
        order: widget.order,
        onDownloadInvoice: widget.onDownloadInvoice,
      ),
      SizedBox(height: 10.h),
      OrderMetaCard(
        orderId: widget.order.id?.toString() ?? '',
        paymentMethod: widget.order.paymentMethod ?? '',
        createdAt: widget.order.createdAt,
        invoiceUrl: widget.order.invoice,
        onDownloadInvoice: widget.onDownloadInvoice,
      ),
      SizedBox(height: 8.h),
      // ── Returns Section ──────────────────────────────────
      OrderReturnsSection(
        items: widget.order.items,
        currencyCode: widget.order.currencyCode,
      ),
      SizedBox(height: 8.h),
      const OrderHelpLink(),
      SizedBox(height: 12.h),
    ];

    return MultiBlocListener(
      listeners: [
        BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentSuccess) {
              final paymentMethodName = _getPaymentMethodName(_lastSelectedPaymentMethodType);
              final tipAmountToPay = _selectedTipAmount ?? 0.0;

              if (_lastSelectedPaymentMethodType == PaymentMethodType.xendit ||
                  _lastSelectedPaymentMethodType == PaymentMethodType.flutterwave ||
                  _lastSelectedPaymentMethodType == PaymentMethodType.mercadoPago) {
                // Skip client-side tip api call as backend webhooks handle it automatically
                ToastManager.show(
                  context: context,
                  message: 'Tip paid successfully',
                  type: ToastType.success,
                );
                widget.onRefresh();
                setState(() {
                  _selectedTipAmount = null;
                  _lastSelectedPaymentMethodType = null;
                });
              } else {
                context.read<OrderDetailBloc>().add(
                      PayOrderTip(
                        orderSlug: widget.order.slug ?? '',
                        riderTipAmount: tipAmountToPay,
                        paymentMethod: paymentMethodName,
                        transactionId: state.transactionId,
                      ),
                    );
              }
            } else if (state is PaymentFailure) {
              ToastManager.show(
                context: context,
                message: state.error,
                type: ToastType.error,
              );
            }
          },
        ),
        BlocListener<OrderDetailBloc, OrderDetailState>(
          listener: (context, state) {
            if (state is OrderDetailActionSuccess && state.actionType == 'pay_tip') {
              ToastManager.show(
                context: context,
                message: state.message,
                type: ToastType.success,
              );
              widget.onRefresh();
              setState(() {
                _selectedTipAmount = null;
                _lastSelectedPaymentMethodType = null;
              });
            } else if (state is OrderDetailActionFailed) {
              ToastManager.show(
                context: context,
                message: state.error,
                type: ToastType.error,
              );
            }
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: StaggeredListAnimator(
          type: StaggeredListType.column,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  List<Widget> _buildAddressOrStoreCard(BuildContext context) {
    final isPickup =
        widget.order.deliveryType?.toLowerCase() == 'pickup' || widget.order.fulfillmentType?.toLowerCase() == 'pickup';

    if (isPickup) {
      // Group items by store slug
      final Map<String, ({Store store, List<OrderItems> items})> groupedByStore = {};
      for (final item in widget.order.items) {
        final store = item.store ?? Store(name: 'Unknown Store', slug: 'unknown');
        final slug = store.slug ?? 'unknown';
        if (!groupedByStore.containsKey(slug)) {
          groupedByStore[slug] = (store: store, items: []);
        }
        groupedByStore[slug]!.items.add(item);
      }

      // Filter to unique stores that have prepared items or if the order is ready for pickup
      final Map<String, ({Store store, List<OrderItems> items})> uniqueStores = {};
      final Map<String, String> storeOtps = {};

      for (final entry in groupedByStore.entries) {
        final storeSlug = entry.key;
        final storeData = entry.value;

        bool anyItemPrepared = false;
        String storeOtp = '';

        for (final item in storeData.items) {
          final s = item.status?.toLowerCase().trim();
          final itemOtp = item.otp?.toString() ?? '';
          final isPrepared = s == 'accepted' ||
              s == 'preparing' ||
              s == 'collected' ||
              s == 'ready_for_pickup' ||
              s == 'delivered' ||
              itemOtp.isNotEmpty;

          if (isPrepared) {
            anyItemPrepared = true;
          }
          if (itemOtp.isNotEmpty) {
            storeOtp = itemOtp;
          }
        }

        if (anyItemPrepared || widget.status == OrderStatus.readyForPickup) {
          uniqueStores[storeSlug] = storeData;
          if (storeOtp.isNotEmpty) {
            storeOtps[storeSlug] = storeOtp;
          }
        }
      }

      if (uniqueStores.isEmpty) {
        return const [];
      }

      final List<Widget> widgets = [];
      int stopIndex = 1;
      final totalStops = uniqueStores.length;

      for (final storeEntry in uniqueStores.entries) {
        final storeSlug = storeEntry.key;
        final storeData = storeEntry.value;
        final otp = storeOtps[storeSlug] ?? widget.order.pickupOtp ?? '';

        widgets.add(SizedBox(height: 10.h));
        widgets.add(
          _buildPickupStoreCard(
            context,
            store: storeData.store,
            storeItems: storeData.items,
            stopIndex: stopIndex,
            totalStops: totalStops,
            otp: otp,
            orderStatus: widget.status,
          ),
        );
        stopIndex++;
      }

      return widgets;
    }

    final showTipBox = (widget.order.riderTipAmount ?? 0.0) == 0.0 &&
        widget.status != OrderStatus.delivered &&
        widget.status != OrderStatus.returned &&
        widget.status != OrderStatus.cancelled &&
        widget.status != OrderStatus.failed;

    return [
      SizedBox(height: 10.h),
      OrderAddressCard(
        label: widget.status == OrderStatus.delivered
            ? context.tr('deliveredTo', fallback: 'Delivered to') : context.tr('deliveryAddress', fallback: 'Delivery address'),
        address: widget.order.shippingAddress1 ?? '',
        addressType: widget.order.shippingAddressType,
      ),
      if (showTipBox) ...[
        SizedBox(height: 10.h),
        RiderTipSection(
          isCod: false,
          initialTip: _selectedTipAmount,
          isFromOrderDetails: true,
          onTipChanged: (tip) {
            setState(() {
              _selectedTipAmount = tip;
            });
          },
          onTipButtonPressed: () async {
            if (_selectedTipAmount == null || _selectedTipAmount! <= 0) return;
            final paymentMethodType = await context.push(
              AppRoutes.paymentOptions,
              extra: {
                'totalAmount': _selectedTipAmount,
                'deliveryType': widget.order.deliveryType,
                'isPickupCodEnabled': false,
                'hasTip': true,
                'currencyCode': widget.order.currencyCode,
              },
            );

            if (paymentMethodType != null && paymentMethodType is PaymentMethodType && context.mounted) {
              setState(() {
                _lastSelectedPaymentMethodType = paymentMethodType;
              });
              context.read<PaymentBloc>().add(
                    InitiatePaymentEvent(
                      paymentMethodType: paymentMethodType,
                      amount: _selectedTipAmount!,
                      context: context,
                      additionalData: {
                        'userId': Global.userData?.userId.toString() ?? '',
                        'customerName': Global.userData?.name.toString() ?? '',
                        'email': Global.userData?.email.toString() ?? '',
                        'phone': Global.userData?.mobile.toString() ?? '',
                        'orderId': widget.order.id,
                        'orderSlug': widget.order.slug ?? '',
                        if (widget.order.currencyCode != null && widget.order.currencyCode!.isNotEmpty)
                          'currency': widget.order.currencyCode,
                      },
                      addMoneyToWallet: false,
                      description: 'Rider Tip Payment',
                    ),
                  );
            }
          },
        ),
      ],
    ];
  }

  ({String label, Color bg, Color fg, IconData? icon})? _getStoreStatusPill(String? status, bool dark) {
    if (status == null) return null;
    final cleanStatus = status.toLowerCase().trim();
    switch (cleanStatus) {
      case 'pending':
        return (
          label: 'Pending',
          bg: dark ? Colors.orange[900]!.withValues(alpha: 0.2) : Colors.orange[50]!,
          fg: dark ? Colors.orange[300]! : Colors.orange[700]!,
          icon: Icons.access_time,
        );
      case 'awaiting_store_response':
      case 'awaiting_store_confirmation':
        return (
          label: 'Awaiting Store Response',
          bg: dark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
          fg: dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
          icon: Icons.hourglass_empty,
        );
      case 'accepted':
        return (
          label: 'Accepted',
          bg: dark ? Colors.green[900]!.withValues(alpha: 0.2) : Colors.green[50]!,
          fg: dark ? Colors.green[300]! : Colors.green[700]!,
          icon: Icons.check,
        );
      case 'preparing':
        return (
          label: 'Preparing',
          bg: dark ? Colors.blue[900]!.withValues(alpha: 0.2) : Colors.blue[50]!,
          fg: dark ? Colors.blue[300]! : Colors.blue[700]!,
          icon: Icons.kitchen,
        );
      case 'ready_for_pickup':
      case 'ready':
        return (
          label: 'Ready',
          bg: dark ? Colors.teal[900]!.withValues(alpha: 0.2) : Colors.teal[50]!,
          fg: dark ? Colors.teal[300]! : Colors.teal[700]!,
          icon: Icons.shopping_bag,
        );
      case 'collected':
      case 'delivered':
        return (
          label: 'Collected',
          bg: dark ? Colors.grey[800]! : Colors.grey[100]!,
          fg: dark ? Colors.grey[300]! : Colors.grey[700]!,
          icon: Icons.check_box_outlined,
        );
      case 'cancelled':
      case 'canceled':
      case 'failed':
      case 'rejected':
        return (
          label: 'Cancelled',
          bg: dark ? Colors.red[900]!.withValues(alpha: 0.2) : Colors.red[50]!,
          fg: dark ? Colors.red[300]! : Colors.red[700]!,
          icon: Icons.cancel_outlined,
        );
      default:
        final formattedLabel = status.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
        return (
          label: formattedLabel,
          bg: dark ? Colors.grey[800]! : Colors.grey[100]!,
          fg: dark ? Colors.grey[300]! : Colors.grey[700]!,
          icon: null,
        );
    }
  }

  Widget _buildDeliveryOtpCard(BuildContext context, String otp) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    const primaryColor = AppTheme.primaryColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: dark ? theme.colorScheme.surfaceContainer : primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: dark ? theme.colorScheme.outlineVariant : primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                TablerIcons.shield_check,
                color: primaryColor,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'Delivery OTP',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
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
                  color: dark ? theme.colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: dark ? theme.colorScheme.outlineVariant : primaryColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
            'Share this OTP with the delivery partner to collect your order',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupStoreCard(
    BuildContext context, {
    required Store store,
    required List<OrderItems> storeItems,
    required int stopIndex,
    required int totalStops,
    required String otp,
    required OrderStatus orderStatus,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    const primaryColor = AppTheme.primaryColor;

    // Get store-level status pill config
    final storeStatus = storeItems.isNotEmpty ? storeItems.first.status : null;
    final pill = _getStoreStatusPill(storeStatus, dark);
    final storeSlug = store.slug ?? 'unknown';
    final isExpanded = _expandedStores.contains(storeSlug);
    final canOpenStore = storeSlug.trim().isNotEmpty && storeSlug != 'unknown';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Store Header Section
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canOpenStore ? () => _openStoreDetails(context, store) : null,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: store.storeLogo != null && store.storeLogo!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: store.storeLogo!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Icon(
                                  TablerIcons.building_store,
                                  color: primaryColor,
                                  size: 22.sp,
                                ),
                              )
                            : Icon(
                                TablerIcons.building_store,
                                color: primaryColor,
                                size: 22.sp,
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  store.name ?? '',
                                  style: TextStyle(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: dark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              if (pill != null) ...[
                                SizedBox(width: 6.w),
                                _StatusPill(
                                  label: pill.label,
                                  bg: pill.bg,
                                  fg: pill.fg,
                                  icon: pill.icon,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "${storeItems.length} ${storeItems.length == 1 ? 'item' : 'items'} · Stop $stopIndex of $totalStops",
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canOpenStore) ...[
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 18.sp,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 2. Address Section
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canOpenStore ? () => _openStoreDetails(context, store) : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey[500],
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        store.address ?? '',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Divider(height: 1.h, color: dark ? theme.colorScheme.outlineVariant : Colors.grey[100]),

          // 3. OTP Section (if applicable and not delivered)
          if (otp.isNotEmpty && orderStatus != OrderStatus.delivered) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              color: dark ? theme.colorScheme.surface : Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('showThisOtpAtStore', fallback: "Show this OTP at store"),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    otp.split('').join(' '),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.black,
                      letterSpacing: 2.w,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1.h, color: dark ? theme.colorScheme.outlineVariant : Colors.grey[100]),
          ],

          // 4. Store Items Section
          Column(
            children: (isExpanded ? storeItems : storeItems.take(2)).map((item) {
              final productSlug = item.product?.slug?.trim() ?? '';
              final canOpenProduct = productSlug.isNotEmpty;
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canOpenProduct ? () => _openProductDetails(context, item) : null,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Item Image
                            Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: dark ? theme.colorScheme.surface : Colors.grey[50],
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: dark ? theme.colorScheme.outlineVariant : Colors.grey[100]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: item.product?.image != null && item.product!.image!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.product!.image!,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Icon(
                                          TablerIcons.package,
                                          color: Colors.grey[400],
                                          size: 20.sp,
                                        ),
                                      )
                                    : Icon(
                                        TablerIcons.package,
                                        color: Colors.grey[400],
                                        size: 20.sp,
                                      ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // Item Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product?.name ?? item.title ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: dark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    "${item.variantTitle ?? ''} · Qty ${item.quantity}",
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // Price
                            Text(
                              MoneyDisplay.format(item.subtotal ?? '0', currencyCode: widget.order.currencyCode),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1.h, color: dark ? theme.colorScheme.outlineVariant : Colors.grey[100]),
                ],
              );
            }).toList(),
          ),

          if (storeItems.length > 2) ...[
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedStores.remove(storeSlug);
                  } else {
                    _expandedStores.add(storeSlug);
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isExpanded ? TablerIcons.chevron_up : TablerIcons.chevron_down,
                      size: 16.sp,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isExpanded ? "SHOW LESS" : "SHOW MORE",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1.h, color: dark ? theme.colorScheme.outlineVariant : Colors.grey[100]),
          ],

          // 5. Open in Maps Button at the very bottom
          InkWell(
            onTap: () => _navigateToStore(store.latitude, store.longitude),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    TablerIcons.navigation,
                    size: 14.sp,
                    color: Colors.blue[600],
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Open in Maps",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  void _openStoreDetails(BuildContext context, Store store) {
    final storeSlug = store.slug?.trim() ?? '';
    if (storeSlug.isEmpty || storeSlug == 'unknown') return;
    GoRouter.of(context).push(
      AppRoutes.nearbyStoreDetails,
      extra: {
        'store-slug': storeSlug,
        'store-name': store.name ?? '',
      },
    );
  }

  void _openProductDetails(BuildContext context, OrderItems item) {
    final productSlug = item.product?.slug?.trim() ?? '';
    if (productSlug.isEmpty) return;
    GoRouter.of(context).push(
      AppRoutes.productDetailPage,
      extra: {
        'productSlug': productSlug,
        'title': item.product?.name ?? item.title ?? '',
        'mainImage': item.product?.image ?? '',
      },
    );
  }
}

class _BillSummaryGuard extends StatelessWidget {
  final OrderDetailData order;
  final VoidCallback onDownloadInvoice;

  const _BillSummaryGuard({
    required this.order,
    required this.onDownloadInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = order.deliveryType == 'pickup';

    final totalPayable = double.tryParse(order.totalPayable ?? '');
    final subtotal = double.tryParse(order.subtotal ?? '');

    final double? parsedDeliveryCharge = double.tryParse(order.deliveryCharge ?? '');
    final double? parsedHandling = double.tryParse(order.handlingCharges ?? '');
    final double? parsedPerStore = double.tryParse(order.perStoreDropOffFee ?? '');
    final double? parsedFinalTotal = double.tryParse(order.finalTotal ?? '');

    if (totalPayable == null || subtotal == null) {
      return const SizedBox.shrink();
    }

    if (!isPickup &&
        (parsedDeliveryCharge == null ||
            parsedHandling == null ||
            parsedPerStore == null ||
            parsedFinalTotal == null)) {
      return const SizedBox.shrink();
    }

    final deliveryCharge = isPickup ? 0.0 : parsedDeliveryCharge!;
    final handling = isPickup ? 0.0 : parsedHandling!;
    final perStore = isPickup ? 0.0 : parsedPerStore!;

    final finalTotal = isPickup
        ? ((parsedFinalTotal ?? 0.0) -
            (parsedDeliveryCharge ?? 0.0) -
            (parsedPerStore ?? 0.0) -
            (parsedHandling ?? 0.0) -
            (order.riderTipAmount ?? 0.0))
        : parsedFinalTotal!;

    final promoDiscount = double.tryParse(order.promoDiscount ?? '0.0') ?? 0.0;

    final double? parsedWalletUsed = double.tryParse(order.walletBalance ?? '');
    final double walletUsed = parsedWalletUsed ?? 0.0;

    return BillSummaryWidget(
      currencyCode: order.currencyCode,
      itemsOriginalPrice: totalPayable,
      itemsDiscountedPrice: subtotal,
      itemsSavings: 0,
      deliveryChargeOriginal: deliveryCharge,
      handlingCharge: handling,
      perStoreDropOffFees: perStore,
      grandTotal: finalTotal,
      totalSavings: 0,
      isFromOrderDetail: true,
      downloadInvoice: onDownloadInvoice,
      promoCode: order.promoCode,
      promoDiscount: promoDiscount,
      totalPayable: totalPayable,
      walletBalanceUsed: walletUsed,
      riderTip: isPickup ? null : order.riderTipAmount,
      paymentMethod: order.paymentMethod,
      codCharges: order.codCharges,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  const _StatusPill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11.sp,
              color: fg,
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 36.sp, color: scheme.onSurfaceVariant),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.tr('retryLabel', fallback: 'Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/my_orders/bloc/get_my_order/get_my_order_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/get_my_order/get_my_order_event.dart';
import 'package:hyper_local/screens/my_orders/bloc/get_my_order/get_my_order_state.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../../../config/helper.dart';
import 'package:hyper_local/utils/widgets/delivery_slot_bottom_sheet.dart';
import '../repo/order_repo.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/screens/my_orders/bloc/order_detail/order_detail_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import '../model/order_filter_model.dart';
import '../widgets/my_order_card.dart';
import '../widgets/order_filter_bottom_sheet.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  OrderFilter _filter = const OrderFilter();
  @override
  void initState() {
    super.initState();
    context.read<GetMyOrderBloc>().add(FetchMyOrder());
  }

  void _openFilterSheet() {
    OrderFilterSheet.show(
      context: context,
      dateOptions: SettingsData.instance.system!.dataFilterEnum!,
      sortOptions: SettingsData.instance.system!.orderStatusEnum!,
      currentFilter: _filter,
      onApply: (newFilter) {
        setState(() => _filter = newFilter);
        // Optionally re-fetch with filters:
        context.read<GetMyOrderBloc>().add(FetchMyOrder(
              dateFilter: _filter.selectedDateFilter,
              statusSort: _filter.selectedStatusSort,
              deliveryType: _filter.selectedDeliveryType,
              isScheduled: _filter.isScheduled ? 1 : null,
            ));
      },
    );
  }

  Future<void> _onRescheduleTap({
    required int orderId,
    required String orderSlug,
    required String? rescheduleDeadline,
    required int? storeId,
  }) async {
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.tr('storeDetailsNotFoundForRescheduling', fallback: 'Store details not found for rescheduling'))),
      );
      return;
    }

    final result = await DeliverySlotBottomSheet.show(
      context: context,
      initialDate: null,
      initialTimeSlot: null,
      maxDays: 30,
      availableDays: null,
      rescheduleDeadline: rescheduleDeadline,
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
            content: Text(ctx.tr('areYouSureYouWantToCancelThisOrder',
                fallback: "Are you sure you want to cancel this order?")),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  ctx.tr('cancel', fallback: "Cancel"),
                  style: TextStyle(color: AppTheme.textSecondary(ctx)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              CancelOrder(orderId: orderId, orderSlug: orderSlug),
            );
      }
    } else if (result != null && result is! String) {
      final selected = result as ({
        DateTime? date,
        String? timeSlot,
        int? slotId,
        String? startTime,
        String? endTime
      });

      if (selected.date != null) {
        final String formattedDate =
            DateFormat('yyyy-MM-dd').format(selected.date!);

        context.read<OrderDetailBloc>().add(
              RescheduleOrder(
                orderId: orderId,
                orderSlug: orderSlug,
                date: formattedDate,
                startTime: selected.startTime ?? '',
                endTime: selected.endTime ?? '',
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      title: context.tr('myOrders'),
      showAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBarActions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openFilterSheet,
              tooltip: 'Filters',
            ),
            if (_filter.hasFilters)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_filter.activeCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
      body: BlocListener<OrderDetailBloc, OrderDetailState>(
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
            context.read<GetMyOrderBloc>().add(FetchMyOrder(
                  dateFilter: _filter.selectedDateFilter,
                  statusSort: _filter.selectedStatusSort,
                  deliveryType: _filter.selectedDeliveryType,
                  isScheduled: _filter.isScheduled ? 1 : null,
                ));
          } else if (state is OrderDetailActionFailed) {
            Navigator.of(context, rootNavigator: true).pop();
            ToastManager.show(
              context: context,
              message: state.error,
              type: ToastType.error,
            );
          }
        },
        child: BlocBuilder<GetMyOrderBloc, GetMyOrderState>(
          builder: (context, state) {
            if (state is GetMyOrderLoading) {
              return const Center(
                child: CustomCircularProgressIndicator(),
              );
            } else if (state is GetMyOrderLoaded) {
              final allOrders = state.myOrderData;
              final filteredOrders = _filter.selectedDeliveryType == null
                  ? allOrders
                  : allOrders.where((order) {
                      final orderDelType =
                          (order.deliveryType ?? order.fulfillmentType)
                              ?.toLowerCase();
                      final filterDelType =
                          _filter.selectedDeliveryType!.toLowerCase();
                      if (filterDelType == 'regular') {
                        return orderDelType == 'regular' ||
                            orderDelType == 'delivery';
                      }
                      return orderDelType == filterDelType;
                    }).toList();

              log('Total Orders ${filteredOrders.length}');
              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filter.hasFilters
                            ? 'No orders match this filter'
                            : (context.tr('noOrdersYet', fallback: 'No orders yet')),
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return CustomRefreshIndicator(
                onRefresh: () async {
                  context.read<GetMyOrderBloc>().add(FetchMyOrder(
                      dateFilter: _filter.selectedDateFilter,
                      statusSort: _filter.selectedStatusSort,
                      deliveryType: _filter.selectedDeliveryType,
                      isScheduled: _filter.isScheduled ? 1 : null));
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo is ScrollUpdateNotification &&
                        !state.hasReachedMax &&
                        !state.isLoadingMore &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                      log('Selected Date  ${_filter.selectedDateFilter}');
                      log('Selected Sort  ${_filter.selectedStatusSort}');
                      context.read<GetMyOrderBloc>().add(
                            FetchMoreMyOrder(
                                dateFilter: _filter.selectedDateFilter,
                                statusSort: _filter.selectedStatusSort,
                                deliveryType: _filter.selectedDeliveryType,
                                isScheduled: _filter.isScheduled ? 1 : null),
                          );
                    }
                    return false;
                  },
                  child: StaggeredListAnimator.builder(
                    type: StaggeredListType.listView,
                    shrinkWrap: false,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredOrders.length + ((!state.hasReachedMax && state.isLoadingMore) ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredOrders.length) {
                        return const SizedBox(
                          height: 80,
                          child: CustomCircularProgressIndicator(),
                        );
                      }
                      
                      final order = filteredOrders[index];
                      return GestureDetector(
                        onTap: () {
                          final type =
                              (order.deliveryType ?? order.fulfillmentType)
                                  ?.toLowerCase();
                          final isPickup = type == 'pickup';
                          final isDelivery =
                              type == 'delivery' || type == 'regular';
                          final statusLower = order.status?.toLowerCase();
                          final isReadyForPickup =
                              statusLower == 'ready_for_pickup' ||
                                  statusLower == 'readyforpickup';

                          if (isPickup) {
                            if (isReadyForPickup) {
                              GoRouter.of(context).push(
                                  AppRoutes.readyForPickup,
                                  extra: {'order-slug': order.slug});
                            } else {
                              GoRouter.of(context).push(AppRoutes.orderDetail,
                                  extra: {'order-slug': order.slug});
                            }
                          } else if (isDelivery) {
                            if (order.status == 'delivered' ||
                                order.status == 'cancelled' ||
                                order.status == 'failed') {
                              GoRouter.of(context).push(AppRoutes.orderDetail,
                                  extra: {'order-slug': order.slug});
                            } else {
                              GoRouter.of(context).push(
                                  AppRoutes.deliveryTracking,
                                  extra: {'order-slug': order.slug});
                            }
                          } else {
                            // Fallback when we don't know the fulfillmentType (null in list view)
                            // Route to details page, which loads full data and redirects correctly
                            GoRouter.of(context).push(AppRoutes.orderDetail,
                                extra: {'order-slug': order.slug});
                          }
                        },
                        child: OrderDeliveryCard(
                          status: capitalizeFirstLetter(
                              removeUnderscores(order.status ?? 'Pending')),
                          dateTime: formatDateTime(
                              DateTime.tryParse(order.createdAt.toString())),
                          orderItems: order.items,
                          orderId: order.id.toString(),
                          deliveryType:
                              order.deliveryType ?? order.fulfillmentType,
                          scheduledDate: order.scheduledDate,
                          scheduledTimeSlotLabel: order.scheduledTimeSlotLabel,
                          deliveryTimeSlotId: order.deliveryTimeSlotId,
                          rescheduleStatus: order.rescheduleStatus,
                          rescheduleDeadline: order.rescheduleDeadline,
                          onRescheduleTap: () => _onRescheduleTap(
                            orderId: order.id!,
                            orderSlug: order.slug!,
                            rescheduleDeadline: order.rescheduleDeadline,
                            storeId: order.items.firstOrNull?.storeId,
                          ),
                          onRateOrder: () {
                            final storeMap = {
                              "orderSlug": order.slug,
                              "orderId": order.id,
                            };

                            GoRouter.of(context).push(
                              AppRoutes.rateYourExp,
                              extra: storeMap,
                            );
                          },
                          onTrackOrder: () {
                            final type =
                                (order.deliveryType ?? order.fulfillmentType)
                                    ?.toLowerCase();
                            final isPickup = type == 'pickup';
                            final isDelivery =
                                type == 'delivery' || type == 'regular';
                            final statusLower = order.status?.toLowerCase();
                            final isReadyForPickup =
                                statusLower == 'ready_for_pickup' ||
                                    statusLower == 'readyforpickup';

                            if (isPickup) {
                              if (isReadyForPickup) {
                                GoRouter.of(context).push(
                                    AppRoutes.readyForPickup,
                                    extra: {'order-slug': order.slug});
                              } else {
                                GoRouter.of(context).push(AppRoutes.orderDetail,
                                    extra: {'order-slug': order.slug});
                              }
                            } else if (isDelivery) {
                              GoRouter.of(context).push(
                                  AppRoutes.deliveryTracking,
                                  extra: {'order-slug': order.slug});
                            } else {
                              GoRouter.of(context).push(AppRoutes.orderDetail,
                                  extra: {'order-slug': order.slug});
                            }
                          },
                          isDelivered: order.status == 'delivered',
                          isDeliveryBoyAssigned: order.deliveryBoyId != null,
                          orderSlug: order.slug!,
                        ),
                      );
                    },
                  ),
                ),
              );
            } else if (state is GetMyOrderFailed) {
              return NoOrderPage(
                onRetry: () {
                  context.read<GetMyOrderBloc>().add(FetchMyOrder());
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

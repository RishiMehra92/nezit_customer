import 'package:flutter_svg/flutter_svg.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/config/payment_config.dart';
import 'package:hyper_local/screens/cart_page/bloc/clear_cart/clear_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/clear_cart/clear_cart_event.dart';
import 'package:hyper_local/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_event.dart';
import 'package:hyper_local/screens/cart_page/bloc/update_item_quantity/update_item_quantity_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/update_item_quantity/update_item_quantity_event.dart';
import 'package:hyper_local/screens/cart_page/bloc/update_item_quantity/update_item_quantity_state.dart';
import 'package:hyper_local/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_state.dart';
import 'package:hyper_local/screens/cart_page/widgets/bill_summary_widget.dart';
import 'package:hyper_local/screens/cart_page/widgets/loyalty_points_progress_widget.dart';
import 'package:hyper_local/screens/cart_page/widgets/delivery_address_widget.dart';
import 'package:hyper_local/screens/cart_page/widgets/address_selection_bottom_sheet.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_detail_shimmer.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../config/global.dart';
import '../../../config/helper.dart';
import '../../../services/address/selected_address_hive.dart';
import '../../../services/user_cart/cart_validation.dart';
import '../../../utils/widgets/money_display.dart';
import '../../../utils/widgets/whole_page_progress.dart';
import '../../my_orders/bloc/create_order/create_order_bloc.dart';
import '../../payment_options/bloc/payment_bloc.dart';
import '../../payment_options/bloc/payment_event.dart';
import '../../payment_options/bloc/payment_state.dart';
import '../../payment_options/widgets/webview_payment.dart';
import '../../product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import '../../address_list_page/model/get_address_list_model.dart';
import '../../address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import '../../wallet_page/bloc/user_wallet/user_wallet_bloc.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_state.dart';
import '../../../router/app_routes.dart';
import '../bloc/attachment/attachment_bloc.dart';
import '../bloc/cart_ui_bloc/cart_ui_bloc.dart';
import '../bloc/cart_ui_bloc/cart_ui_event.dart';
import '../bloc/cart_ui_bloc/cart_ui_state.dart';
import '../bloc/get_user_cart/get_user_cart_bloc.dart';
import '../bloc/promo_code/promo_code_bloc.dart';
import '../bloc/promo_code/promo_code_event.dart';
import '../bloc/promo_code/promo_code_state.dart';
import '../bloc/clear_cart/clear_cart_state.dart';
import '../model/get_cart_model.dart';
import '../widgets/cart_product_item.dart';
import '../widgets/delivery_method_selector_widget.dart';
import '../widgets/order_note_widget.dart';
import '../widgets/removed_items_widget.dart';
import '../widgets/wallet_usage_widget.dart';
import '../widgets/you_might_also_like_product_widget.dart';
import '../widgets/rider_tip_section.dart';
import '../../../config/dependency_injection_container.dart';
import '../../../services/auth_guard.dart';
import '../../share_cart/service/cart_native_share.dart';
import '../../share_cart/service/shared_cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  AddressListData? selectedAddress;
  double totalAmount = 0.0;
  double walletAmountUsed = 0.0;
  String? selectedPaymentMethod;
  dynamic selectedPaymentMethodType;
  bool isCartLoading = true;
  bool _isInitialFetch = true;
  bool isClearingCart = false;
  bool isWholePageProgress = false;
  DeliveryType selectedDeliveryType = DeliveryType.regular;
  String selectedOrderDeliveryType = 'delivery';
  int? cartId;
  late bool _userWantsWallet = false;

  List<CartModel> stateData = [];
  int? deliveryZoneId;
  int? previousDeliveryZoneId;
  String? promoCode;
  String orderNote = '';
  bool _isCartSyncing = false;
  bool _isSharingCart = false;
  final GlobalKey _shareButtonKey = GlobalKey();
  double? selectedTipAmount;
  String? _tipError;
  Timer? _tipDebounce;

  void _debounceTipCall(double? tip) {
    setState(() {
      isCartLoading = true;
      _isCartSyncing = true;
    });
    if (_tipDebounce?.isActive ?? false) _tipDebounce!.cancel();
    _tipDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final cartIdFromState = stateData.isNotEmpty ? stateData.first.data?.id : null;
        context.read<GetUserCartBloc>().add(SetCartTipEvent(
              cartId: cartIdFromState,
              tipAmount: tip ?? 0.0,
            ));
      }
    });
  }

  DateTime? _scheduledDate;
  String? _scheduledTimeSlot;
  int? _scheduledTimeSlotId;
  String? _scheduledSlotStartTime;
  String? _scheduledSlotEndTime;

  Future<void> _initCartAndAddress() async {
    // 1. Check if address exists in Hive
    selectedAddress = _getAddressFromHive();

    // 2. If no address in Hive, check AddressListBloc or fetch address list as fallback
    if (selectedAddress == null) {
      final addressBloc = context.read<GetAddressListBloc>();
      var addressState = addressBloc.state;

      // If not yet loaded, trigger fetch and await it
      if (addressState is! GetAddressListLoaded) {
        addressBloc.add(FetchUserAddressList(deliveryZoneId: deliveryZoneId));
        try {
          addressState = await addressBloc.stream
              .firstWhere((s) => s is GetAddressListLoaded || s is GetAddressListFailed)
              .timeout(const Duration(seconds: 2));
        } catch (_) {}
      }

      if (addressState is GetAddressListLoaded) {
        final deliverable =
            addressState.addressList.where((addr) => addr.isDeliverable != false).toList();
        if (deliverable.isNotEmpty) {
          selectedAddress = deliverable.first;
          HiveSelectedAddressHelper.setSelectedAddress(deliverable.first);
        }
      }
    }

    if (mounted) {
      setState(() {});
      context.read<GetUserCartBloc>().add(FetchUserCart(
            addressId: selectedAddress?.id,
            deliveryType: selectedOrderDeliveryType,
          ));
    }
  }

  @override
  void initState() {
    super.initState();
    isCartLoading = true;
    _isInitialFetch = true;
    _userWantsWallet = false;
    _initCartAndAddress();
    context.read<SettingsBloc>().add(FetchSettingsData(context: context));
    context
        .read<SimilarProductBloc>()
        .add(FetchSimilarProduct(excludeProductSlug: context.read<GetUserCartBloc>().productSlug));
    context.read<PromoCodeBloc>().add(RemovePromoCode());
    context.read<UserWalletBloc>().add(FetchUserWallet());
    context.read<AttachmentBloc>().add(ClearAllAttachments());
  }

  bool get canUseWallet {
    final settingsState = context.read<SettingsBloc>().state;
    return settingsState is SettingsLoaded && (SettingsData.instance.payment?.wallet ?? false);
  }

  bool get effectiveUseWallet => canUseWallet && _userWantsWallet;

  List<CartModel>? _cartDataFromState(GetUserCartState state) {
    if (state is GetUserCartLoaded) return state.cartData;
    if (state is GetUserCartUpdating) return state.cartData;
    return null;
  }

  void _refreshCart({bool resetWalletPreference = false, bool silent = false}) {
    if (resetWalletPreference) {
      _userWantsWallet = false;
    }

    context.read<GetUserCartBloc>().add(
          FetchUserCart(
            addressId: selectedAddress?.id,
            rushDelivery: selectedDeliveryType == DeliveryType.rush,
            useWallet: effectiveUseWallet,
            promoCode: promoCode,
            deliveryType: selectedOrderDeliveryType,
            silent: silent,
          ),
        );
  }

  Future<void> _shareCart() async {
    if (_isSharingCart) return;
    setState(() => _isSharingCart = true);
    try {
      if (!await AuthGuard.ensureLoggedIn(context) || !mounted) return;
      final link = await getIt<SharedCartService>().createLink();
      if (!mounted) return;

      final cartData = _getCurrentCartData();
      final count = link.itemsCount > 0
          ? link.itemsCount
          : (cartData?.items.length ?? getIt<SharedCartService>().cart.localRepo.getAllItems().length);

      double total = totalAmount;
      if (total <= 0.0) {
        total = cartData?.paymentSummary?.itemsTotal?.toDouble() ?? 0.0;
      }
      if (total <= 0.0) {
        final localItems = getIt<SharedCartService>().cart.localRepo.getAllItems();
        total = localItems.fold<double>(0.0, (sum, item) {
          final addonsTotal = item.addons.fold<double>(0.0, (aSum, a) => aSum + a.price);
          return sum + ((item.price + addonsTotal) * item.quantity);
        });
      }

      final currencyCode = cartData?.currencyCode;
      final formattedTotal = MoneyDisplay.format(
        total.truncateToDouble() == total
            ? total.toStringAsFixed(0)
            : total.toStringAsFixed(2),
        currencyCode: currencyCode,
      );

      final message = context.tr(
        'shareCartMessage',
        args: {
          'count': count,
          'total': formattedTotal,
          'currency': currencyCode ?? AppHelpers.currency,
          'url': link.url,
        },
        fallback:
            '🛒 Check out this cart! Picked out $count items worth $formattedTotal.\nTap the link to add them to your cart and place the order together:\n👉 ${link.url}',
      );

      Rect origin = Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, 100);
      try {
        final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          origin = box.localToGlobal(Offset.zero) & box.size;
        }
      } catch (_) {}

      await CartNativeShare.share(
        url: link.url,
        message: message,
        title: context.tr('shareCart', fallback: 'Share Cart'),
        copyLabel: context.tr('copyCartLink', fallback: 'Copy Cart Link'),
        copiedLabel: context.tr('cartLinkCopied', fallback: 'Cart link copied'),
        origin: origin,
      );
    } catch (error) {
      if (mounted) {
        ToastManager.show(
          context: context,
          message: error.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingCart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (BuildContext context, PaymentState state) {
        return Stack(
          children: [
            CustomScaffold(
                showViewCart: false,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                title: context.tr('cart', fallback: 'Cart'),
                appBarActions: [
                  BlocBuilder<GetUserCartBloc, GetUserCartState>(
                    builder: (BuildContext context, GetUserCartState state) {
                      bool hasItems = false;

                      final cartData = _cartDataFromState(state);
                      if (cartData != null && cartData.isNotEmpty) {
                        hasItems = cartData.first.data?.items != null &&
                            cartData.first.data!.items.isNotEmpty;
                      }
                      if (hasItems) {
                        return Padding(
                          padding: EdgeInsets.only(right: 10.w),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final shouldClear = await _showClearCartConfirmDialog(context);
                                  if (shouldClear) {
                                    if (context.mounted) {
                                      context.read<ClearCartBloc>().add(ClearCartRequest());
                                      context.read<CartBloc>().add(ClearCart(context: context));
                                    }
                                  }
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    if (context.mounted) {
                                      context.read<GetUserCartBloc>().add(FetchUserCart(
                                            addressId: selectedAddress?.id,
                                            rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                            useWallet: _userWantsWallet,
                                            promoCode: promoCode,
                                            deliveryType: selectedOrderDeliveryType,
                                          ));
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: EdgeInsets.all(4.w),
                                  child: SvgPicture.asset(
                                    'assets/svg/shopping-cart-x.svg',
                                    height: 20,
                                    width: 20,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 8.w,
                              ),
                              InkWell(
                                key: _shareButtonKey,
                                onTap: _isSharingCart ? null : _shareCart,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  height: 22.h,
                                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: _isSharingCart
                                      ? const Center(
                                          child: SizedBox(
                                            height: 12,
                                            width: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppTheme.primaryColor),
                                            ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              TablerIcons.share,
                                              color: AppTheme.primaryColor,
                                              size: 18,
                                            ),
                                            SizedBox(width: 2.w),
                                            Text(
                                              context.tr('share', fallback: 'Share'),
                                              style: const TextStyle(
                                                  color: AppTheme.primaryColor, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
                showAppBar: true,
                body: MultiBlocListener(
                  listeners: [
                    BlocListener<SettingsBloc, SettingsState>(
                      listener: (context, settingsState) {
                        log('Get Address List Bloc  $state');
                        if (settingsState is SettingsLoaded) {
                          final walletAllowed = SettingsData.instance.payment?.wallet ?? false;
                          if (!walletAllowed && _userWantsWallet) {
                            setState(() {
                              _userWantsWallet = false;
                            });

                            // Refresh cart immediately with wallet off
                            _refreshCart();
                          }
                        }
                      },
                    ),
                    BlocListener<GetAddressListBloc, GetAddressListState>(
                      listener: (context, addressState) {
                        log('Get Address List Bloc  $state');
                        if (addressState is GetAddressListLoaded) {
                          final deliverableAddresses = addressState.addressList
                              .where((addr) => addr.isDeliverable != false)
                              .toList();

                          if (deliverableAddresses.isEmpty) {
                            if (selectedAddress != null) {
                              setState(() {
                                selectedAddress = null;
                              });
                            }
                          } else {
                            final hasSelectedInList = selectedAddress != null &&
                                deliverableAddresses.any((addr) => addr.id == selectedAddress!.id);

                            if (selectedAddress == null || !hasSelectedInList) {
                              setState(() {
                                selectedAddress = deliverableAddresses.first;
                                isCartLoading = true;
                              });
                              // Save selected address to Hive
                              HiveSelectedAddressHelper.setSelectedAddress(
                                  deliverableAddresses.first);
                              // Update cart with selected address
                              context.read<GetUserCartBloc>().add(FetchUserCart(
                                    addressId: selectedAddress?.id,
                                    rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                    useWallet: _userWantsWallet,
                                    promoCode: promoCode,
                                    deliveryType: selectedOrderDeliveryType,
                                  ));
                            }
                          }
                        }
                      },
                    ),
                    BlocListener<GetUserCartBloc, GetUserCartState>(listener: (context, state) {
                      log('Get User Cart Bloc  $state');
                      if (state is GetUserCartLoaded) {
                        final cartItems =
                            state.cartData.isNotEmpty ? state.cartData.first.data?.items ?? [] : [];
                        final billSummary = state.cartData.isNotEmpty
                            ? state.cartData.first.data?.paymentSummary
                            : null;
                        final serverTipAmount = billSummary?.riderTipAmount;
                        final storeIds = cartItems
                            .map((item) => item.storeId)
                            .where((id) => id != null)
                            .cast<int>()
                            .toSet();
                        if (storeIds.length > 1) {
                          _scheduledDate = null;
                          _scheduledTimeSlot = null;
                          _scheduledSlotStartTime = null;
                          _scheduledSlotEndTime = null;
                        }
                        final hasNonPickup =
                            cartItems.any((item) => item.store?.allowsPickup != true);
                        if (hasNonPickup && selectedOrderDeliveryType == 'pickup') {
                          setState(() {
                            selectedOrderDeliveryType = 'delivery';
                          });
                          _refreshCart(silent: true);
                        }

                        setState(() {
                          if (serverTipAmount != null) {
                            selectedTipAmount = serverTipAmount;
                          }
                          isCartLoading = false;
                          _isInitialFetch = false;
                          _isCartSyncing = false;
                          // Extract deliveryZoneId from cart data
                          if (state.cartData.isNotEmpty &&
                              state.cartData.first.data?.deliveryZone != null) {
                            final newDeliveryZoneId =
                                state.cartData.first.data?.deliveryZone?.zoneId;
                            // Only fetch addresses if deliveryZoneId changed or is first time set
                            if (newDeliveryZoneId != null &&
                                newDeliveryZoneId != previousDeliveryZoneId) {
                              deliveryZoneId = newDeliveryZoneId;
                              previousDeliveryZoneId = newDeliveryZoneId;
                              // Fetch address list with deliveryZoneId for checkout (only when zone changes)
                              context
                                  .read<GetAddressListBloc>()
                                  .add(FetchUserAddressList(deliveryZoneId: deliveryZoneId));
                            } else if (newDeliveryZoneId != null) {
                              // Update deliveryZoneId but don't fetch addresses if it hasn't changed
                              deliveryZoneId = newDeliveryZoneId;
                            }
                          }
                        });
                        context.read<CartUIBloc>().add(SetWalletLoading(false));
                      } else if (state is GetUserCartUpdating) {
                        setState(() {
                          stateData = state.cartData;
                          isCartLoading = true;
                          _isCartSyncing = true;
                        });
                      } else if (state is GetUserCartLoading) {
                        setState(() {
                          isCartLoading = true;
                          _isCartSyncing = true;
                        });
                        context.read<CartUIBloc>().add(SetWalletLoading(false));
                      } else if (state is GetUserCartFailed) {
                        setState(() {
                          isCartLoading = false;
                          _isInitialFetch = false;
                          _isCartSyncing = false;
                        });
                        context.read<CartUIBloc>().add(SetWalletLoading(false));
                        ToastManager.show(
                          context: context,
                          message: state.error,
                          type: ToastType.error,
                        );
                      } else if (state is SetCartTipSuccess) {
                        context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery: selectedDeliveryType == DeliveryType.rush,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode,
                              deliveryType: selectedOrderDeliveryType,
                            ));
                      }
                    }),
                    BlocListener<RemoveItemFromCartBloc, RemoveItemFromCartState>(
                      listener: (context, state) {
                        log('Remove Item From Cart Bloc  $state');
                        if (state is RemoveItemFromCartLoading) {
                          setState(() {
                            isCartLoading = true;
                            _isCartSyncing = true;
                          });
                        }
                        if (state is RemoveItemFromCartSuccess) {
                          // Keep loading true, will be set to false when cart loads
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                                addressId: selectedAddress?.id,
                                rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                useWallet: _userWantsWallet,
                                promoCode: promoCode,
                                deliveryType: selectedOrderDeliveryType,
                              ));
                        }
                        if (state is RemoveItemFromCartFailed) {
                          setState(() {
                            isCartLoading = false;
                            _isCartSyncing = false;
                          });
                        }
                      },
                    ),
                    BlocListener<ClearCartBloc, ClearCartState>(
                      listener: (context, state) {
                        log('Clear Cart Bloc  $state');
                        if (state is ClearCartLoading) {
                          setState(() {
                            isCartLoading = true;
                            isClearingCart = true;
                            _isCartSyncing = true;
                          });
                        } else if (state is ClearCartSuccess || state is ClearCartFailed) {
                          // context.read<GetUserCartBloc>().add(RefreshUserCart(
                          setState(() {
                            isCartLoading = false;
                            isClearingCart = false;
                            _isCartSyncing = false;
                          });
                        }
                      },
                    ),
                    BlocListener<SaveForLaterBloc, SaveForLaterState>(
                      listener: (context, state) {
                        log('Save For Later Bloc  $state');
                        if (state is SaveForLaterLoading) {
                          setState(() {
                            isCartLoading = true;
                            _isCartSyncing = true;
                          });
                        } else if (state is ProductSavedSuccess) {
                          // Cart will be refreshed automatically
                          setState(() {
                            isCartLoading = false;
                          });

                          ToastManager.show(
                              context: context, message: '${state.productName} is saved for later');
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                                addressId: selectedAddress?.id,
                                rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                useWallet: _userWantsWallet,
                                promoCode: promoCode,
                                deliveryType: selectedOrderDeliveryType,
                              ));
                        } else if (state is SaveForLaterFailed) {
                          setState(() {
                            isCartLoading = false;
                            _isCartSyncing = false;
                          });
                        }
                      },
                    ),
                    BlocListener<CreateOrderBloc, CreateOrderState>(
                      listener: (context, state) async {
                        log('Create Order Bloc  $state');
                        if (state is CreateOrderSuccess) {
                          context.read<CartUIBloc>().add(SetWholePageProgress(true));
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                          setState(() {
                            isWholePageProgress = true;
                            isCartLoading = true;
                          });
                          if (selectedPaymentMethodType == PaymentMethodType.flutterwave ||
                              selectedPaymentMethodType == PaymentMethodType.xendit ||
                              selectedPaymentMethodType == PaymentMethodType.mercadoPago) {
                            if (state.paymentUrl != null && state.paymentUrl!.trim().isNotEmpty) {
                              final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => WebViewPaymentPage(
                                            paymentUrl: state.paymentUrl!,
                                            orderSlug: state.orderSlug,
                                            transactionUuid: state.transactionUuid,
                                            onPaymentSuccess: () {
                                              setState(() {
                                                isWholePageProgress = false;
                                                isCartLoading = false;
                                              });
                                            },
                                            onPaymentFailure: () {
                                              setState(() {
                                                isWholePageProgress = false;
                                                isCartLoading = false;
                                              });
                                              Future.delayed(const Duration(milliseconds: 200), () {
                                                if (context.mounted) {
                                                  context.read<GetUserCartBloc>().add(FetchUserCart(
                                                        addressId: selectedAddress?.id,
                                                        rushDelivery: selectedDeliveryType ==
                                                            DeliveryType.rush,
                                                        useWallet: _userWantsWallet,
                                                        promoCode: promoCode,
                                                        deliveryType: selectedOrderDeliveryType,
                                                      ));
                                                }
                                              });
                                            },
                                          )));

                              if (result != null && result is Map && result['success'] == true) {
                                if (context.mounted) {
                                  final displayAddress = selectedAddress != null
                                      ? formatAddressFromModel(selectedAddress!)
                                      : null;

                                  GoRouter.of(context).pop();
                                  log('Payment successful after webview: ${state.message}');

                                  final finalOrderSlug = (result['order_slug'] != null &&
                                          result['order_slug'].toString().isNotEmpty)
                                      ? result['order_slug']
                                      : state.orderSlug;

                                  // Navigate to order success page
                                  GoRouter.of(context).push(
                                    AppRoutes.orderSuccess,
                                    extra: {
                                      'address': displayAddress,
                                      'addressType': selectedAddress?.addressType ?? '',
                                      'orderSlug': finalOrderSlug,
                                      'isPickup': selectedOrderDeliveryType == 'pickup',
                                    },
                                  );
                                }
                              }
                            } else {
                              setState(() {
                                isWholePageProgress = false;
                                isCartLoading = false;
                              });
                              ToastManager.show(
                                context: context,
                                message: 'Payment link is not available',
                                type: ToastType.error,
                              );
                            }
                          } else {
                            final displayAddress = selectedAddress != null
                                ? formatAddressFromModel(selectedAddress!)
                                : null;

                            GoRouter.of(context).pop();
                            log('Payment successful: ${state.message}');

                            // Navigate to order success page
                            GoRouter.of(context).push(
                              AppRoutes.orderSuccess,
                              extra: {
                                'address': displayAddress,
                                'addressType': selectedAddress?.addressType ?? '',
                                'orderSlug': state.orderSlug,
                                'isPickup': selectedOrderDeliveryType == 'pickup',
                              },
                            );
                          }
                        } else if (state is CreateOrderFailure) {
                          setState(() {
                            isWholePageProgress = false;
                            isCartLoading = false;
                          });
                          ToastManager.show(
                            context: context,
                            message: state.error,
                            type: ToastType.error,
                          );
                        } else if (state is CreateOrderProgress) {
                          setState(() {
                            isWholePageProgress = true;
                          });
                        }
                      },
                    ),
                    // Payment BLoC Listener
                    BlocListener<PaymentBloc, PaymentState>(
                      listener: (context, state) {
                        log('Payment Bloc  $state');
                        log('Payment Success  $state');
                        if (state is PaymentSuccess) {
                          setState(() {
                            isWholePageProgress = false;
                          });
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                          _initiatePayment(
                              paymentId: state.transactionId,
                              signature: state.signature,
                              orderId: state.orderId);
                        } else if (state is PaymentFailure) {
                          setState(() {
                            isWholePageProgress = false;
                          });
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                          ToastManager.show(
                              context: context, message: state.error, type: ToastType.error);
                        } else if (state is PaymentLoading) {
                          setState(() {
                            isWholePageProgress = true;
                          });
                        }
                      },
                    ),
                    BlocListener<CartBloc, CartState>(
                      listener: (context, state) {
                        if (state is CartLoaded) {
                          // If any item is not yet synced (add/update/delete), disable payment button
                          final hasPendingSync = state.items.any((item) => !item.isSynced);
                          if (hasPendingSync) {
                            setState(() {
                              isCartLoading = true;
                              _isCartSyncing = true;
                            });
                          }
                          // Show error if sync failed (e.g. item couldn't be added)
                          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                            setState(() {
                              isCartLoading = false;
                              _isCartSyncing = false;
                            });
                            ToastManager.show(
                              context: context,
                              message: state.errorMessage!,
                              type: ToastType.error,
                            );
                          }
                        } else if (state is CartError) {
                          setState(() {
                            _isCartSyncing = false;
                          });
                          ToastManager.show(
                            context: context,
                            message: state.error,
                            type: ToastType.error,
                          );
                        }
                      },
                    ),
                    BlocListener<UpdateItemQuantityBloc, UpdateItemQuantityState>(
                      listener: (context, state) {
                        log('Update Item Quantity Bloc  $state');
                        if (state is UpdateItemQuantityLoading) {
                          setState(() {
                            isCartLoading = true;
                            _isCartSyncing = true;
                          });
                        }
                        if (state is UpdateItemQuantitySuccess) {
                          // Keep loading true, will be set to false when cart loads
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                                addressId: selectedAddress?.id,
                                rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                useWallet: _userWantsWallet,
                                promoCode: promoCode,
                                deliveryType: selectedOrderDeliveryType,
                              ));
                        }
                        if (state is UpdateItemQuantityFailed) {
                          setState(() {
                            isCartLoading = false;
                            _isCartSyncing = false;
                          });
                        }
                      },
                    ),
                    BlocListener<PromoCodeBloc, PromoCodeState>(
                      listener: (context, state) {
                        if (state is PromoCodeRemoving ||
                            state is PromoCodeApplying ||
                            state is PromoCodeLoading) {
                          setState(() {
                            isCartLoading = true;
                          });
                        }
                        if (state is PromoCodeLoaded) {
                          setState(() {
                            isCartLoading = false;
                          });
                        }
                        if (state is PromoCodeFailed) {
                          setState(() {
                            isCartLoading = false;
                          });
                          ToastManager.show(
                              context: context, message: context.tr('promoCodeAppliedOnYourCart'));
                        }
                        if (state is PromoCodeSelected) {
                          setState(() {
                            promoCode = state.promoCode;
                            isCartLoading = false;
                          });
                          if (state.promoCode.isNotEmpty) {
                            ToastManager.show(
                                context: context,
                                message: context.tr('promoCodeAppliedOnYourCart'));
                          }
                        }
                        if (state is PromoCodeRemoved) {
                          setState(() {
                            promoCode = state.promoCode;
                            isCartLoading = false;
                          });
                        }
                      },
                    )
                  ],
                  child: BlocBuilder<GetUserCartBloc, GetUserCartState>(
                    builder: (BuildContext context, GetUserCartState state) {
                      if (_isInitialFetch || state is UserCartInitialLoading) {
                        return const CustomCircularProgressIndicator();
                      }
                      return CustomRefreshIndicator(
                        onRefresh: () async {
                          context.read<GetUserCartBloc>().add(RefreshUserCart(
                                addressId: selectedAddress?.id,
                                rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                useWallet: _userWantsWallet,
                                promoCode: promoCode,
                                deliveryType: selectedOrderDeliveryType,
                              ));
                          context.read<SettingsBloc>().add(FetchSettingsData(context: context));
                          context
                              .read<GetAddressListBloc>()
                              .add(FetchUserAddressList(deliveryZoneId: deliveryZoneId));
                          context.read<UserWalletBloc>().add(FetchUserWallet());
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: BlocBuilder<GetUserCartBloc, GetUserCartState>(
                            builder: (BuildContext context, GetUserCartState state) {
                              log('Get User Cart State $state');
                              log('isCartLoading $isCartLoading');
                              final cartDataFromState = _cartDataFromState(state);
                              if (cartDataFromState != null) {
                                stateData = cartDataFromState;
                              }
                              if (isClearingCart) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 50.h),
                                      const CustomCircularProgressIndicator(),
                                      SizedBox(height: 10.h),
                                      Text(context.tr('clearingYourCart'),
                                          style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              }
                              if (stateData.isEmpty) {
                                final localCartState = context.read<CartBloc>().state;
                                bool hasLocalItems = false;
                                if (localCartState is CartLoaded) {
                                  hasLocalItems = localCartState.items.isNotEmpty;
                                }

                                if (isCartLoading) {
                                  // We have local items but server/stateData is empty => SYNCING
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(height: 50.h),
                                        const CustomCircularProgressIndicator(),
                                        SizedBox(height: 10.h),
                                        Text(
                                            hasLocalItems
                                                ? (context.tr('syncingYourCart',
                                                    fallback: "Syncing your cart..."))
                                                : (context.tr('loading', fallback: "Loading...")),
                                            style: const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                }

                                // isCartLoading = false;
                                return _buildEmptyCartState();
                              }

                              if (stateData.first.data?.items != null &&
                                  stateData.first.data!.items.isNotEmpty) {
                                cartId = stateData.first.data?.id;
                                final cartData = stateData;
                                final billSummaryData = cartData.first.data?.paymentSummary;
                                deliveryZoneId = cartData.first.data?.deliveryZone?.zoneId;

                                final allItems = cartData.first.data?.items ?? [];
                                final eligibleItems = allItems;

                                double itemsDiscountedPrice =
                                    billSummaryData?.itemsTotal?.toDouble() ?? 0.0;
                                final itemsTotal = (billSummaryData?.itemsTotal != null &&
                                        billSummaryData!.itemsTotal! > 0)
                                    ? billSummaryData.itemsTotal!.toDouble()
                                    : eligibleItems.fold<double>(0.0,
                                        (sum, item) => sum + _calculateCartItemTotalPrice(item));
                                final freeDeliveryAmount = cartData
                                    .first.data?.deliveryZone?.freeDeliveryAmount
                                    ?.toDouble();
                                final isFreeDelivery =
                                    freeDeliveryAmount != null && itemsTotal >= freeDeliveryAmount;
                                final neededForFreeDelivery =
                                    (freeDeliveryAmount != null && freeDeliveryAmount > itemsTotal)
                                        ? freeDeliveryAmount - itemsTotal
                                        : 0.0;
                                final freeDeliverySubtext = (selectedOrderDeliveryType ==
                                            'delivery' &&
                                        freeDeliveryAmount != null &&
                                        freeDeliveryAmount > 0 &&
                                        neededForFreeDelivery > 0)
                                    ? 'Shop for ${MoneyDisplay.format(neededForFreeDelivery, currencyCode: _getCurrentCartData()?.currencyCode)} more to get FREE delivery'
                                    : null;

                                double deliveryChargeOriginal;
                                if (selectedOrderDeliveryType == 'pickup') {
                                  deliveryChargeOriginal = 0.0;
                                } else if (selectedDeliveryType == DeliveryType.rush) {
                                  deliveryChargeOriginal =
                                      billSummaryData?.rushDeliveryCharge ?? 0.0;
                                } else if (isFreeDelivery) {
                                  deliveryChargeOriginal = 0.0;
                                } else {
                                  deliveryChargeOriginal =
                                      billSummaryData?.regularDeliveryCharge ?? 0.0;
                                }
                                debugPrint(
                                    '🚚 Backend Delivery Charges: totalDeliveryCharges=${billSummaryData?.totalDeliveryCharges}, deliveryCharges=${billSummaryData?.deliveryCharges}, parsed deliveryChargeOriginal=$deliveryChargeOriginal');

                                double perStoreDropOffFees = selectedOrderDeliveryType == 'pickup'
                                    ? 0.0
                                    : (billSummaryData?.perStoreDropOffFee?.toDouble() ?? 0.0);

                                double handlingCharge = selectedOrderDeliveryType == 'pickup'
                                    ? 0.0
                                    : (billSummaryData?.handlingCharges?.toDouble() ?? 0.0);

                                double promoDiscount =
                                    double.tryParse(billSummaryData?.promoDiscount ?? '0') ?? 0.0;

                                if (selectedOrderDeliveryType == 'pickup') {
                                  itemsDiscountedPrice = eligibleItems.fold<double>(
                                      0.0, (sum, item) => sum + _calculateCartItemTotalPrice(item));
                                  final totalSubtotal = allItems.fold<double>(
                                      0.0, (sum, item) => sum + _calculateCartItemTotalPrice(item));
                                  if (totalSubtotal > 0) {
                                    promoDiscount =
                                        (promoDiscount * itemsDiscountedPrice) / totalSubtotal;
                                  }
                                }

                                final walletBal = billSummaryData?.walletBalance;
                                final totalWalletBalance = walletBal is num
                                    ? walletBal.toDouble()
                                    : (double.tryParse(walletBal?.toString() ?? '0.00') ?? 0.0);

                                final loyaltyDiscount = billSummaryData
                                        ?.loyaltySummary?.loyaltyPointsDiscountAmount
                                        ?.toDouble() ??
                                    0.0;

                                final codCharge =
                                    selectedPaymentMethod?.toLowerCase().trim() == 'cod'
                                        ? (billSummaryData?.codCharges?.toDouble() ?? 0.0)
                                        : 0.0;

                                final preWalletTotal = itemsDiscountedPrice +
                                    deliveryChargeOriginal +
                                    perStoreDropOffFees +
                                    handlingCharge +
                                    codCharge -
                                    promoDiscount -
                                    loyaltyDiscount +
                                    (selectedOrderDeliveryType == 'pickup'
                                        ? 0.0
                                        : (selectedTipAmount ?? 0.0));
                                walletAmountUsed = _userWantsWallet
                                    ? (totalWalletBalance < preWalletTotal
                                        ? totalWalletBalance
                                        : preWalletTotal)
                                    : 0.0;
                                double grandTotal = preWalletTotal - walletAmountUsed;
                                if (grandTotal < 0.0) {
                                  grandTotal = 0.0;
                                }

                                totalAmount = grandTotal;

                                return StaggeredListAnimator(
                                  type: StaggeredListType.column,
                                  children: [
                                    RemovedItemsWidget(
                                      removedItems: cartData.first.data?.removedItems ?? [],
                                    ),
                                    if (cartData.isNotEmpty &&
                                        cartData.first.success == false &&
                                        cartData.first.message != null &&
                                        cartData.first.message!.trim().isNotEmpty) ...[
                                      Container(
                                        width: double.infinity,
                                        margin: EdgeInsets.only(bottom: 9.h),
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: Colors.red.withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              TablerIcons.alert_triangle,
                                              size: isTablet(context) ? 24.r : 18.r,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    context.tr('warning', fallback: "Warning"),
                                                    style: TextStyle(
                                                      fontSize: isTablet(context) ? 18.sp : 13.sp,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    cartData.first.message!,
                                                    style: TextStyle(
                                                      fontSize: isTablet(context) ? 16.sp : 12.sp,
                                                      fontWeight: FontWeight.w400,
                                                      color:
                                                          Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (selectedOrderDeliveryType == 'pickup' &&
                                        eligibleItems.isEmpty) ...[
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(height: 60.h),
                                            Icon(
                                              Icons.storefront_outlined,
                                              size: 80.r,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(height: 16.h),
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                                              child: Text(
                                                context.tr('noItemsAvailableForPickup',
                                                    fallback:
                                                        'No items in your cart are available for pickup.'),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 60.h),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      CartWidget(
                                        currencyCode: cartData.first.data?.currencyCode,
                                        items: eligibleItems,
                                        stores: cartData.first.data?.stores,
                                        deliveryTime: cartData
                                                .first.data?.paymentSummary?.estimatedDeliveryTime
                                                ?.toString() ??
                                            '',
                                        onQuantityChanged: _handleQuantityChanged,
                                        onRemoveItem: _handleRemoveItem,
                                        onAddMoreItems: _handleAddMoreItems,
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        quantityButtonColor: AppTheme.primaryColor,
                                        priceColor: Colors.black,
                                        originalPriceColor: Colors.grey[500],
                                        isCartUpdating: isCartLoading || _isCartSyncing,
                                        totalItem: selectedOrderDeliveryType == 'pickup'
                                            ? eligibleItems.fold<int>(
                                                0, (sum, item) => sum + (item.quantity ?? 0))
                                            : cartData.first.data?.totalQuantity,
                                        addressId: selectedAddress?.id,
                                        rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                        useWallet: _userWantsWallet,
                                        promoCode: promoCode,
                                        deliveryType: selectedOrderDeliveryType,
                                        selectedDate: _scheduledDate,
                                        selectedTimeSlot: _scheduledTimeSlot,
                                        selectedTimeSlotId: _scheduledTimeSlotId,
                                        onScheduledDateTimeChanged:
                                            (date, timeSlot, slotId, startTime, endTime) {
                                          setState(() {
                                            _scheduledDate = date;
                                            _scheduledTimeSlot = timeSlot;
                                            _scheduledTimeSlotId = slotId;
                                            _scheduledSlotStartTime = startTime;
                                            _scheduledSlotEndTime = endTime;
                                          });
                                        },
                                      ),
                                      _buildOffersAndFreeDeliverySection(
                                        showFreeDelivery: selectedOrderDeliveryType == 'delivery' &&
                                            freeDeliveryAmount != null &&
                                            freeDeliveryAmount > 0,
                                        isFreeDelivery: isFreeDelivery,
                                        freeDeliveryAmount: freeDeliveryAmount?.toDouble() ?? 0.0,
                                        itemsTotal: itemsTotal,
                                        itemsDiscountedPrice: itemsDiscountedPrice,
                                        cartData: cartData.first.data,
                                        billSummaryData: billSummaryData,
                                      ),
                                      SizedBox(
                                        height: 9.h,
                                      ),
                                      BlocBuilder<SimilarProductBloc, SimilarProductState>(
                                          builder: (context, state) {
                                        if (state is SimilarProductLoaded) {
                                          if (state.similarProduct.isNotEmpty) {
                                            return YouMightAlsoLikeProductWidget(
                                                productData: state.similarProduct,
                                                addressId: selectedAddress?.id,
                                                rushDelivery:
                                                    selectedDeliveryType == DeliveryType.rush,
                                                useWallet: _userWantsWallet,
                                                promoCode: promoCode,
                                                isFromCartPage: true);
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        } else if (state is SimilarProductLoading) {
                                          return productListShimmer(3);
                                        }
                                        return const SizedBox.shrink();
                                      }),
                                    ],
                                    SizedBox(
                                      height: 9.h,
                                    ),
                                    DeliveryMethodSelectorWidget(
                                      currencyCode: _getCurrentCartData()?.currencyCode,
                                      selectedMethod: selectedOrderDeliveryType,
                                      isPickupEnabled: isPickupAvailable,
                                      blockedPickupStores: blockedStores,
                                      onMethodChanged: (method) {
                                        setState(() {
                                          selectedOrderDeliveryType = method;
                                          if (method == 'pickup') {
                                            selectedDeliveryType = DeliveryType.regular;
                                            if (selectedPaymentMethod == 'cod') {
                                              final cartData = _getCurrentCartData();
                                              final pickupCodInfo = _getPickupCodStatus(cartData);
                                              final bool isPickupCodEnabled =
                                                  pickupCodInfo['isPickupCodEnabled'] as bool;
                                              if (!isPickupCodEnabled) {
                                                selectedPaymentMethod = null;
                                                selectedPaymentMethodType = null;
                                              }
                                            }
                                          } else if (method == 'delivery') {
                                            context.read<GetAddressListBloc>().add(
                                                  FetchUserAddressList(
                                                      deliveryZoneId: deliveryZoneId),
                                                );
                                          }
                                        });
                                      },
                                      selectedDeliveryType: selectedDeliveryType,
                                      rushDeliveryCharge:
                                          billSummaryData?.rushDeliveryCharge ?? 0.0,
                                      regularDeliveryCharge: isFreeDelivery
                                          ? 0.0
                                          : (billSummaryData?.regularDeliveryCharge ?? 0.0),
                                      isRushDeliveryDisabled:
                                          billSummaryData?.isRushDeliveryAvailable == false,
                                      onDeliveryTypeChanged: (DeliveryType type) {
                                        setState(() {
                                          selectedDeliveryType = type;
                                        });
                                      },
                                    ),
                                    if (selectedOrderDeliveryType != 'pickup' ||
                                        eligibleItems.isNotEmpty) ...[
                                      BlocBuilder<CartUIBloc, CartUIState>(
                                        builder: (context, uiState) {
                                          return BlocBuilder<SettingsBloc, SettingsState>(
                                            builder: (context, settingsState) {
                                              final walletAllowed = settingsState is SettingsLoaded
                                                  ? SettingsData.instance.payment?.wallet ?? false
                                                  : false;

                                              if (!walletAllowed && _userWantsWallet) {
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _userWantsWallet = false;
                                                    });
                                                    _refreshCart(silent: true);
                                                  }
                                                });
                                              }

                                              if (!walletAllowed) {
                                                return const SizedBox.shrink();
                                              }

                                              return Column(
                                                children: [
                                                  SizedBox(
                                                    height: 9.h,
                                                  ),
                                                  WalletUsageWidget(
                                                    isWalletEnabled: effectiveUseWallet,
                                                    isLoading:
                                                        isCartLoading || uiState.isWalletLoading,
                                                    walletAmountUsed: walletAmountUsed,
                                                    availableBalance: totalWalletBalance,
                                                    cartCurrencyCode: stateData.isNotEmpty
                                                        ? stateData.first.data?.currencyCode
                                                        : null,
                                                    onWalletToggle:
                                                        !uiState.isWalletLoading && !isCartLoading
                                                            ? (bool value) {
                                                                setState(() {
                                                                  _userWantsWallet = value;
                                                                });
                                                              }
                                                            : (value) {},
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      OrderNoteWidget(
                                        onNoteChanged: (note) {
                                          setState(() {
                                            orderNote = note;
                                          });
                                        },
                                        isEnabled: !isCartLoading,
                                      ),
                                      if ((SettingsData.instance.deliveryBoy?.enableRiderTips ??
                                              false) &&
                                          selectedOrderDeliveryType != 'pickup')
                                        RiderTipSection(
                                          isCod: selectedPaymentMethod == 'cod',
                                          initialTip: selectedTipAmount,
                                          onTipChanged: (tip) {
                                            _debounceTipCall(tip);
                                          },
                                          onValidationErrorChanged: (errorText) {
                                            _tipError = errorText;
                                          },
                                        ),
                                      BillSummaryWidget(
                                        itemsOriginalPrice: 0,
                                        itemsDiscountedPrice: itemsDiscountedPrice,
                                        itemsSavings: 0,
                                        deliveryChargeOriginal: deliveryChargeOriginal,
                                        handlingCharge: handlingCharge,
                                        grandTotal: grandTotal,
                                        totalSavings: 0,
                                        perStoreDropOffFees: perStoreDropOffFees,
                                        potentialPointsToEarn: billSummaryData
                                            ?.loyaltySummary?.potentialPointsToEarn
                                            ?.toDouble(),
                                        promoCode: billSummaryData?.promoCode,
                                        promoDiscount: promoDiscount,
                                        promoError: billSummaryData?.promoError,
                                        removeCoupon: () {
                                          setState(() {
                                            isCartLoading = true;
                                            promoCode = '';
                                          });
                                          context.read<PromoCodeBloc>().add(RemovePromoCode());
                                          context.read<GetUserCartBloc>().add(FetchUserCart(
                                                addressId: selectedAddress?.id,
                                                rushDelivery:
                                                    selectedDeliveryType == DeliveryType.rush,
                                                useWallet: _userWantsWallet,
                                                promoCode: promoCode ?? '',
                                                deliveryType: selectedOrderDeliveryType,
                                              ));
                                        },
                                        promoMode: billSummaryData?.promoApplied?.promoMode ?? '',
                                        discountAmount:
                                            billSummaryData?.promoApplied?.discountAmount ?? '',
                                        isRushDelivery: selectedOrderDeliveryType == 'pickup'
                                            ? false
                                            : (selectedDeliveryType == DeliveryType.rush),
                                        walletBalanceUsed: walletAmountUsed,
                                        freeDeliverySubtext: freeDeliverySubtext,
                                        riderTip: selectedOrderDeliveryType == 'pickup'
                                            ? null
                                            : billSummaryData?.riderTipAmount?.toDouble(),
                                        loyaltyDiscount: loyaltyDiscount,
                                        paymentMethod: selectedPaymentMethod,
                                        codCharges: billSummaryData?.codCharges?.toDouble(),
                                        currencyCode: stateData.isNotEmpty
                                            ? stateData.first.data?.currencyCode
                                            : null,
                                      ),
                                    ],
                                  ],
                                );
                              } else {
                                isCartLoading = false;
                                return _buildEmptyCartState();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomNavigationBar: BlocBuilder<GetUserCartBloc, GetUserCartState>(
                  builder: (context, state) {
                    bool hasItems = false;
                    // Update total amount from cart data
                    final cartDataFromState = _cartDataFromState(state);
                    if (cartDataFromState != null) {
                      stateData = cartDataFromState;
                    }
                    if (stateData.isNotEmpty) {
                      hasItems = stateData.first.data?.items != null &&
                          stateData.first.data!.items.isNotEmpty;
                    }

                    if (hasItems) {
                      final allItems =
                          stateData.isNotEmpty ? (stateData.first.data?.items ?? []) : [];
                      double itemsDiscountedPrice = 0.0;
                      if (stateData.isNotEmpty) {
                        final billSummaryData = stateData.first.data?.paymentSummary;
                        final eligibleItems = allItems;
                        itemsDiscountedPrice = billSummaryData?.itemsTotal?.toDouble() ?? 0.0;

                        // Use the delivery charge corresponding to the selected delivery speed
                        // so switching rush/regular reflects instantly without an API call.
                        final itemsTotal = billSummaryData?.itemsTotal?.toDouble() ?? 0.0;
                        final freeDeliveryAmount =
                            stateData.first.data?.deliveryZone?.freeDeliveryAmount?.toDouble();
                        final isFreeDelivery =
                            freeDeliveryAmount != null && itemsTotal >= freeDeliveryAmount;

                        final double deliveryCharge;
                        if (selectedOrderDeliveryType == 'pickup') {
                          deliveryCharge = 0.0;
                        } else if (selectedDeliveryType == DeliveryType.rush) {
                          deliveryCharge = billSummaryData?.rushDeliveryCharge ?? 0.0;
                        } else if (isFreeDelivery) {
                          deliveryCharge = 0.0;
                        } else {
                          deliveryCharge = billSummaryData?.regularDeliveryCharge ?? 0.0;
                        }

                        final double perStoreFees = selectedOrderDeliveryType == 'pickup'
                            ? 0.0
                            : (billSummaryData?.perStoreDropOffFee?.toDouble() ?? 0.0);

                        final double handlingFee = selectedOrderDeliveryType == 'pickup'
                            ? 0.0
                            : (billSummaryData?.handlingCharges?.toDouble() ?? 0.0);

                        double promoDiscount =
                            double.tryParse(billSummaryData?.promoDiscount ?? '0') ?? 0.0;

                        if (selectedOrderDeliveryType == 'pickup') {
                          itemsDiscountedPrice = eligibleItems.fold<double>(
                              0.0, (sum, item) => sum + _calculateCartItemTotalPrice(item));
                          final totalSubtotal = allItems.fold<double>(
                              0.0, (sum, item) => sum + _calculateCartItemTotalPrice(item));
                          if (totalSubtotal > 0) {
                            promoDiscount = (promoDiscount * itemsDiscountedPrice) / totalSubtotal;
                          }
                        }

                        final walletBal = billSummaryData?.walletBalance;
                        final totalWalletBalance = walletBal is num
                            ? walletBal.toDouble()
                            : (double.tryParse(walletBal?.toString() ?? '0.00') ?? 0.0);

                        final preWalletTotal = itemsDiscountedPrice +
                            deliveryCharge +
                            perStoreFees +
                            handlingFee -
                            promoDiscount +
                            (selectedTipAmount ?? 0.0);
                        final walletAmountUsedCalculated = _userWantsWallet
                            ? (totalWalletBalance < preWalletTotal
                                ? totalWalletBalance
                                : preWalletTotal)
                            : 0.0;
                        final calculated = preWalletTotal - walletAmountUsedCalculated;
                        totalAmount = calculated < 0.0 ? 0.0 : calculated;
                      } else {
                        totalAmount = 0.0;
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedOrderDeliveryType == 'delivery' && selectedAddress != null)
                            DeliveryAddressWidget(
                              selectedAddress: selectedAddress,
                              onTap: () {
                                _showAddressSelectionBottomSheet();
                              },
                            ),
                          _buildCheckoutSection(),
                        ],
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                )),
            if (isWholePageProgress) const WholePageProgress(),
          ],
        );
      },
    );
  }

  List<CartItem> _getProductsMissingRequiredAttachment(
    BuildContext context,
    List<CartItem> cartItems,
  ) {
    final attachmentState = context.read<AttachmentBloc>().state;
    final attachmentsMap = attachmentState is AttachmentLoaded
        ? attachmentState.attachments
        : <int, CartItemAttachment?>{};

    return cartItems.where((item) {
      // Only check products that require attachment
      if (item.product?.isAttachmentRequired == true) {
        if (item.product?.attachmentMode != 'required') {
          return false;
        } else {
          final attachment = attachmentsMap[item.productId ?? -1];
          return attachment == null;
        }
      } else {
        return false;
      }
    }).toList();
  }

  Future<bool> _showClearCartConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            context.tr('clearAllItems'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            context.tr('allItemsWillBeRemovedCannotBeUndone'),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(context.tr('no', fallback: 'No')),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                context.tr('yesClear', fallback: 'Yes, clear'),
                style: const TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _handleQuantityChanged(String itemId, int newQuantity) {
    log('On Quantity Change $newQuantity $itemId');
    setState(() {
      isCartLoading = true;
      _isCartSyncing = true;
    });
    context.read<UpdateItemQuantityBloc>().add(UpdateItemQuantityRequest(
          cartItemId: int.parse(itemId),
          quantity: newQuantity,
        ));
  }

  void _handleRemoveItem(String itemId) {
    setState(() {
      isCartLoading = true;
      _isCartSyncing = true;
    });
    context
        .read<RemoveItemFromCartBloc>()
        .add(RemoveItemFromCartRequest(cartItemId: int.parse(itemId)));
  }

  void _handleAddMoreItems() {
    // Navigate to products page or show add items dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('addMoreItemsTapped', fallback: 'Add more items tapped!'))),
    );
  }

  void _showAddressSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => AddressSelectionBottomSheet(
        selectedAddress: selectedAddress,
        deliveryZoneId: deliveryZoneId,
        onAddressSelected: (address) {
          if (selectedAddress == null || address.id != selectedAddress!.id) {
            setState(() {
              selectedAddress = address;
              selectedDeliveryType = DeliveryType.regular;
              isCartLoading = true;
            });
            // Save selected address to Hive
            HiveSelectedAddressHelper.setSelectedAddress(address);
            context.read<GetUserCartBloc>().add(FetchUserCart(
                  addressId: address.id,
                  useWallet: _userWantsWallet,
                  rushDelivery: selectedDeliveryType == DeliveryType.rush,
                  promoCode: promoCode,
                  deliveryType: selectedOrderDeliveryType,
                ));
          }
        },
      ),
    );
  }

  CartData? _getCurrentCartData() {
    final cartBlocState = context.read<GetUserCartBloc>().state;
    final cartModels = _cartDataFromState(cartBlocState);
    if (cartModels != null && cartModels.isNotEmpty) {
      return cartModels.first.data;
    }
    return null;
  }

  Map<String, dynamic> _getPickupCodStatus(CartData? cartData) {
    if (cartData == null) {
      return {'isPickupCodEnabled': false, 'nonCodPickupStores': <String>[]};
    }

    final storesMap = <int, Store>{};

    for (var item in cartData.items) {
      if (item.store != null && item.store!.id != null) {
        storesMap[item.store!.id!] = item.store!;
      }
    }

    for (var store in cartData.stores) {
      if (store.id != null) {
        storesMap.putIfAbsent(store.id!, () => store);
      }
    }

    final storesList = storesMap.values.toList();
    if (storesList.isEmpty) {
      return {'isPickupCodEnabled': false, 'nonCodPickupStores': <String>[]};
    }

    final nonCodPickupStores = storesList
        .where((s) => s.isPickupCodEnabled != true)
        .map((s) => s.name ?? 'Store')
        .toList();

    final isPickupCodEnabled = nonCodPickupStores.isEmpty;

    return {
      'isPickupCodEnabled': isPickupCodEnabled,
      'nonCodPickupStores': nonCodPickupStores,
    };
  }

  void _navigateToPaymentOptions() async {
    if (selectedAddress == null && selectedOrderDeliveryType != 'pickup') {
      ToastManager.show(
          context: context,
          message: context.tr('pleaseSelectADeliveryAddressFirst',
              fallback: 'Please select a delivery address first'),
          type: ToastType.error);
      return;
    }

    final cartData = _getCurrentCartData();
    final pickupCodInfo = _getPickupCodStatus(cartData);

    final paymentMethodType = await context.push(
      AppRoutes.paymentOptions,
      extra: {
        'totalAmount': totalAmount,
        'deliveryType': selectedOrderDeliveryType,
        'isPickupCodEnabled': pickupCodInfo['isPickupCodEnabled'],
        'nonCodPickupStores': pickupCodInfo['nonCodPickupStores'],
        'hasTip': (selectedTipAmount ?? 0.0) > 0,
        'codCharges': cartData?.paymentSummary?.codCharges?.toDouble(),
        'currencyCode': cartData?.currencyCode,
        'availablePaymentMethods': cartData?.availablePaymentMethods,
      },
    );

    if (paymentMethodType != null && paymentMethodType is PaymentMethodType) {
      final paymentMethod = PaymentConfig.getPaymentMethodByType(paymentMethodType);
      if (paymentMethod != null) {
        setState(() {
          selectedPaymentMethod = paymentMethod.id;
          selectedPaymentMethodType = paymentMethod.type;
        });
      }
    }
  }

  void _processOrder(BuildContext context) {
    final cartData = _getCurrentCartData();

    if (totalAmount <= 0) {
      _initiatePayment();
      return;
    }

    if (selectedPaymentMethod == null) {
      ToastManager.show(
          context: context,
          message:
              context.tr('selectPaymentMethod', fallback: 'Please select a payment method first'),
          type: ToastType.error);
      return;
    }

    if (selectedOrderDeliveryType == 'pickup' && selectedPaymentMethod == 'cod') {
      final pickupCodInfo = _getPickupCodStatus(cartData);
      final bool isPickupCodEnabled = pickupCodInfo['isPickupCodEnabled'] as bool;
      if (!isPickupCodEnabled) {
        final nonCodStores = pickupCodInfo['nonCodPickupStores'] as List<String>;
        final storesText = nonCodStores.isNotEmpty ? nonCodStores.join(', ') : 'selected store';
        ToastManager.show(
          context: context,
          message: 'The following store(s) do not support COD: $storesText',
          type: ToastType.error,
        );
        return;
      }
    }

    // Process payment based on method
    if (selectedPaymentMethod != 'cod' &&
        selectedPaymentMethodType != PaymentMethodType.flutterwave &&
        selectedPaymentMethodType != PaymentMethodType.xendit &&
        selectedPaymentMethodType != PaymentMethodType.mercadoPago) {
      context.read<PaymentBloc>().add(
            InitiatePaymentEvent(
                paymentMethodType: selectedPaymentMethodType!,
                amount: totalAmount,
                additionalData: {
                  'userId': Global.userData?.userId.toString() ?? '',
                  'customerName': Global.userData?.name.toString() ?? '',
                  'email': Global.userData?.email.toString() ?? '',
                  'phone': Global.userData?.mobile.toString() ?? '',
                  'deliveryAddress':
                      selectedAddress != null ? formatAddressFromModel(selectedAddress!) : '',
                  if (cartData?.currencyCode != null && cartData!.currencyCode!.isNotEmpty)
                    'currency': cartData.currencyCode,
                },
                addMoneyToWallet: false,
                context: context),
          );
    } else {
      _initiatePayment();
    }
  }

  void _initiatePayment({
    String? paymentId,
    String? signature,
    String? orderId,
  }) {
    final attachmentState = context.read<AttachmentBloc>().state;
    final attachments = attachmentState is AttachmentLoaded
        ? attachmentState.attachments
        : <int, List<CartItemAttachment>>{};
    final String? formattedScheduledDate =
        _scheduledDate != null ? DateFormat('yyyy-MM-dd').format(_scheduledDate!) : null;

    if (totalAmount <= 0) {
      context.read<CreateOrderBloc>().add(CreateOrderRequest(
            paymentType: 'wallet',
            addressId: selectedOrderDeliveryType == 'pickup' ? null : selectedAddress?.id,
            rushDelivery: selectedDeliveryType == DeliveryType.rush,
            promoCode: promoCode,
            paymentDetails: selectedPaymentMethod == 'razorpay'
                ? {
                    'razorpay_order_id': orderId,
                    'razorpay_signature': signature,
                    'transaction_id': paymentId,
                  }
                : (selectedPaymentMethodType != PaymentMethodType.flutterwave &&
                        selectedPaymentMethodType != PaymentMethodType.xendit &&
                        selectedPaymentMethodType != PaymentMethodType.mercadoPago)
                    ? {
                        'transaction_id': paymentId,
                      }
                    : {},
            orderNote: orderNote,
            attachments: attachments,
            useWallet: _userWantsWallet,
            deliveryType: selectedOrderDeliveryType,
            scheduledDate: formattedScheduledDate,
            scheduledTimeSlotLabel: _scheduledTimeSlot,
            scheduledSlotStartTime: _scheduledSlotStartTime,
            scheduledSlotEndTime: _scheduledSlotEndTime,
          ));
      return;
    }
    if (selectedPaymentMethod == null && selectedPaymentMethodType == null) {
      ToastManager.show(
        context: context,
        message: context.tr('paymentMethodNotSelected', fallback: 'Payment method not selected'),
        type: ToastType.error,
      );
      return;
    }

    context.read<CreateOrderBloc>().add(CreateOrderRequest(
          paymentType: selectedPaymentMethod!,
          addressId: selectedOrderDeliveryType == 'pickup' ? null : selectedAddress?.id,
          rushDelivery: selectedDeliveryType == DeliveryType.rush,
          promoCode: promoCode,
          paymentDetails: selectedPaymentMethod == 'razorpay'
              ? {
                  'razorpay_order_id': orderId,
                  'razorpay_signature': signature,
                  'transaction_id': paymentId,
                }
              : (selectedPaymentMethodType != PaymentMethodType.flutterwave &&
                      selectedPaymentMethodType != PaymentMethodType.xendit &&
                      selectedPaymentMethodType != PaymentMethodType.mercadoPago)
                  ? {
                      'transaction_id': paymentId,
                    }
                  : {},
          orderNote: orderNote,
          attachments: attachments,
          useWallet: _userWantsWallet,
          deliveryType: selectedOrderDeliveryType,
          scheduledDate: formattedScheduledDate,
          scheduledTimeSlotLabel: _scheduledTimeSlot,
          scheduledSlotStartTime: _scheduledSlotStartTime,
          scheduledSlotEndTime: _scheduledSlotEndTime,
        ));
  }

  Widget _buildCheckoutSection() {
    final dark = isDarkMode(context);
    final cartData = stateData.isNotEmpty ? stateData.first.data : null;
    final bool isCheckoutBlocked =
        cartData != null && (!cartData.isCheckoutAllowed || cartData.hasMixedCurrencies);

    return Container(
      padding: const EdgeInsets.only(top: 14, left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: dark ? AppTheme.mainDarkContainerBgColor : Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cartData != null && cartData.hasMixedCurrencies)
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Your cart contains stores with different currencies. Please checkout one currency at a time.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          (selectedAddress != null || selectedOrderDeliveryType == 'pickup')
              ? Row(
                  children: [
                    if (totalAmount > 0.0)
                      if (selectedPaymentMethod != null && selectedPaymentMethodType != null) ...[
                        // Selected payment method on the left
                        InkWell(
                          onTap:
                              (isCartLoading || _isCartSyncing) ? null : _navigateToPaymentOptions,
                          child: Opacity(
                            opacity: (isCartLoading || _isCartSyncing) ? 0.5 : 1.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    if (selectedPaymentMethod != null &&
                                        selectedPaymentMethodType != null) ...[
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: PaymentConfig.getPaymentMethodWidget(
                                            selectedPaymentMethod!,
                                            size: 24),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        (context.tr('payUsing', fallback: 'Pay Using'))
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          letterSpacing: 1.1,
                                          color: dark ? Colors.white54 : Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Icon(
                                        Icons.arrow_drop_up,
                                        color: dark ? Colors.white70 : Colors.black54,
                                      ),
                                    ]
                                  ],
                                ),
                                Text(
                                  PaymentConfig.getPaymentMethodName(selectedPaymentMethod!),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: dark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    const SizedBox(height: 5),
                    // Pay button on the right
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: CustomButton(
                          isDisabled: isCartLoading ||
                              _isCartSyncing ||
                              (stateData.isEmpty || (stateData.first.data?.items ?? []).isEmpty) ||
                              (stateData.isNotEmpty && stateData.first.success == false) ||
                              isCheckoutBlocked,
                          onPressed: () {
                            final bool isPlacingOrderNow =
                                totalAmount <= 0 || selectedPaymentMethod != null;
                            if (isPlacingOrderNow) {
                              final user = Global.userData;
                              // final bool emailOk = (user?.emailVerified ?? '').trim().isNotEmpty;
                              final bool mobileOk = (user?.mobileVerified ?? '').trim().isNotEmpty;
                              if (!mobileOk) {
                                ToastManager.show(
                                  context: context,
                                  message: context.tr(
                                      'pleaseVerifyEmailAndMobileBeforePlacingOrder',
                                      fallback:
                                          'Please verify your email and mobile number before placing the order.'),
                                  type: ToastType.error,
                                );
                                GoRouter.of(context).push(AppRoutes.userProfile);
                                return;
                              }
                            }

                            final cartData = stateData.isNotEmpty ? stateData.first.data : null;
                            final allCartItems = cartData?.items ?? [];
                            final cartItems = allCartItems;
                            final storeIds = cartItems
                                .map((item) => item.storeId)
                                .where((id) => id != null)
                                .cast<int>()
                                .toSet();

                            // Wallet amount used no longer needed for MOV checks

                            final billSummaryData = cartData?.paymentSummary;
                            final itemsTotal = (billSummaryData?.itemsTotal != null &&
                                    billSummaryData!.itemsTotal! > 0)
                                ? billSummaryData.itemsTotal!.toDouble()
                                : cartItems.fold<double>(
                                    0.0, (sum, item) => sum + _calculateCartItemTotalPrice(item));

                            final cartValidationError = CartValidation.validateCartForCheckout(
                              context: context,
                              cartTotal: itemsTotal,
                              totalItemsCount: cartItems.length,
                              storeIds: storeIds,
                              currencyCodes: cartData?.currencyCodes,
                              currencyCode: cartData?.currencyCode,
                            );

                            if (cartValidationError != null) {
                              ToastManager.show(
                                context: context,
                                message: cartValidationError,
                              );
                              return;
                            }

                            if (SettingsData.instance.deliveryBoy?.enableRiderTips == true &&
                                _tipError != null &&
                                selectedOrderDeliveryType != 'pickup') {
                              ToastManager.show(
                                context: context,
                                message: _tipError!,
                                type: ToastType.error,
                              );
                              return;
                            }

                            // ────────────────────────────────────────────────
                            final missingAttachmentProducts = _getProductsMissingRequiredAttachment(
                              context,
                              cartItems,
                            );

                            if (missingAttachmentProducts.isNotEmpty) {
                              final productNames = missingAttachmentProducts
                                  .map((p) => "• ${p.product?.name ?? 'Item'}")
                                  .join("\n");

                              ToastManager.show(
                                context: context,
                                message:
                                    "Attachment required for:\n$productNames\nPlease add the required file(s).",
                                type: ToastType.error,
                                duration: const Duration(seconds: 5),
                              );
                              return;
                            }

                            // All validations passed → proceed
                            if (totalAmount <= 0 || selectedPaymentMethod != null) {
                              _processOrder(context);
                            } else {
                              setState(() {
                                selectedPaymentMethod = 'razorpay';
                                selectedPaymentMethodType = PaymentMethodType.razorpay;
                              });
                              _processOrder(context);
                            }
                          },
                          child: (isCartLoading || _isCartSyncing)
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      context.tr('updating', fallback: 'Updating...'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  (totalAmount <= 0.0)
                                      ? (context.tr('placeOrder', fallback: 'Place Order'))
                                      : (context.tr('makePayment', fallback: 'Make Payment')),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: CustomButton(
                    isDisabled: isCartLoading || _isCartSyncing,
                    onPressed: () {
                      _navigateToAddAddress();
                    },
                    child: (isCartLoading || _isCartSyncing)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                context.tr('updating', fallback: 'Updating...'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            context.tr('chooseAddressForDelivery'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('yourCartIsEmpty', fallback: 'Your cart is empty'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('looksLikeYouHaventAddedAnythingYet',
                  fallback: "Looks like you haven't added anything yet"),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: CustomButton(
                onPressed: () {
                  context.go(AppRoutes.home);
                },
                child: Text(
                  context.tr('browseProducts', fallback: 'Browse products'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AddressListData? _getAddressFromHive() {
    if (HiveSelectedAddressHelper.hasSelectedAddress()) {
      final saved = HiveSelectedAddressHelper.getSelectedAddress();
      if (saved != null) {
        return AddressListData(
          id: saved.id,
          userId: saved.userId,
          addressLine1: saved.addressLine1,
          addressLine2: saved.addressLine2,
          city: saved.city,
          landmark: saved.landmark,
          state: saved.state,
          zipcode: saved.zipcode,
          mobile: saved.mobile,
          addressType: saved.addressType,
          country: saved.country,
          countryCode: saved.countryCode,
          latitude: saved.latitude,
          longitude: saved.longitude,
          createdAt: saved.createdAt,
          updatedAt: saved.updatedAt,
        );
      }
    }
    return null;
  }

  void _navigateToAddAddress() async {
    await GoRouter.of(context).push(
      AppRoutes.locationPicker,
      extra: {
        'isFromAddressPage': true,
        'isEdit': false,
        'isFromCartPage': true,
        'deliveryZoneId': deliveryZoneId
      },
    );
    if (mounted) {
      context.read<GetAddressListBloc>().add(FetchUserAddressList(deliveryZoneId: deliveryZoneId));
      setState(() {
        selectedAddress = _getAddressFromHive();
      });
      _refreshCart(silent: true);
    }
  }

  double _calculateCartItemTotalPrice(CartItem item) {
    final double regularPrice = item.variant?.price ?? 0.0;
    final double salePrice = item.variant?.specialPrice ?? 0.0;

    double localTotalAddon = 0.0;
    if (item.addons.isNotEmpty) {
      localTotalAddon = item.addons.fold<double>(
        0.0,
        (total, addon) => total + (addon.price ?? 0.0),
      );
    }

    final int displayQty = item.quantity ?? 1;
    final double totalRegular = (regularPrice * displayQty) + (localTotalAddon * displayQty);
    final double totalSale = (salePrice > 0 ? salePrice * displayQty : regularPrice * displayQty) +
        (localTotalAddon * displayQty);

    final bool hasRealDiscount =
        salePrice > 0 && salePrice < regularPrice && (regularPrice - salePrice).abs() > 0.01;

    return hasRealDiscount ? totalSale : totalRegular;
  }

  bool get isPickupAvailable {
    if (stateData.isEmpty) return true;
    final allItems = stateData.first.data?.items ?? [];
    return allItems.every((item) => item.store?.allowsPickup == true);
  }

  List<String> get blockedStores {
    if (stateData.isEmpty) return [];
    final allItems = stateData.first.data?.items ?? [];
    return allItems
        .where((item) => item.store?.allowsPickup != true)
        .map((item) => item.store?.name)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  Widget _buildOffersAndFreeDeliverySection({
    required bool showFreeDelivery,
    required bool isFreeDelivery,
    required double freeDeliveryAmount,
    required double itemsTotal,
    required double itemsDiscountedPrice,
    required CartData? cartData,
    required PaymentSummary? billSummaryData,
  }) {
    const primaryColor = AppTheme.primaryColor;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final neededAmount = freeDeliveryAmount - itemsTotal;
    final progress =
        freeDeliveryAmount > 0 ? (itemsTotal / freeDeliveryAmount).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (billSummaryData?.loyaltySummary?.isLoyaltyEnabled == true &&
              billSummaryData?.loyaltySummary?.minOrderValueToRedeem != null &&
              (billSummaryData?.loyaltySummary?.minOrderValueToRedeem ?? 0.0) > 0 &&
              (billSummaryData?.loyaltySummary?.userPointsBalance ?? 0) > 0) ...[
            LoyaltyPointsProgressWidget(
              currencyCode: cartData?.currencyCode,
              itemsTotal: itemsDiscountedPrice,
              minOrderValueToRedeem: billSummaryData?.loyaltySummary?.minOrderValueToRedeem ?? 0.0,
              userPointsBalance: billSummaryData?.loyaltySummary?.userPointsBalance ?? 0,
              potentialPointsToEarn: billSummaryData?.loyaltySummary?.potentialPointsToEarn ?? 0.0,
              isLoyaltyPointsUsed: cartData?.useLoyaltyPoints ?? false,
              onTap: () {
                final currentUsed = cartData?.useLoyaltyPoints ?? false;
                setState(() {
                  isCartLoading = true;
                });
                context.read<GetUserCartBloc>().add(FetchUserCart(
                      addressId: selectedAddress?.id,
                      rushDelivery: selectedDeliveryType == DeliveryType.rush,
                      useWallet: _userWantsWallet,
                      promoCode: promoCode,
                      deliveryType: selectedOrderDeliveryType,
                      useLoyaltyPoints: !currentUsed,
                    ));
              },
            ),
            SizedBox(height: 8.h),
          ],
          if (showFreeDelivery) ...[
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isFreeDelivery
                    ? (dark ? const Color(0xFF133E2B) : const Color(0xFFE8F5E9))
                    : (dark ? const Color(0xFF0F3570) : const Color(0xFFEBF3FC)),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isFreeDelivery
                      ? Colors.green.withValues(alpha: 0.3)
                      : (dark ? const Color(0xFF1E4C8A) : primaryColor.withValues(alpha: 0.2)),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: dark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            if (!dark)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_shipping,
                          color: isFreeDelivery ? Colors.green : primaryColor,
                          size: 22.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isFreeDelivery ? 'FREE Delivery Unlocked!' : 'Get FREE delivery',
                              style: TextStyle(
                                fontSize: isTablet(context) ? 18 : 14.sp,
                                fontWeight: FontWeight.bold,
                                color: isFreeDelivery
                                    ? (dark ? Colors.green[300] : Colors.green[800])
                                    : (dark ? Colors.white : primaryColor),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              isFreeDelivery
                                  ? 'Congratulations! You get free delivery.'
                                  : 'Add products worth ${MoneyDisplay.format(neededAmount > 0 ? neededAmount : 0, currencyCode: cartData?.currencyCode)} more',
                              style: TextStyle(
                                fontSize: isTablet(context) ? 14 : 11.5.sp,
                                fontWeight: FontWeight.w500,
                                color: isFreeDelivery
                                    ? (dark ? Colors.green[200] : Colors.green[700])
                                    : (dark
                                        ? Colors.white70
                                        : primaryColor.withValues(alpha: 0.85)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0.0, end: progress),
                      builder: (context, animatedValue, child) {
                        return LinearProgressIndicator(
                          value: animatedValue,
                          minHeight: 5.h,
                          backgroundColor: isFreeDelivery
                              ? Colors.green.withValues(alpha: 0.2)
                              : (dark ? Colors.white24 : primaryColor.withValues(alpha: 0.15)),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFreeDelivery ? Colors.green : primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
          ],
          GestureDetector(
            onTap: () async {
              final result = await GoRouter.of(context).push(AppRoutes.promoCode, extra: {
                'cartAmount': stateData.first.data?.paymentSummary?.itemsTotal?.toDouble() ?? 0.0,
                'deliveryCharges':
                    stateData.first.data?.paymentSummary?.totalDeliveryCharges?.toDouble() ?? 0.0,
              });

              if (result != null && result is String && result.isNotEmpty) {
                if (mounted) {
                  context.read<CartUIBloc>().add(SetCartLoading(true));
                  promoCode = result;
                  context.read<GetUserCartBloc>().add(FetchUserCart(
                        addressId: selectedAddress?.id,
                        promoCode: promoCode,
                        rushDelivery: selectedDeliveryType == DeliveryType.rush,
                        useWallet: _userWantsWallet,
                        deliveryType: selectedOrderDeliveryType,
                      ));
                }
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          TablerIcons.rosette_discount_filled,
                          color: const Color(0xFF149400),
                          size: isTablet(context) ? 18.r : 24.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('viewCouponOffers', fallback: 'View Coupon & Offers'),
                                style: TextStyle(
                                  fontSize: isTablet(context) ? 20 : 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (promoCode != null && promoCode!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('couponCodeApplied', fallback: "Coupon code applied"),
                                  style: TextStyle(
                                    fontSize: isTablet(context) ? 15 : 11.sp,
                                    color: const Color(0xFF149400),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20.r,
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

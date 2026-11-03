import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:intl/intl.dart';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/save_for_later_page/bloc/save_for_later_bloc/save_for_later_event.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_dotted_divider.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:open_filex/open_filex.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../config/helper.dart';
import '../../../services/user_cart/cart_validation.dart';
import '../repo/cart_repository.dart';
import '../../../utils/widgets/delivery_slot_bottom_sheet.dart';
import '../../../utils/widgets/custom_toast.dart';
import '../../../utils/widgets/debounce_function.dart';
import '../../../utils/widgets/price_utils.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import '../bloc/attachment/attachment_bloc.dart';
import '../model/get_cart_model.dart';
import 'addon_edit_bottom_sheet.dart';
import 'package:path/path.dart' as path;

class CartItemAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;

  CartItemAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
  });
}

class StoreGroup {
  final String name;
  final String? slug;
  final String? logo;
  final bool? storeStatus;
  final String? pickupInstructions;
  final ScheduledDeliveryInfo? scheduledDeliveryInfo;
  final List<CartItem> items;

  StoreGroup({
    required this.name,
    required this.slug,
    required this.logo,
    this.storeStatus = false,
    this.pickupInstructions,
    this.scheduledDeliveryInfo,
    required this.items,
  });
}

List<StoreGroup> groupCartItemsByStore(List<CartItem> items, {List<Store>? stores}) {
  Map<String, StoreGroup> groupedItems = {};

  for (var item in items) {
    String storeKey = item.store?.name ?? 'Unknown Store';
    if (!groupedItems.containsKey(storeKey)) {
      ScheduledDeliveryInfo? schedInfo = item.store?.scheduledDeliveryInfo;
      if (schedInfo == null && stores != null && stores.isNotEmpty) {
        final match = stores.firstWhereOrNull((s) => s.id == item.store?.id || s.slug == item.store?.slug);
        schedInfo = match?.scheduledDeliveryInfo;
      }

      groupedItems[storeKey] = StoreGroup(
        name: storeKey,
        slug: item.store?.slug,
        logo: item.product?.image,
        storeStatus: item.store?.status?.isOpen,
        pickupInstructions: item.store?.pickupInstructions,
        scheduledDeliveryInfo: schedInfo,
        items: [],
      );
    }
    groupedItems[storeKey]!.items.add(item);
  }

  return groupedItems.values.toList();
}

/// Recomputes the cartKey for a server-side [CartItem] so it matches.
String _cartKeyFor(CartItem item) {
  final String productId = (item.product?.id ?? 0).toString();
  final String variantId = (item.productVariantId ?? 0).toString();
  if (item.addons.isEmpty) return '${productId}_$variantId';
  final ids = item.addons.map((a) => a.addonItemId ?? 0).where((id) => id > 0).toList()..sort();
  if (ids.isEmpty) return '${productId}_$variantId';
  return '${productId}_${variantId}_${ids.join('-')}';
}

class CartWidget extends StatelessWidget {
  final List<CartItem> items;
  final List<Store>? stores;
  final String deliveryTime;
  final Function(String itemId, int newQuantity) onQuantityChanged;
  final Function(String itemId) onRemoveItem;
  final VoidCallback? onAddMoreItems;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final TextStyle? headerTextStyle;
  final TextStyle? deliveryTextStyle;
  final Color? quantityButtonColor;
  final Color? priceColor;
  final Color? originalPriceColor;
  final BorderRadius? borderRadius;
  final int? totalItem;
  final bool isCartUpdating;

  final int? addressId;
  final String? promoCode;
  final bool? rushDelivery;
  final bool? useWallet;
  final String? deliveryType;
  final String? currencyCode;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final int? selectedTimeSlotId;
  final void Function(DateTime? date, String? timeSlot, int? slotId, String? startTime, String? endTime)
      onScheduledDateTimeChanged;

  const CartWidget({
    super.key,
    required this.items,
    this.stores,
    required this.deliveryTime,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    required this.selectedDate,
    required this.selectedTimeSlot,
    this.selectedTimeSlotId,
    this.currencyCode,
    required this.onScheduledDateTimeChanged,
    this.onAddMoreItems,
    this.padding,
    this.backgroundColor,
    this.headerTextStyle,
    this.deliveryTextStyle,
    this.quantityButtonColor,
    this.priceColor,
    this.originalPriceColor,
    this.borderRadius,
    this.totalItem,
    this.isCartUpdating = false,
    this.addressId,
    this.promoCode,
    this.rushDelivery,
    this.useWallet,
    this.deliveryType,
  });

  @override
  Widget build(BuildContext context) {
    // Group items by store
    final groupedStores = groupCartItemsByStore(items, stores: stores);
    return Column(
      children: groupedStores.map((storeGroup) {
        return Container(
          margin: EdgeInsets.only(bottom: 9.h),
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              StoreCartSection(
                storeName: storeGroup.name,
                items: storeGroup.items,
                storeStatus: storeGroup.storeStatus ?? false,
                deliveryTime: deliveryTime,
                onQuantityChanged: onQuantityChanged,
                onRemoveItem: onRemoveItem,
                onAddMoreItems: onAddMoreItems,
                padding: padding,
                backgroundColor: backgroundColor,
                headerTextStyle: headerTextStyle,
                deliveryTextStyle: deliveryTextStyle,
                quantityButtonColor: quantityButtonColor,
                priceColor: priceColor,
                originalPriceColor: originalPriceColor,
                borderRadius: borderRadius,
                totalItems: totalItem,
                isCartUpdating: isCartUpdating,
                addressId: addressId,
                promoCode: promoCode,
                useWallet: useWallet,
                rushDelivery: rushDelivery,
                deliveryType: deliveryType,
                pickupInstructions: storeGroup.pickupInstructions,
                storeId: storeGroup.items.isNotEmpty ? storeGroup.items.first.store?.id : null,
                scheduledDeliveryInfo: storeGroup.scheduledDeliveryInfo ??
                    (storeGroup.items.isNotEmpty ? storeGroup.items.first.store?.scheduledDeliveryInfo : null),
                hasMultipleStores: groupedStores.length > 1,
                selectedDate: selectedDate,
                selectedTimeSlot: selectedTimeSlot,
                selectedTimeSlotId: selectedTimeSlotId,
                currencyCode: currencyCode,
                onScheduledDateTimeChanged: onScheduledDateTimeChanged,
              ),
              buildDottedLine(context),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    if (AppHelpers.systemVendorTypeIsSingle) {
                      GoRouter.of(context).go(AppRoutes.home);
                    } else {
                      GoRouter.of(context).push(
                        AppRoutes.nearbyStoreDetails,
                        extra: {
                          'store-slug': storeGroup.slug,
                          'store-name': storeGroup.name,
                        },
                      );
                    }
                  },
                  borderRadius:
                      BorderRadius.only(bottomLeft: Radius.circular(16.r), bottomRight: Radius.circular(16.r)),
                  child: Ink(
                    child: Opacity(
                      opacity: (storeGroup.storeStatus == false) ? 0.3 : 1,
                      child: SizedBox(
                        height: 55,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TablerIcons.circle_plus,
                              size: isTablet(context) ? 28 : 18.r,
                              color: (storeGroup.storeStatus == false)
                                  ? Theme.of(context).colorScheme.outlineVariant
                                  : AppTheme.primaryColor,
                            ),
                            SizedBox(
                              width: 5.w,
                            ),
                            Text(
                              context.tr('addMoreItems'),
                              style: TextStyle(
                                  color: (storeGroup.storeStatus == false)
                                      ? Theme.of(context).colorScheme.outlineVariant
                                      : AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet(context) ? 20 : 14.sp),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Store-specific cart section widget
class StoreCartSection extends StatefulWidget {
  final String storeName;
  final List<CartItem> items;
  final bool storeStatus;
  final String deliveryTime;
  final Function(String itemId, int newQuantity) onQuantityChanged;
  final Function(String itemId) onRemoveItem;
  final VoidCallback? onAddMoreItems;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final TextStyle? headerTextStyle;
  final TextStyle? deliveryTextStyle;
  final Color? quantityButtonColor;
  final Color? priceColor;
  final Color? originalPriceColor;
  final BorderRadius? borderRadius;
  final int? totalItems;
  final bool isCartUpdating;

  final int? addressId;
  final String? promoCode;
  final bool? rushDelivery;
  final bool? useWallet;
  final String? deliveryType;
  final int? storeId;
  final String? pickupInstructions;
  final ScheduledDeliveryInfo? scheduledDeliveryInfo;
  final bool hasMultipleStores;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final int? selectedTimeSlotId;
  final String? currencyCode;
  final void Function(DateTime? date, String? timeSlot, int? slotId, String? startTime, String? endTime)
      onScheduledDateTimeChanged;

  const StoreCartSection({
    super.key,
    required this.storeName,
    required this.items,
    required this.storeStatus,
    required this.deliveryTime,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    this.onAddMoreItems,
    this.padding,
    this.backgroundColor,
    this.headerTextStyle,
    this.deliveryTextStyle,
    this.quantityButtonColor,
    this.priceColor,
    this.originalPriceColor,
    this.borderRadius,
    this.totalItems,
    this.isCartUpdating = false,
    this.addressId,
    this.promoCode,
    this.rushDelivery,
    this.useWallet,
    this.deliveryType,
    this.storeId,
    this.pickupInstructions,
    this.scheduledDeliveryInfo,
    this.hasMultipleStores = false,
    required this.selectedDate,
    required this.selectedTimeSlot,
    this.selectedTimeSlotId,
    this.currencyCode,
    required this.onScheduledDateTimeChanged,
  });

  @override
  State<StoreCartSection> createState() => _StoreCartSectionState();
}

class _StoreCartSectionState extends State<StoreCartSection> {
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 500));
  Timer? _apiThrottleTimer;

  @override
  void didUpdateWidget(StoreCartSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasMultipleStores) {
      if (widget.selectedDate != null || widget.selectedTimeSlot != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onScheduledDateTimeChanged(null, null, null, null, null);
        });
      }
    }
    if (widget.deliveryType == 'pickup' && oldWidget.deliveryType != 'pickup' && widget.selectedDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onScheduledDateTimeChanged(null, null, null, null, null);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('pickupOrder', fallback: 'Pickup Order')),
            content: Text(context.tr('pickupScheduleWarning', fallback: 'Pickup does not support scheduled delivery dates.')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('ok', fallback: 'OK')),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _handleScheduleDeliveryTap() async {

    if (widget.deliveryType == 'pickup') {
      ToastManager.show(
        context: context,
        message: context.tr('pickupScheduleWarning', fallback: 'Pickup does not support scheduled delivery dates.'),
        type: ToastType.warning,
      );
      return;
    }

    if (widget.hasMultipleStores) {
      ToastManager.show(
        context: context,
        message: context.tr('singleStoreScheduleWarning', fallback: 'To place a scheduled order, please checkout from a single store.'),
        type: ToastType.warning,
      );
      return;
    }

    final info = widget.scheduledDeliveryInfo;
    if (info == null || info.isEnabled == false) {
      ToastManager.show(
        context: context,
        message: context.tr('storeScheduleUnavailable', fallback: 'Schedule delivery is not available for this Store'),
        type: ToastType.warning,
      );
      return;
    }

    final storeId = widget.storeId ?? widget.items.first.store?.id;

    final result = await DeliverySlotBottomSheet.show(
      context: context,
      initialDate: widget.selectedDate,
      initialTimeSlot: widget.selectedTimeSlot,
      initialTimeSlotId: widget.selectedTimeSlotId,
      maxDays: info.maxDays ?? 30,
      availableDays: info.availableDays,
      onFetchSlots: (date) => CartRepository().getScheduledDeliverySlots(
        storeId: storeId!,
        date: date,
      ),
    );

    if (result != null) {
      widget.onScheduledDateTimeChanged(result.date, result.timeSlot, result.slotId, result.startTime, result.endTime);
    }
  }

  @override
  void dispose() {
    _apiThrottleTimer?.cancel();
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPickupInstructions = widget.deliveryType == 'pickup' &&
        widget.pickupInstructions != null &&
        widget.pickupInstructions!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStoreHeader(context),
        if (hasPickupInstructions) ...[
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: isDarkMode(context) ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4.w,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  TablerIcons.info_circle,
                                  size: isTablet(context) ? 22.r : 16.r,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  context.tr('pickupInstructions'),
                                  style: TextStyle(
                                    fontSize: isTablet(context) ? 16.sp : 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.pickupInstructions!,
                              style: TextStyle(
                                fontSize: isTablet(context) ? 15.sp : 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.tertiary,
                                fontFamily: AppTheme.fontFamily,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                ),
              ),
            ),
          ),
        ],
        ...widget.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: _buildCartItem(context, item),
            )),
      ],
    );
  }

  Widget _buildStoreHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode(context) ? Theme.of(context).colorScheme.secondary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppHelpers.systemVendorTypeIsSingle ? (context.tr('items', fallback: 'Items')) : widget.storeName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  style: widget.headerTextStyle ??
                      TextStyle(
                        fontSize: isTablet(context) ? 24 : 15.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamily,
                      ),
                ),
                if (widget.storeStatus) ...[
                  SizedBox(height: 2.h),
                  Text(
                    context.tr('nProducts', positionalArgs: [widget.items.length], fallback: "${widget.items.length} Product${widget.items.length != 1 ? 's' : ''}"),
                    style: widget.deliveryTextStyle ??
                        TextStyle(
                          fontSize: isTablet(context) ? 18 : 12.sp,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppTheme.fontFamily,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          if (!widget.storeStatus)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  TablerIcons.x,
                  color: AppTheme.errorColor,
                  size: 16,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  context.tr('currentlyClosed', fallback: 'Currently closed'),
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ],
            )
          else if (widget.deliveryType != 'pickup' &&
              (widget.scheduledDeliveryInfo == null || widget.scheduledDeliveryInfo?.isEnabled != false))
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _handleScheduleDeliveryTap,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      TablerIcons.calendar,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (widget.selectedDate != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${DateFormat('dd-MMM-yy').format(widget.selectedDate!)}${widget.selectedTimeSlot != null ? ' · ${widget.selectedTimeSlot}' : ''}',
                        style: TextStyle(
                          fontSize: isTablet(context) ? 14 : 9.sp,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      GestureDetector(
                        onTap: () {
                          widget.onScheduledDateTimeChanged(null, null, null, null, null);
                        },
                        child: const Icon(
                          TablerIcons.x,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.horizontal,

      // Backgrounds (same as before)
      background: Container(
        color: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.bookmark_add, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(
              context.tr('saveForLater', fallback: "Save for Later"),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: AppTheme.errorColor,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              context.tr('delete', fallback: "Delete"),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.delete, color: Colors.white, size: 28),
          ],
        ),
      ),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Save for Later → trigger API, but don't dismiss yet
          context.read<SaveForLaterBloc>().add(SaveForLaterRequest(
                cartItemId: item.id!,
                cartItemName: item.product!.name!,
              ));
          return false; // Don't dismiss
        }

        if (direction == DismissDirection.endToStart) {
          // Show confirmation dialog
          final bool? shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(context.tr('removeItem', fallback: "Remove item")),
                content: Text(
                  context.tr('areYouSureYouWantToRemoveItemFromCart', positionalArgs: [item.product!.name!], fallback: "Are you sure you want to remove ${item.product!.name} from cart?"),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.tr('cancel', fallback: "Cancel")),
                  ),
                  CustomButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.tr('delete', fallback: "Delete")),
                  ),
                ],
              );
            },
          );

          if (shouldDelete == true) {
            if (context.mounted) {
              context.read<CartBloc>().add(RemoveFromCart(
                  cartKey: _cartKeyFor(item),
                  context: context,
                  addressId: widget.addressId,
                  promoCode: widget.promoCode,
                  useWallet: widget.useWallet,
                  rushDelivery: widget.rushDelivery,
                  isFromCartPage: true));
            }
            // Trigger remove API
            widget.onRemoveItem(item.id.toString());
            return false; // Don't dismiss yet — wait for Bloc success
          }
        }

        return false;
      },

      // REMOVE onDismissed completely → we control dismissal manually

      child: Opacity(
        opacity: (widget.storeStatus == false) ? 0.3 : 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: isDarkMode(context) ? Colors.grey.shade800 : Colors.grey[200]!, width: 0.5)),
          ),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        GoRouter.of(context).push(
                          AppRoutes.productDetailPage,
                          extra: {'productSlug': item.product!.slug},
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductImage(item.product!.image!),
                          SizedBox(width: 10.w),
                          Expanded(child: _buildProductInfo(item)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  _buildQuantityControl(item),
                  SizedBox(width: 12.w),
                  _buildPriceSection(item),
                ],
              ),
              if (item.product!.isAttachmentRequired!) ...[
                const SizedBox(height: 12),
                _buildAttachmentsSection(item),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomImageContainer(
          imagePath: imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildProductInfo(CartItem item) {
    final theme = Theme.of(context);

    final String variantTitle = item.variant?.title ?? '';
    final String addonsText = item.addons.map((a) => a.item?.title ?? '').where((t) => t.isNotEmpty).join(', ');
    final String description =
        addonsText.isEmpty ? variantTitle : (variantTitle.isEmpty ? addonsText : '$variantTitle, $addonsText');

    return SizedBox(
      width: 125.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.product!.name!,
            style: TextStyle(
                fontSize: isTablet(context) ? 20 : 12.sp, fontWeight: FontWeight.w500, fontFamily: AppTheme.fontFamily),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (description.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: isTablet(context) ? 15 : 10.sp,
                  fontWeight: FontWeight.w300,
                  fontFamily: AppTheme.fontFamily,
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.75),
                  height: 1.3,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (item.addons.isNotEmpty || item.variant!.isAddons == true) ...[
            SizedBox(height: 6.h),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showAddonEditBottomSheet(
                    context: context,
                    cartItem: item,
                    addressId: widget.addressId,
                    promoCode: widget.promoCode,
                    rushDelivery: widget.rushDelivery,
                    useWallet: widget.useWallet,
                    currencyCode: widget.currencyCode,
                  );
                },
                borderRadius: BorderRadius.circular(4.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('edit', fallback: 'Edit'),
                        style: TextStyle(
                          fontSize: isTablet(context) ? 15 : 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.arrow_right,
                        size: isTablet(context) ? 18 : 14.r,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item) {
    final String cartKey = _cartKeyFor(item);

    return BlocSelector<CartBloc, CartState, int?>(
      selector: (state) {
        if (state is CartLoaded) {
          final localItem = state.items.firstWhereOrNull(
            (i) => i.cartKey == cartKey,
          );
          return localItem?.quantity;
        }
        return null; // will fallback to item.quantity
      },
      builder: (context, localQty) {
        // Fallback to server/API quantity if local not found yet
        final displayQty = localQty ?? item.quantity ?? 1;

        if (item.variant!.stock! <= 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              context.tr('outOfStock'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Minus / Remove
                  _buildQtyBtn(
                    icon: Icons.remove,
                    onTap: widget.isCartUpdating
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            if (displayQty <= item.product!.quantityStepSize!) {
                              // Remove from local
                              context.read<CartBloc>().add(RemoveFromCart(
                                  cartKey: cartKey,
                                  context: context,
                                  addressId: widget.addressId,
                                  promoCode: widget.promoCode,
                                  useWallet: widget.useWallet,
                                  rushDelivery: widget.rushDelivery,
                                  isFromCartPage: true));
                              // Trigger server remove
                            } else {
                              final newQty = displayQty - item.product!.quantityStepSize!;
                              log('Quantity Change $newQty');
                              // Update local
                              context.read<CartBloc>().add(UpdateCartQty(
                                  cartKey: cartKey,
                                  quantity: newQty,
                                  cartItemId: item.id,
                                  context: context,
                                  addressId: widget.addressId,
                                  promoCode: widget.promoCode,
                                  useWallet: widget.useWallet,
                                  rushDelivery: widget.rushDelivery,
                                  isFromCartPage: true));
                            }
                          },
                  ),

                  // Quantity display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$displayQty',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Plus
                  _buildQtyBtn(
                    icon: Icons.add,
                    onTap: widget.isCartUpdating
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            final newQty = displayQty + item.product!.quantityStepSize!;
                            // Update local
                            final error = CartValidation.validateProductAddToCart(
                              context: context,
                              requestedQuantity: displayQty + item.product!.quantityStepSize!,
                              minQty: item.product!.minimumOrderQuantity!,
                              maxQty: item.product!.totalAllowedQuantity!,
                              stock: item.variant!.stock!,
                              isStoreOpen: item.product!.storeStatus!.isOpen!,
                            );

                            if (error != null) {
                              ToastManager.show(context: context, message: error, type: ToastType.error);
                              return;
                            }

                            // Plain quantity bump in every case — the customize sheet
                            context.read<CartBloc>().add(UpdateCartQty(
                                cartKey: cartKey,
                                quantity: newQty,
                                cartItemId: item.id,
                                context: context,
                                addressId: widget.addressId,
                                promoCode: widget.promoCode,
                                useWallet: widget.useWallet,
                                rushDelivery: widget.rushDelivery,
                                isFromCartPage: true));
                            // Trigger server update
                          },
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: widget.isCartUpdating
                  ? Padding(
                      key: const ValueKey('cart-updating'),
                      padding: EdgeInsets.only(top: 4.h),
                      child: SizedBox(
                        width: 12.r,
                        height: 12.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('cart-idle'),
                      height: 16,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQtyBtn({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.grey : AppTheme.primaryColor,
        ),
      ),
    );
  }

  double calculateTotalAddonPrice(CartItem item) {
    if (item.addons.isEmpty) {
      return 0.0;
    }

    return item.addons.fold<double>(
      0.0,
      (total, addon) => total + (addon.price ?? 0.0),
    );
  }

  Widget _buildPriceSection(CartItem item) {
    final String cartKey = _cartKeyFor(item);

    return BlocSelector<CartBloc, CartState, int?>(
      selector: (state) {
        if (state is CartLoaded) {
          final localItem = state.items.firstWhereOrNull(
            (i) => i.cartKey == cartKey,
          );
          return localItem?.quantity;
        }
        return null;
      },
      builder: (context, localQty) {
        // Use local quantity if available, fallback to server quantity
        final displayQty = localQty ?? item.quantity ?? 1;

        // Parse prices safely
        final double regularPrice = item.variant!.price ?? 0.0;
        final double salePrice = item.variant!.specialPrice ?? 0.0;

        final double localTotalAddon = calculateTotalAddonPrice(item);

        // final double totalRegular = (item.totalItemPrice != null && item.totalItemPrice!

        final double totalRegular = (regularPrice * displayQty) + (localTotalAddon * displayQty);

        // final double totalSale = (item.totalItemSpecialPrice != null && item.totalItemSpecialPrice!

        final double totalSale =
            (salePrice > 0 ? salePrice * displayQty : regularPrice * displayQty) + (localTotalAddon * displayQty);

        // What price to show as main (bold) price
        final bool hasRealDiscount =
            salePrice > 0 && salePrice < regularPrice && (regularPrice - salePrice).abs() > 0.01;

        final double mainTotal = hasRealDiscount ? totalSale : totalRegular;
        final String? itemCurrency = item.variant?.currencyCode ?? item.product?.currencyCode ?? widget.currencyCode;

        final String? directFormattedMain = (displayQty == 1 && localTotalAddon == 0)
            ? (hasRealDiscount
                ? (item.variant?.formattedSpecialPrice != null && item.variant!.formattedSpecialPrice!.isNotEmpty
                    ? item.variant!.formattedSpecialPrice
                    : null)
                : (item.variant?.formattedPrice != null && item.variant!.formattedPrice!.isNotEmpty
                    ? item.variant!.formattedPrice
                    : null))
            : null;
        final String? directFormattedRegular = (displayQty == 1 && localTotalAddon == 0)
            ? (item.variant?.formattedPrice != null && item.variant!.formattedPrice!.isNotEmpty
                ? item.variant!.formattedPrice
                : null)
            : null;

        final String formattedMain = PriceUtils.formatPrice(
          mainTotal,
          formatted: directFormattedMain,
          currencyCode: itemCurrency,
        );
        final String formattedRegular = PriceUtils.formatPrice(
          totalRegular,
          formatted: directFormattedRegular,
          currencyCode: itemCurrency,
        );

        return SizedBox(
          width: isTablet(context) ? 80 : 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show struck-through original price ONLY when there's real discount
              if (hasRealDiscount) ...[
                AdaptivePriceText(
                  formattedRegular,
                  style: TextStyle(
                    fontSize: isTablet(context) ? 16 : 11.sp,
                    fontFamily: AppTheme.fontFamily,
                    color: widget.originalPriceColor ?? Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey[600],
                    decorationThickness: 1.5,
                  ),
                  minFontSize: isTablet(context) ? 12 : 8.5.sp,
                  textAlign: TextAlign.end,
                ),
                SizedBox(height: 2.h),
              ],

              // Main price (bold) – use sale price when discounted, regular otherwise
              AdaptivePriceText(
                formattedMain,
                style: TextStyle(
                  fontSize: isTablet(context) ? 20 : 14.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                ),
                minFontSize: isTablet(context) ? 14 : 10.sp,
                textAlign: TextAlign.end,
              ),
            ],
          ),
        );
      },
    );
  }

  List<CartItemAttachment> _getAttachmentsForItem(CartItem item, AttachmentState state) {
    // Use the same key logic everywhere
    final key = item.productId ?? item.id;

    if (key == null) {
      log('Warning: Both productId and id are null');
      return [];
    }

    final attachmentsList = state.attachments[key] ?? [];

    // Better debug logs
    log('Looking for key: $key | Found ${attachmentsList.length} attachment(s)');

    if (attachmentsList.isNotEmpty) {
      log('Attachment names: ${attachmentsList.map((a) => a.fileName).toList()}');
    }

    return attachmentsList;
  }

  bool _hasAttachments(CartItem item, AttachmentState state) {
    return _getAttachmentsForItem(item, state).isNotEmpty;
  }

  Widget _buildAttachmentsSection(CartItem item) {
    return BlocBuilder<AttachmentBloc, AttachmentState>(
      builder: (context, state) {
        final attachments = _getAttachmentsForItem(item, state);
        if (attachments.isEmpty) {
          return _buildAddAttachmentButton(item, state);
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isDarkMode(context) ? Colors.grey.shade800.withValues(alpha: 0.4) : Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    TablerIcons.paperclip,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.tr('attachments', fallback: 'Attachments'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  )
                ],
              ),
              ...attachments.map((attachment) => _buildSingleAttachment(item, attachment)),
              InkWell(
                onTap: () => _showAttachmentOptions(item),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(TablerIcons.plus, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 5),
                      Text(
                        context.tr('addMoreAttachments', fallback: 'Add more attachments'),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleAttachment(CartItem item, CartItemAttachment attachment) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openAttachment(attachment),
              child: Row(
                children: [
                  _buildFileIcon(attachment.fileType, attachment.filePath),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.fileName,
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _formatFileSize(attachment.fileSize),
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _removeSingleAttachment(item, attachment),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(TablerIcons.x, size: 18, color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(String fileType, String filePath) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return const Icon(TablerIcons.file_type_pdf, color: Colors.red, size: 28);
      case 'doc':
      case 'docx':
        return const Icon(TablerIcons.file_type_docx, color: Colors.blue, size: 28);
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(filePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(TablerIcons.photo, color: Colors.green, size: 28),
            ),
          ),
        );
      default:
        return const Icon(TablerIcons.file, color: Colors.grey, size: 28);
    }
  }

  Widget _buildAddAttachmentButton(CartItem item, AttachmentState state) {
    final hasAttachment = _hasAttachments(item, state);

    return Align(
      alignment: AlignmentGeometry.topLeft,
      child: InkWell(
        onTap: () {
          if (hasAttachment) {
            final attachments = _getAttachmentsForItem(item, state);
            _openAttachment(attachments.first);
          } else {
            _showAttachmentOptions(item);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasAttachment ? TablerIcons.eye : TablerIcons.paperclip,
                size: isTablet(context) ? 28 : 18.r,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                hasAttachment
                    ? (context.tr('viewAttachment', fallback: 'View Attachment'))
                    : (context.tr('addAttachment', fallback: 'Add Attachment')),
                style: TextStyle(
                  fontSize: isTablet(context) ? 24 : 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions(CartItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('addAttachment', fallback: 'Add Attachment'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('chooseFileTypeToUpload', fallback: 'Choose file type to upload'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAttachmentOption(
                  icon: TablerIcons.photo,
                  label: context.tr('imagesLabel'),
                  subtitle: context.tr('imagesSubtitle'),
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(item, 'image');
                  },
                ),
                const SizedBox(height: 12),
                _buildAttachmentOption(
                  icon: TablerIcons.file_type_pdf,
                  label: context.tr('pdfDocumentLabel'),
                  subtitle: context.tr('pdfDocumentSubtitle'),
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(item, 'pdf');
                  },
                ),
                const SizedBox(height: 12),
                _buildAttachmentOption(
                  icon: TablerIcons.file_type_docx,
                  label: context.tr('wordDocumentLabel'),
                  subtitle: context.tr('wordDocumentSubtitle'),
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(item, 'docx');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(CartItem item, String fileType) async {
    List<PlatformFile> result = [];

    if (fileType == 'image') {
      result = await FilePicker.pickFiles(
        type: FileType.image,
      );
    } else if (fileType == 'pdf') {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } else if (fileType == 'docx') {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx'],
      );
    }

    if (result.isEmpty) {
      // User canceled
      return;
    }

    final newAttachments = <CartItemAttachment>[];

    final platformFile = result.first;

    for (final platformFile in result) {
      if (platformFile.path == null) continue;

      final extension = path.extension(platformFile.name).toLowerCase().replaceAll('.', '');

      String detectedType = 'other';
      if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        detectedType = 'image';
      } else if (extension == 'pdf') {
        detectedType = 'pdf';
      } else if (['doc', 'docx'].contains(extension)) {
        detectedType = 'docx';
      }

      final attachment = CartItemAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString() + platformFile.name,
        fileName: platformFile.name,
        filePath: platformFile.path!,
        fileType: detectedType,
        fileSize: await File(platformFile.path!).length(),
      );

      newAttachments.add(attachment);
    }

    if (platformFile.path == null) {
      if (mounted) {
        ToastManager.show(
          context: context,
          message: context.tr('couldNotGetFilePath', fallback: 'Could not get file path'),
          type: ToastType.error,
        );
      }
      return;
    }

    log('New Attachments 2 $newAttachments');

    if (newAttachments.isNotEmpty && mounted) {
      context.read<AttachmentBloc>().add(AddAttachments(
            productId: item.productId ?? item.id!,
            attachment: newAttachments,
          ));
    }
  }

  Future<void> _openAttachment(CartItemAttachment attachment) async {
    try {
      final result = await OpenFilex.open(
        attachment.filePath,
      );

      if (result.type != ResultType.done) {
        if (mounted) {
          ToastManager.show(
            context: context,
            message: context.tr('cannotOpenFile', positionalArgs: [result.message], fallback: 'Cannot open file: ${result.message}'),
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastManager.show(
          context: context,
          message: context.tr('errorOpeningAttachment', positionalArgs: [e.toString()], fallback: 'Error opening file: $e'),
          type: ToastType.error,
        );
      }
    }
  }

  void _removeSingleAttachment(CartItem item, CartItemAttachment attachment) {
    context.read<AttachmentBloc>().add(
          RemoveAttachment(
            productId: item.productId ?? item.id!,
            attachment: attachment,
          ),
        );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class HintWidget extends StatelessWidget {
  final String text;
  const HintWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: isTablet(context) ? 14.sp : 10.sp,
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w600,
        fontFamily: AppTheme.fontFamily,
      ),
    );
  }
}

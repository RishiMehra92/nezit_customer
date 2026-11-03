import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../config/settings_data_instance.dart';
import '../../config/theme.dart';
import '../../screens/cart_page/bloc/clear_cart/clear_cart_bloc.dart';
import '../../screens/cart_page/bloc/clear_cart/clear_cart_event.dart';
import '../../screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import '../../utils/extensions/translation_extension.dart';
import '../../utils/widgets/custom_toast.dart';

class CartValidation {
  CartValidation._();

  /// Checks whether [newCurrencyCode] is compatible with items already in the cart.
  /// If the cart already has items in a different currency (e.g. INR vs USD),
  /// prompts the user to confirm clearing the cart.
  ///
  /// Returns:
  /// - `true` if compatible (or if user confirmed clearing the cart to start fresh).
  /// - `false` if user cancelled (do not proceed with adding the item).
  static Future<bool> ensureCurrencyCompatible({
    required BuildContext context,
    required String? newCurrencyCode,
  }) async {
    if (newCurrencyCode == null || newCurrencyCode.trim().isEmpty) {
      return true;
    }

    String? existingCurrency;
    bool hasItems = false;

    // 1. Check server-side cart via GetUserCartBloc if available
    try {
      final userCartBloc = context.read<GetUserCartBloc>();
      if (userCartBloc.cartData.isNotEmpty) {
        final cartData = userCartBloc.cartData.first.data;
        if (cartData != null && cartData.items.isNotEmpty) {
          hasItems = true;
          existingCurrency = cartData.currencyCode;
          if (existingCurrency == null || existingCurrency.isEmpty) {
            existingCurrency = cartData.currencyCodes.isNotEmpty
                ? cartData.currencyCodes.first
                : null;
          }
          if (existingCurrency == null || existingCurrency.isEmpty) {
            for (final item in cartData.items) {
              final c = item.variant?.currencyCode ?? item.product?.currencyCode;
              if (c != null && c.isNotEmpty) {
                existingCurrency = c;
                break;
              }
            }
          }
        }
      }
    } catch (_) {}

    // 2. Check local Hive cart if server cart didn't yield items
    if (!hasItems) {
      try {
        final cartBloc = context.read<CartBloc>();
        final localItems = cartBloc.localRepo.getAllItems();
        if (localItems.isNotEmpty) {
          hasItems = true;
          for (final item in localItems) {
            if (item.currencyCode != null && item.currencyCode!.isNotEmpty) {
              existingCurrency = item.currencyCode;
              break;
            }
          }
        }
      } catch (_) {}
    }

    // If cart is empty or no existing currency could be determined, allow adding
    if (!hasItems || existingCurrency == null || existingCurrency.trim().isEmpty) {
      return true;
    }

    // Compare currencies (case-insensitive)
    final existingUpper = existingCurrency.trim().toUpperCase();
    final newUpper = newCurrencyCode.trim().toUpperCase();

    if (existingUpper == newUpper) {
      return true;
    }

    // Currency mismatch detected: prompt the user
    if (!context.mounted) return false;

    final shouldReplace = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            ctx.tr('clearCartTitle', fallback: 'Clear Cart?'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            ctx.tr(
              'replaceCartCurrencyMessage',
              args: {
                'existingCurrency': existingUpper,
                'newCurrency': newUpper,
              },
              fallback: 'Your cart contains items in $existingUpper. Clear cart to add items in $newUpper?',
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.tr('cancel', fallback: 'Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                ctx.tr('clearCart', fallback: 'Clear Cart'),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldReplace == true) {
      if (!context.mounted) return false;
      try {
        context.read<ClearCartBloc>().add(ClearCartRequest());
      } catch (_) {}
      try {
        context.read<CartBloc>().add(ClearCart(context: context));
      } catch (_) {}

      // Prompted clear: notify user and return false so they can tap Add cleanly
      try {
        ToastManager.show(
          context: context,
          message: context.tr(
            'cartClearedAddAgain',
            args: {'currency': newUpper},
            fallback: 'Cart cleared. Tap Add again to add items in $newUpper.',
          ),
          type: ToastType.success,
        );
      } catch (_) {}
      return false;
    }

    return false;
  }

  /// PRODUCT-LEVEL VALIDATIONS.
  static String? validateProductAddToCart({
    required BuildContext context,
    required int requestedQuantity,
    required int minQty,
    required int maxQty,
    required int stock,
    bool isStoreOpen = true,
  }) {
    // Out of stock
    if (stock <= 0) {
      return context.tr('outOfStock');
    }

    // Store closed
    if (!isStoreOpen) {
      return context.tr('looksLikeTheStoreCatchingSomeRest');
    }

    // Below minimum quantity
    if (requestedQuantity < minQty) {
      return context.tr('minimumQuantityRequired', positionalArgs: [minQty]);
    }

    // Exceeds max allowed per product
    if (requestedQuantity > maxQty) {
      return context.tr('maximumQuantityAllowed', positionalArgs: [maxQty]);
    }

    // Exceeds available stock
    if (requestedQuantity > stock) {
      return context.tr('onlyXItemsInStock', positionalArgs: [stock]);
    }

    return null; // Valid
  }

  static String? validateBeforeAddToCart({
    required BuildContext context,
    required int currentCartItemCount,
    required int requestedAddQuantity,
    required Set<int> currentStoreIdsInCart,
    required int thisProductStoreId,
  }) {
    final system = SettingsData.instance.system!;

    final newTotalItemsCount = currentCartItemCount + requestedAddQuantity;

    // 1. Check maximum items allowed in cart (global limit)
    if (newTotalItemsCount > system.maximumItemsAllowedInCart!) {
      final remaining = system.maximumItemsAllowedInCart! - currentCartItemCount;
      if (remaining <= 0) {
        return context.tr('youHaveReachedMaximumLimitOfTheCart', positionalArgs: [system.maximumItemsAllowedInCart!]);
      }
      return context.tr('cannotAddMoreThanXItems', positionalArgs: [remaining]);
    }

    if (currentStoreIdsInCart.isNotEmpty) {
      if (system.checkoutType == 'single_store' && currentStoreIdsInCart.first != thisProductStoreId) {
        return context.tr('onlyOneStoreAtATime');
      }
    }

    // All checks passed
    return null;
  }

  /// CART-LEVEL VALIDATIONS.
  static String? validateCartForCheckout({
    required BuildContext context,
    required double cartTotal,
    required int totalItemsCount,
    required Set<int> storeIds,
    List<String>? currencyCodes,
    String? currencyCode,
  }) {
    // 0. Mixed-currency check as per Section 4 of multi-currency spec
    if (currencyCodes != null && currencyCodes.length > 1) {
      return 'Your cart contains stores with different currencies. Please checkout one currency at a time.';
    }
    if (currencyCodes != null && currencyCodes.isNotEmpty && (currencyCode == null || currencyCode.isEmpty)) {
      return 'Your cart contains stores with different currencies. Please checkout one currency at a time.';
    }

    final system = SettingsData.instance.system!;

    // Minimum cart amount
    if (cartTotal < system.minimumCartAmount!) {
      final minAmount = system.minimumCartAmount!;
      final diff = minAmount - cartTotal;

      String formatAmount(double val) {
        if (val == val.toInt()) {
          return val.toInt().toString();
        }
        return val.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }

      return context.tr('minimumCartAmountRequired', positionalArgs: [formatAmount(diff), formatAmount(minAmount.toDouble())]);
    }

    // Maximum items in cart
    if (totalItemsCount > system.maximumItemsAllowedInCart!) {
      return context.tr('youHaveReachedMaximumLimitOfTheCart', positionalArgs: [system.maximumItemsAllowedInCart!]);
    }

    // Multi-store restriction (if your app supports only single store)
    if (system.checkoutType == 'single_store' && storeIds.length > 1) {
      return context.tr('onlyOneStoreAtATime');
    }

    return null;
  }

  /// Helper: Get user-friendly stock message (not error, just info)
  static String getStockMessage({
    required int stock,
    required BuildContext context,
  }) {
    if (stock <= 0) {
      return context.tr('outOfStock');
    } else if (stock <= 5) {
      return context.tr('onlyFewLeft', positionalArgs: [stock]);
    }
    return context.tr('inStock');
  }
}
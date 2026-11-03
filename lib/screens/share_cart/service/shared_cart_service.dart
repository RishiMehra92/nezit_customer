import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/api_base_helper.dart';
import '../../../config/global.dart';
import '../../../config/helper.dart';
import '../../../model/user_cart_model/cart_addon.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../model/user_location/user_location_model.dart';
import '../../../services/address/selected_address_hive.dart';
import '../../../services/location/location_service.dart';
import '../../cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import '../model/shared_cart.dart';
import '../repo/shared_cart_repository.dart';

class SharedCartLocationRequired implements Exception {}

/// A server import succeeded; retrying the POST could duplicate a merge.
class SharedCartImportCommitted implements Exception {
  final SharedCartImport result;
  final Object cause;
  SharedCartImportCommitted(this.result, this.cause);
  @override
  String toString() => cause.toString();
}

class SharedCartService {
  final SharedCartRepository repository;
  final CartBloc cart;
  final GetUserCartBloc activeCart;

  SharedCartService(
      {required this.repository, required this.cart, required this.activeCart});

  bool get loggedIn => Global.userData?.token.isNotEmpty == true;

  bool get hasExistingItems {
    final localItems = cart.localRepo.getAllItems();
    if (localItems.isNotEmpty) return true;
    final activeState = activeCart.state;
    if (activeState is GetUserCartLoaded) {
      return activeState.cartData
          .any((store) => (store.data?.items.isNotEmpty ?? false));
    }
    return false;
  }

  void _requireLogin() {
    if (!loggedIn) throw ApiException('Sign in to share or import a cart.');
  }

  Future<CartShareLink> createLink() => cart.runExclusive(() async {
        _requireLogin();
        await cart.flushPendingChanges();
        _requireLogin();
        return repository.createLink();
      });

  Future<SharedCartPreview> preview(String code) {
    final address =
        loggedIn ? HiveSelectedAddressHelper.getSelectedAddress() : null;
    UserLocation? location;
    try {
      location = LocationService.getStoredLocation();
    } catch (_) {
      // Location storage may be unavailable if bootstrap initialization failed.
    }
    if (address?.id == null && location == null) {
      throw SharedCartLocationRequired();
    }
    return repository.preview(code,
        authenticated: loggedIn,
        addressId: address?.id,
        latitude: location?.latitude,
        longitude: location?.longitude);
  }

  Future<SharedCartImport> importCart(
          String code, SharedCartAction action, SharedCartPreview preview) =>
      cart.runExclusive(() async {
        _requireLogin();
        await cart.flushPendingChanges();
        _requireLogin();
        final result = await repository.importCart(code, action);
        final local = cart.localRepo.getAllItems();
        final items = result.cartItems.map((raw) {
          final incoming = SharedCartItem(raw);
          final addonIds = incoming.addons
              .map((a) => parseInt(a['addon_item_id']) ?? 0)
              .toList()
            ..sort();
          final key =
              '${incoming.productId}_${incoming.variantId}${addonIds.isEmpty ? '' : '_${addonIds.join('-')}'}';
          final existing =
              local.where((item) => item.cartKey == key).firstOrNull;
          final shared = preview.items
              .where((item) =>
                  item.productId == incoming.productId &&
                  item.variantId == incoming.variantId &&
                  item.storeId == incoming.storeId)
              .firstOrNull;
          return UserCart(
            productId: incoming.productId.toString(),
            variantId: incoming.variantId.toString(),
            vendorId: incoming.storeId.toString(),
            name: incoming.name.isNotEmpty
                ? incoming.name
                : existing?.name ?? shared?.name ?? '',
            variantName: existing?.variantName ?? shared?.variantName ?? '',
            image: existing?.image ?? shared?.image ?? '',
            price: shared?.unitPrice ?? existing?.price ?? 0,
            originalPrice:
                shared?.originalPrice ?? existing?.originalPrice ?? 0,
            quantity: incoming.quantity,
            minQty: existing?.minQty ?? 1,
            maxQty: existing?.maxQty ?? 25,
            isOutOfStock: false,
            isSynced: true,
            updatedAt: DateTime.now(),
            serverCartItemId: parseInt(raw['id']),
            syncAction: CartSyncAction.none,
            addons: incoming.addons.map((addon) {
              final id = parseInt(addon['addon_item_id']) ?? 0;
              final oldAddon = existing?.addons
                  .where((a) => a.addonItemId == id)
                  .firstOrNull;
              return CartAddon(
                  addonGroupId: parseInt(addon['addon_group_id']) ?? 0,
                  addonItemId: id,
                  title: parseString(addon['title']) ?? oldAddon?.title ?? '',
                  price: parseDouble(addon['price']) ?? oldAddon?.price ?? 0);
            }).toList(),
            currencyCode: shared?.currencyCode ?? existing?.currencyCode,
          );
        }).toList();
        try {
          await cart.localRepo.replaceWithImportedCart(items);
          cart.add(LoadCart());
        } catch (error) {
          throw SharedCartImportCommitted(result, error);
        } finally {
          activeCart.add(FetchUserCart(
              addressId: HiveSelectedAddressHelper.getSelectedAddress()?.id,
              reconcileImportedCart: true));
        }
        return result;
      });
}

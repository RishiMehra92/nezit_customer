import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart' show ProductData;

import '../../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../../model/user_cart_model/cart_sync_action.dart';
import '../../../../model/user_cart_model/user_cart.dart';
import '../../../../utils/widgets/bottom_variant_selector_with_addons.dart';
import '../../../../utils/widgets/custom_product_card.dart';
import '../../../ad_campaign/bloc/ad_click_bloc/ad_click_bloc.dart';
import '../../../ad_campaign/widgets/ad_visibility_observer.dart';

class HomeLayoutProductCard extends StatelessWidget {
  final ProductData data;
  final List<String>? relatedProductSlugs;
  final ValueNotifier<List<String>>? relatedSlugsNotifier;
  final VoidCallback? onReachEnd;
  final int? initialIndex;

  const HomeLayoutProductCard({
    super.key,
    required this.data,
    this.relatedProductSlugs,
    this.relatedSlugsNotifier,
    this.onReachEnd,
    this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final variants = data.variants;
    if (variants.isEmpty) return const SizedBox.shrink();
    final defaultVariant = variants.firstWhere(
      (v) => v.isDefault,
      orElse: () => variants.first,
    );

    final card = CustomProductCard(
      productId: data.id,
      productImage: data.mainImage,
      productImages: [
        data.mainImage,
        ...data.additionalImages,
        ...data.variants.map((v) => v.image),
      ].where((img) => img.isNotEmpty).toSet().toList(),
      productName: data.title,
      productSlug: data.slug,
      productPrice: defaultVariant.price.toString(),
      formattedProductPrice: defaultVariant.formattedPrice,
      specialPrice: defaultVariant.specialPrice.toString(),
      formattedSpecialPrice: defaultVariant.formattedSpecialPrice,
      currencyCode: defaultVariant.currencyCode,
      productTags: const [],
      estimatedDeliveryTime: data.estimatedDeliveryTime,
      ratings: double.tryParse(data.ratings.toString()) ?? 0,
      ratingCount: data.ratingCount,
      isSponsored: data.isSponsored,
      badge: data.badge,
      onCardTap: data.isSponsored
          ? () => context.read<AdClickBloc>().add(RecordClick(
                campaignId: data.campaignId,
                visitorKey: data.visitorKey,
              ))
          : null,
      onAddToCart: () {
        if (data.variants.length > 1 || data.variants.any((v) => v.addonGroups.isNotEmpty == true)) {
          showVariantBottomSheetWithAddons(
            variantsList: data.variants,
            productData: data,
            productImage: data.mainImage,
            quantityStepSize: data.quantityStepSize,
            context: context,
          );
        } else {
          final item = UserCart(
            productId: data.id.toString(),
            variantId: defaultVariant.id.toString(),
            variantName: defaultVariant.title.toString(),
            vendorId: defaultVariant.storeId.toString(),
            name: data.title,
            image: data.mainImage,
            price: defaultVariant.specialPrice.toDouble(),
            originalPrice: defaultVariant.price.toDouble(),
            quantity: data.minimumOrderQuantity,
            serverCartItemId: null,
            syncAction: CartSyncAction.add,
            updatedAt: DateTime.now(),
            minQty: data.minimumOrderQuantity,
            maxQty: data.totalAllowedQuantity,
            isOutOfStock: defaultVariant.stock <= 0,
            isSynced: false,
            currencyCode: defaultVariant.currencyCode,
          );
          context.read<CartBloc>().add(AddToCart(item: item, context: context));
        }
      },
      variantCount: data.variants.length,
      onVariantSelectorRequested: data.variants.length > 1
          ? () => showVariantBottomSheetWithAddons(
                variantsList: data.variants,
                productData: data,
                productImage: data.mainImage,
                quantityStepSize: data.quantityStepSize,
                context: context,
              )
          : null,
      isStoreOpen: data.storeStatus?.isOpen ?? true,
      isWishListed: data.favorite.isNotEmpty,
      productVariantId: defaultVariant.id,
      storeId: defaultVariant.storeId,
      wishlistItemId: data.favorite.isNotEmpty ? data.favorite.first.id ?? 0 : 0,
      totalStocks: defaultVariant.stock,
      imageFit: data.imageFit,
      quantityStepSize: data.quantityStepSize,
      minQty: data.minimumOrderQuantity,
      totalAllowedQuantity: data.totalAllowedQuantity,
      indicator: data.indicator,
      relatedProductSlugs: relatedProductSlugs,
      relatedSlugsNotifier: relatedSlugsNotifier,
      onReachEnd: onReachEnd,
      initialIndex: initialIndex,
    );

    if (data.isSponsored && data.campaignId > 0) {
      return AdVisibilityObserver(
        campaignId: data.campaignId,
        visitorKey: data.visitorKey,
        child: card,
      );
    }
    return card;
  }
}

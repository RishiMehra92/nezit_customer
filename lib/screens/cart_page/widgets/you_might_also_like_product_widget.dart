import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
// ignore: unused_import
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hyper_local/utils/widgets/bottom_variant_selector_with_addons.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/helper.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../utils/widgets/custom_product_card.dart';
import '../../ad_campaign/bloc/ad_click_bloc/ad_click_bloc.dart';
import '../../ad_campaign/widgets/ad_visibility_observer.dart';

class YouMightAlsoLikeProductWidget extends StatelessWidget {
  final List<ProductData> productData;
  final int? addressId;
  final String? promoCode;
  final bool? rushDelivery;
  final bool? useWallet;
  final bool? isFromCartPage;

  const YouMightAlsoLikeProductWidget(
      {super.key,
      required this.productData,
      this.addressId,
      this.promoCode,
      this.rushDelivery,
      this.useWallet,
      this.isFromCartPage});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12.0.w, right: 12.0.w, top: 12.h, bottom: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('youMightAlsoLike'),
                  style: TextStyle(
                    fontSize: isTablet(context) ? 24 : 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 5.h),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(productData.length, (index) {
                  final product = productData[index];
                  ProductVariants? defaultVariant;
                  if (product.variants.isNotEmpty) {
                    defaultVariant = product.variants.firstWhere(
                      (variant) => variant.isDefault == true,
                      orElse: () => product.variants.first,
                    );
                  }

                  // Set price and specialPrice based on the default variant
                  final price = defaultVariant != null ? defaultVariant.price.toString() : '0';
                  final specialPrice = defaultVariant != null ? defaultVariant.specialPrice.toString() : '';

                  final card = CustomProductCard(
                    productId: product.id,
                    productImage: product.mainImage,
                    productImages: [
                      product.mainImage,
                      ...product.additionalImages,
                      ...product.variants.map((v) => v.image),
                    ].where((img) => img.isNotEmpty).toSet().toList(),
                    productSlug: product.slug,
                    productName: product.title,
                    productPrice: price,
                    specialPrice: specialPrice,
                    productTags: const [],
                    estimatedDeliveryTime: product.estimatedDeliveryTime.toString(),
                    assetImage: '',
                    ratings: double.parse(product.ratings.toString()),
                    ratingCount: product.ratingCount,
                    onAddToCart: () {
                      if (product.variants.length > 1 ||
                          product.variants.any((v) => v.addonGroups.isNotEmpty == true)) {
                        showVariantBottomSheetWithAddons(
                            variantsList: product.variants,
                            productData: product,
                            productImage: product.mainImage,
                            quantityStepSize: product.quantityStepSize,
                            context: context,
                            addressId: addressId,
                            promoCode: promoCode,
                            rushDelivery: rushDelivery,
                            useWallet: useWallet,
                            isFromCartPage: isFromCartPage);
                      } else {
                        final item = UserCart(
                            productId: product.id.toString(),
                            variantId: defaultVariant!.id.toString(),
                            variantName: defaultVariant.title.toString(),
                            vendorId: defaultVariant.storeId.toString(),
                            name: product.title,
                            image: product.mainImage,
                            price: defaultVariant.specialPrice.toDouble(),
                            originalPrice: defaultVariant.price.toDouble(),
                            quantity: product.quantityStepSize,
                            serverCartItemId: null,
                            syncAction: CartSyncAction.add,
                            updatedAt: DateTime.now(),
                            minQty: product.minimumOrderQuantity,
                            maxQty: product.totalAllowedQuantity,
                            isOutOfStock: defaultVariant.stock <= 0,
                            isSynced: false,
                            currencyCode: defaultVariant.currencyCode,
                        );
                        context.read<CartBloc>().add(AddToCart(
                            item: item,
                            context: context,
                            isFromCartPage: true,
                            useWallet: useWallet,
                            rushDelivery: rushDelivery,
                            addressId: addressId,
                            promoCode: promoCode));

                        // context.read<AddToCartBloc>().add(
                      }
                    },
                    variantCount: product.variants.length,
                    onVariantSelectorRequested: product.variants.length > 1
                        ? () => showVariantBottomSheetWithAddons(
                            variantsList: product.variants,
                            productData: product,
                            productImage: product.mainImage,
                            quantityStepSize: product.quantityStepSize,
                            context: context,
                            addressId: addressId,
                            promoCode: promoCode,
                            rushDelivery: rushDelivery,
                            useWallet: useWallet,
                            isFromCartPage: isFromCartPage)
                        : null,
                    isStoreOpen: product.storeStatus?.isOpen ?? true,
                    isWishListed: product.favorite.isNotEmpty,
                    productVariantId: defaultVariant!.id,
                    storeId: defaultVariant.storeId,
                    wishlistItemId: product.favorite.isNotEmpty ? product.favorite.first.id ?? 0 : 0,
                    totalStocks: defaultVariant.stock,
                    imageFit: product.imageFit,
                    quantityStepSize: product.quantityStepSize,
                    minQty: product.minimumOrderQuantity,
                    totalAllowedQuantity: product.totalAllowedQuantity,
                    isSponsored: product.isSponsored,
                    onCardTap: product.isSponsored
                        ? () => context.read<AdClickBloc>().add(RecordClick(
                              campaignId: product.campaignId,
                              visitorKey: product.visitorKey,
                            ))
                        : null,
                    relatedProductSlugs: productData.map((e) => e.slug).toList(),
                    initialIndex: index,
                  );

                  final Widget cardWidget = product.isSponsored && product.campaignId > 0
                      ? AdVisibilityObserver(
                          campaignId: product.campaignId,
                          visitorKey: product.visitorKey,
                          child: card,
                        )
                      : card;

                  return Padding(
                    padding: EdgeInsets.only(right: 12.0.w),
                    child: SizedBox(
                      width: isTablet(context) ? 140.w : 120.w,
                      child: cardWidget,
                    ),
                  );
                }),
              ),
            ),
          )
        ],
      ),
    );
  }
}

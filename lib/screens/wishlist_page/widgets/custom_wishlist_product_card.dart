import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/adaptive_price_text.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';
import '../../../router/app_routes.dart';

class WishlistProductCard extends StatelessWidget {
  final String productImage;
  final String productName;
  final String productSlug;
  final String price;
  final String specialPrice;
  final String? formattedPrice;
  final String? formattedSpecialPrice;
  final String? currencyCode;
  final VoidCallback onMoveToAnotherWishlist;

  const WishlistProductCard({
    super.key,
    required this.productImage,
    required this.productName,
    required this.productSlug,
    required this.price,
    required this.specialPrice,
    this.formattedPrice,
    this.formattedSpecialPrice,
    this.currencyCode,
    required this.onMoveToAnotherWishlist,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        GoRouter.of(context).push(
            AppRoutes.productDetailPage,
            extra: {
              'productSlug': productSlug
            }
        );
      },
      child: Container(
        width: 180,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomImageContainer(
                      imagePath: productImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              ],
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  SizedBox(
                    height: 33,
                    child: Text(
                      productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        flex: 3,
                        child: AdaptivePriceText(
                          MoneyDisplay.format(specialPrice, formatted: formattedSpecialPrice, currencyCode: currencyCode),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          minFontSize: 10.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        fit: FlexFit.loose,
                        flex: 2,
                        child: AdaptivePriceText(
                          MoneyDisplay.format(price, formatted: formattedPrice, currencyCode: currencyCode),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                          minFontSize: 9.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onMoveToAnotherWishlist,
                      icon: Icon(TablerIcons.transfer, size: 18.r),
                      label: Text(
                          '',
                        style: TextStyle(
                          fontSize: 8.sp
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
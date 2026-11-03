import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

import 'custom_button.dart';

class EmptyStatePage extends StatelessWidget {
  final String title;
  final String description;
  final String imageAsset;
  final VoidCallback? onRetry;

  const EmptyStatePage({
    super.key,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomImageContainer(imagePath: imageAsset),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (onRetry != null) ...[
              const SizedBox(height: 10),
              CustomButton(
                onPressed: onRetry!,
                child: Text(context.tr('retry', fallback: 'Retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStatePageOnLocation extends StatelessWidget {
  final String title;
  final String description;
  final String imageAsset;
  final VoidCallback? onRetry;

  const EmptyStatePageOnLocation({
    super.key,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomImageContainer(imagePath: imageAsset),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              CustomButton(
                onPressed: onRetry!,
                child: Text(context.tr('changeLocation', fallback: 'Change Location')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      title: context.tr('noInternetConnection', fallback: 'No Internet Connection'),
      description: context.tr('checkConnectionAndTryAgain', fallback: 'Please check your connection and try again.'),
      imageAsset: 'assets/svg/no-internet-connection.svg',
      onRetry: () => Navigator.pop(context),
    );
  }
}

class MaintenancePage extends StatelessWidget {
  final String? description;
  final bool showRetry;

  const MaintenancePage({
    super.key,
    this.description,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CustomImageContainer(
                imagePath: 'assets/svg/app-under-maintenance.svg',
              ),
            ),
            const SizedBox(height: 25),
            Material(
              child: Text(
                'We\'ll be back soon!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description ?? 'Our system is currently undergoing scheduled maintenance to serve you better. We\'ll be back online shortly',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class NoOrderPage extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoOrderPage({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      title: context.tr('noOrderFound', fallback: 'No Order Found'),
      description: context.tr('noOrdersYetDescription', fallback: "It looks like you don't have any orders yet."),
      imageAsset: 'assets/svg/no-product-found.svg',
      onRetry: onRetry ?? () => Navigator.pop(context),
    );
  }
}

class NoPromoCodePage extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoPromoCodePage({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      title: context.tr('noPromoCodesAvailable', fallback: 'No Promo Code Found'),
      description: context.tr('thereAreNoActivePromoCodeOrCouponsAvailableRightNow', fallback: "It looks like you don't have any orders yet."),
      imageAsset: 'assets/svg/no-promo-code-state.svg',
      onRetry: onRetry ?? () => Navigator.pop(context),
    );
  }
}

class NoCategoryPage extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoCategoryPage({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      title: context.tr('noCategoryFound', fallback: 'No Category Found'),
      description: context.tr('weCouldntFindAnyCategories', fallback: "We couldn't find any categories."),
      imageAsset: 'assets/svg/no-product-found.svg',
      onRetry: onRetry,
    );
  }
}

class NoSearchPage extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoSearchPage({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      title: context.tr('noSearchResults', fallback: 'No Search Results'),
      description: context.tr('tryAdjustingSearchTerms', fallback: 'Try adjusting your search terms.'),
      imageAsset: 'assets/svg/no-search-results.svg',
      onRetry: onRetry,
    );
  }
}

class NoProductPage extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? title;
  final String? description;
  const NoProductPage({super.key, this.onRetry, this.title, this.description});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      title: title ?? context.tr('noProductFound', fallback: 'No Product Found'),
      description: description ?? context.tr('noProductMatchingSearch', fallback: "We couldn't find any products matching your search."),
      imageAsset: 'assets/svg/no-product-found.svg',
      onRetry: onRetry,
    );
  }
}

class NoStorePage extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoStorePage({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      title: context.tr('noStoreFound', fallback: 'No Store Found'),
      description: context.tr('weCouldntFindAnyStoreInYourSelectLocation', fallback: "We couldn't find any store in your select location."),
      imageAsset: 'assets/svg/no-product-found.svg',
      onRetry: onRetry,
    );
  }
}

class NoDeliveryLocationPage extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoDeliveryLocationPage({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePageOnLocation(
      title: context.tr('wereNotHereYet', fallback: 'We’re not here yet'),
      description: context.tr('noStoresOrProductsAreAvailableInThisAreaRightNow', fallback: 'No stores or products are available in this area right now.'),
      imageAsset: 'assets/images/icons/delivery_pin.png',
      onRetry: onRetry,
    );
  }
}

class NoDeliveryZonePage extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoDeliveryZonePage({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      title: context.tr('noDeliveryZoneFound', fallback: 'No Delivery Zone Found'),
      description: context.tr('noDeliveryZoneDescription', fallback: "We couldn't find any delivery zone in your selected area."),
      imageAsset: 'assets/svg/no-product-found.svg',
      onRetry: onRetry,
    );
  }
}

class NoReelPage extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoReelPage({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      title: context.tr('noReelsFound', fallback: 'No Reels Found'),
      description: context.tr('noReelsDescription', fallback: 'We couldn\'t find any Watch & Buy reels in your selected location.'),
      imageAsset: 'assets/svg/no-product-found.svg',
      onRetry: onRetry,
    );
  }
}
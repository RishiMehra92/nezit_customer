import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

enum HeroLayout { bannerOnly, withItems }

enum HeroCardStyle { full, imageTitle }

class HeroSpacing {
  final EdgeInsets? outerPadding;
  final BorderRadius? borderRadius;

  const HeroSpacing({this.outerPadding, this.borderRadius});

  factory HeroSpacing.fromConfig(dynamic config) {
    return HeroSpacing(
      outerPadding: parseOuterPadding(config),
      borderRadius: parseBorderRadius(config),
    );
  }
}

class HeroSectionStyle extends StatelessWidget {
  final String bgType;
  final String bgPath;
  final List<HeroPromoCard>? cards;
  final HeroLayout layout;
  final double? bannerHeight;
  final String? cardBgType;
  final Color? cardBgColor;
  final String? cardBgImage;
  final Color? cardTitleColor;
  final HeroCardStyle cardStyle;
  final HeroSpacing? spacing;

  const HeroSectionStyle(
      {super.key,
      this.bgType = 'image',
      this.bgPath = 'assets/images/hero-image-8.png',
      this.cards,
      this.layout = HeroLayout.withItems,
      this.bannerHeight,
      this.cardBgType,
      this.cardBgColor,
      this.cardBgImage,
      this.cardTitleColor,
      this.cardStyle = HeroCardStyle.imageTitle,
      this.spacing});

  BoxDecoration get _cardDecoration {
    if (cardBgType == 'image' && cardBgImage != null && cardBgImage!.isNotEmpty) {
      return BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(cardBgImage!),
          fit: BoxFit.cover,
        ),
      );
    }
    return BoxDecoration(
      color: cardBgColor ?? Colors.white.withValues(alpha: 0.9),
    );
  }

  static const Color _cardBottom = Colors.lightGreen;

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case HeroLayout.bannerOnly:
        return _bannerOnly();
      case HeroLayout.withItems:
        return _withItems(context);
    }
  }

  Widget _bannerOnly() {
    final outerPadding = spacing?.outerPadding;

    final borderRadius = spacing?.borderRadius ?? BorderRadius.zero;

    final child = ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: heroBackground(bgType: bgType, bgPath: bgPath),
    );

    return SizedBox(
      width: double.infinity,
      child: outerPadding != null
          ? Container(
              margin: outerPadding,
              child: child,
            )
          : child,
    );
  }

  Widget _withItems(BuildContext ctx) {
    final items = cards;
    final rows = <List<HeroPromoCard>>[];
    for (var i = 0; i < items!.length; i += 3) {
      rows.add(items.sublist(i, (i + 3) > items.length ? items.length : i + 3));
    }

    final outerPadding = spacing?.outerPadding;

    final borderRadius = spacing?.borderRadius ?? BorderRadius.zero;

    return Container(
      height: 270.h,
      margin: outerPadding,
      child: Stack(
        children: [
          Container(
            height: 270.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: Theme.of(ctx).colorScheme.outline,
            ),
            child: ClipRRect(
                borderRadius: borderRadius,
                clipBehavior: Clip.antiAlias,
                child: heroBackground(bgType: bgType, bgPath: bgPath)),
          ),
          // Promo card mosaic.
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 85.h, 12.w, 8.h),
            child: Column(
              children: [
                for (final row in rows) ...[
                  Expanded(child: Row(children: _rowChildren(row, ctx))),
                  SizedBox(height: 8.h),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rowChildren(List<HeroPromoCard> row, BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < row.length; i++) {
      if (i > 0) children.add(SizedBox(width: 8.w));
      children.add(Expanded(
        child: _SmallCard(
            card: row[i],
            decoration: _cardDecoration,
            cardTitleColor: cardTitleColor ?? Theme.of(context).colorScheme.tertiary,
            cardStyle: cardStyle),
      ));
    }
    // Keep card widths consistent when the last row has fewer than 3.
    for (var i = row.length; i < 3; i++) {
      children.add(SizedBox(width: 8.w));
      children.add(const Expanded(child: SizedBox.shrink()));
    }
    return children;
  }

  Widget heroBackground({required String bgType, required String bgPath}) {
    if (bgType == 'animation') {
      final errorWidget = Center(
        child: Text(
          'Hero animation',
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w900,
            color: _cardBottom,
          ),
        ),
      );
      // hero_media may be a network URL (API) or a bundled asset.
      return CustomImageContainer(
        imagePath: bgPath,
        fit: BoxFit.cover,
        errorWidget: errorWidget,
      );
    } else {
      return CustomImageContainer(
        imagePath: bgPath,
        fit: BoxFit.cover,
      );
    }
  }
}

class HeroPromoCard {
  final String title;
  final String badgeLabel;
  final List<String> imageUrls;
  final VoidCallback? onTap;

  const HeroPromoCard({
    required this.title,
    this.badgeLabel = '',
    this.imageUrls = const [],
    this.onTap,
  });
}

class _SmallCard extends StatelessWidget {
  final HeroPromoCard card;
  final BoxDecoration decoration;
  final Color cardTitleColor;
  final HeroCardStyle cardStyle;
  const _SmallCard(
      {required this.card, required this.decoration, required this.cardTitleColor, required this.cardStyle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: card.onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 90.h,
          decoration: decoration,
          child: cardStyle == HeroCardStyle.full ? _fullImage() : _imageTitle(),
        ),
      ),
    );
  }

  Widget _fullImage() {
    if (card.imageUrls.isEmpty) {
      return Center(
        child: Icon(
          Icons.local_drink_rounded,
          size: 28.r,
          color: Colors.white70,
        ),
      );
    }
    return CustomImageContainer(
      imagePath: card.imageUrls.first,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorWidget: Center(
        child: Icon(
          Icons.local_drink_rounded,
          size: 28.r,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _imageTitle() {
    return Stack(
      children: [
        Positioned(
          right: 0,
          left: 0,
          bottom: -10,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final url in card.imageUrls)
                Expanded(
                  child: CustomImageContainer(
                    imagePath: url,
                    height: 55.h,
                    fit: BoxFit.contain,
                    errorWidget: Icon(
                      Icons.local_drink_rounded,
                      size: 28.r,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Title top-left.
        Positioned(
          top: 6,
          left: 16,
          right: 16,
          child: Text(
            card.title,
            maxLines: 2,
            style: TextStyle(
                color: cardTitleColor, fontSize: 12, height: 1.1, letterSpacing: 0.2, overflow: TextOverflow.ellipsis),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

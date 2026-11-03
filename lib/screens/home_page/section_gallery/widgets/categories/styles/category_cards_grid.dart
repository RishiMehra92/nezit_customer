import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';

import '../../../data/sample_section_data.dart';

/// Category cards — Grid style (body only, no section title).
/// Card design replicated from `custom_sub_category_card.dart`: a LayoutBuilder
/// cell with the image on top (65% height, onSecondary background, radius
/// = cardWidth * 0.12) and a centered, responsive 2-line name below (35%).
class CategoryCardsGrid extends StatelessWidget {
  final List<SampleTile> categories;
  final int crossAxisCount;
  final EdgeInsets? outerPadding;
  final double? horizontalGap;
  final double? verticalGap;
  final bool isGrid;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const CategoryCardsGrid({
    super.key,
    this.categories = SampleSectionData.categories,
    this.crossAxisCount = 4,
    this.outerPadding,
    this.horizontalGap,
    this.verticalGap,
    this.isGrid = true,
    this.controller,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive spacing
    double getSpacing(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      return screenWidth * 0.025;
    }

    final double horizontalSpacing = horizontalGap != null ? horizontalGap!.w : getSpacing(context);
    final double verticalSpacing = verticalGap != null ? verticalGap!.h : getSpacing(context);

    if (!isGrid) {
      final itemWidth = 80.w;
      final itemHeight = 100.h;
      return SizedBox(
        height: itemHeight,
        child: ListView.separated(
          controller: controller,
          shrinkWrap: shrinkWrap,
          scrollDirection: Axis.horizontal,
          padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: categories.length,
          separatorBuilder: (_, __) => SizedBox(width: (horizontalGap ?? 12.0).w),
          itemBuilder: (context, i) {
            final tile = categories[i];
            return GestureDetector(
              onTap: tile.onTap,
              behavior: HitTestBehavior.opaque,
              child: _buildItem(context, tile, itemWidth, itemHeight),
            );
          },
        ),
      );
    }

    final itemsList = categories.map((tile) {
      return GestureDetector(
        onTap: tile.onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final cardHeight = constraints.maxHeight;
            return _buildItem(context, tile, cardWidth, cardHeight);
          },
        ),
      );
    }).toList();

    return Padding(
      padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 16.w),
      child: StaggeredListAnimator(
        type: StaggeredListType.gridView,
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: horizontalSpacing,
          mainAxisSpacing: verticalSpacing,
          childAspectRatio: 0.7,
        ),
        columnCount: crossAxisCount,
        children: itemsList,
      ),
    );
  }

  Widget _buildItem(BuildContext context, SampleTile tile, double cardWidth, double cardHeight) {
    final borderRadius = cardWidth * 0.12;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: SizedBox.expand(
                child: CustomImageContainer(
                  imagePath: tile.imageUrl,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(borderRadius),
                  errorWidget: Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.05),
            child: Text(
              tile.name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _responsiveFontSize(cardWidth),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _responsiveFontSize(double cardWidth) {
    if (cardWidth >= 100) return 14;
    if (cardWidth >= 80) return 13;
    if (cardWidth >= 60) return 12;
    return 12;
  }
}

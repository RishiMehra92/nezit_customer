import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';

import '../../../data/sample_section_data.dart';

/// Category cards — Custom Image card style.
/// Swipeable/scrollable horizontal row of custom aspect ratio image cards.
class CategoryCardsCustomImage extends StatelessWidget {
  final List<SampleTile> categories;
  final bool isGrid;
  final int gridColumns;
  final EdgeInsets? outerPadding;
  final double? horizontalGap;
  final double? verticalGap;

  const CategoryCardsCustomImage({
    super.key,
    required this.categories,
    this.isGrid = false,
    this.gridColumns = 3,
    this.outerPadding,
    this.horizontalGap,
    this.verticalGap,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalGapVal = horizontalGap ?? 10.0;
    final verticalGapVal = verticalGap ?? 10.0;

    if (isGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 8.w),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumns,
          crossAxisSpacing: horizontalGapVal.w,
          mainAxisSpacing: verticalGapVal.h,
          childAspectRatio: gridColumns == 2 ? 1 : (gridColumns == 3 ? 1.1 : 1.0),
        ),
        itemBuilder: (context, i) {
          final tile = categories[i];
          return GestureDetector(
            onTap: tile.onTap,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CustomImageContainer(
                imagePath: tile.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                placeholder: ShimmerWidget.rectangular(
                  width: double.infinity,
                  height: double.infinity,
                  isBorder: false,
                ),
                errorWidget: Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      );
    }

    return SizedBox(
      height: 170.h,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: horizontalGapVal.w),
        itemBuilder: (context, i) {
          final tile = categories[i];
          return GestureDetector(
            onTap: tile.onTap,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CustomImageContainer(
                imagePath: tile.imageUrl,
                height: 170.h,
                fit: BoxFit.contain,
                placeholder: ShimmerWidget.rectangular(
                  width: 160.w, // Fixed placeholder width to prevent collapse during loading
                  height: 120.h,
                  isBorder: false,
                ),
                errorWidget: Container(
                  width: 120.w,
                  height: 120.h,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

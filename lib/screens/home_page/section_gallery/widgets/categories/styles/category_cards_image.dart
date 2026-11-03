import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

import '../../../data/sample_section_data.dart';

/// Category cards — Image card style (body only, no section title).
/// Horizontal scrolling rectangular image cards with the name overlaid on a
/// gradient scrim.
class CategoryCardsImage extends StatelessWidget {
  final List<SampleTile> categories;
  final EdgeInsets? outerPadding;
  final double? horizontalGap;
  final double? verticalGap;

  const CategoryCardsImage({
    super.key,
    this.categories = SampleSectionData.categories,
    this.outerPadding,
    this.horizontalGap,
    this.verticalGap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final horizontalGapVal = horizontalGap ?? 10.0;

    return SizedBox(
      height: 125.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: horizontalGapVal.w),
        itemBuilder: (context, i) {
          final tile = categories[i];
          return GestureDetector(
            onTap: tile.onTap,
            behavior: HitTestBehavior.opaque,
            child: CustomImageContainer(
              imagePath: tile.imageUrl,
              width: 115.w,
              height: 125.h,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12.r),
              errorWidget: Container(
                color: scheme.surfaceContainerHighest,
                child: Icon(Icons.category_rounded,
                    color: scheme.primary, size: 32.r),
              ),
            ),
          );
        },
      ),
    );
  }
}

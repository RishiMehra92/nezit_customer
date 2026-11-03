import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/sample_section_data.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';

/// Brand cards — Style 2 (body only, no section title).
/// Non-scrolling grid of rounded square brand tiles with a colored background.
class BrandStyleTwo extends StatelessWidget {
  final List<SampleTile> brands;
  final int crossAxisCount;
  final bool isCustomImage;
  final bool isGrid;
  final BorderRadius? borderRadius;
  final EdgeInsets? outerPadding;
  final double? horizontalGap;
  final double? verticalGap;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const BrandStyleTwo({
    super.key,
    this.brands = SampleSectionData.brands,
    this.crossAxisCount = 3,
    this.isCustomImage = false,
    this.isGrid = true,
    this.borderRadius,
    this.outerPadding,
    this.horizontalGap,
    this.verticalGap,
    this.controller,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final horizontalGapVal = horizontalGap ?? 12.0;
    final verticalGapVal = verticalGap ?? 14.0;

    if (!isGrid) {
      return SizedBox(
        height: 110.h,
        child: ListView.separated(
          controller: controller,
          shrinkWrap: shrinkWrap,
          scrollDirection: Axis.horizontal,
          padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: brands.length,
          separatorBuilder: (_, __) => SizedBox(width: horizontalGapVal.w),
          itemBuilder: (context, i) {
            final tile = brands[i];
            if (isCustomImage) {
              return GestureDetector(
                onTap: tile.onTap,
                behavior: HitTestBehavior.opaque,
                child: CustomImageContainer(
                  imagePath: tile.imageUrl,
                  height: 90.h,
                  fit: BoxFit.contain,
                  borderRadius: borderRadius ?? BorderRadius.zero,
                  errorWidget: Icon(Icons.storefront_rounded, color: scheme.primary),
                ),
              );
            }
            return GestureDetector(
              onTap: tile.onTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: isTablet ? 65.w : 100.w,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: borderRadius ?? BorderRadius.circular(16.r),
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        child: CustomImageContainer(
                          imagePath: tile.imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: Icon(Icons.storefront_rounded, color: scheme.primary),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      tile.name,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    final itemsList = brands.map((tile) {
      if (isCustomImage) {
        return GestureDetector(
          onTap: tile.onTap,
          behavior: HitTestBehavior.opaque,
          child: CustomImageContainer(
            imagePath: tile.imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            borderRadius: borderRadius ?? BorderRadius.zero,
            errorWidget: Icon(Icons.storefront_rounded, color: scheme.primary),
          ),
        );
      }
      return GestureDetector(
        onTap: tile.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: borderRadius ?? BorderRadius.circular(16.r),
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.all(10.0),
                child: CustomImageContainer(
                  imagePath: tile.imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: Icon(Icons.storefront_rounded, color: scheme.primary),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              tile.name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ],
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
          mainAxisSpacing: verticalGapVal.h,
          crossAxisSpacing: horizontalGapVal.w,
          childAspectRatio: isCustomImage ? 1.0 : 0.9,
        ),
        columnCount: crossAxisCount,
        children: itemsList,
      ),
    );
  }
}

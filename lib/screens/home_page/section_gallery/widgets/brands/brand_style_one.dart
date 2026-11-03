import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/sample_section_data.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

/// Brand cards — Style 1 (body only, no section title).
/// Card design replicated from `custom_brands_card.dart`: a bordered surface
/// card with a subtle shadow and the logo shown with BoxFit.contain, in a
/// horizontal scroll. Card width adapts for tablets (65.w) vs phones (100.w).
class BrandStyleOne extends StatelessWidget {
  final List<SampleTile> brands;
  final bool isCustomImage;
  final bool isGrid;
  final int crossAxisCount;
  final BorderRadius? borderRadius;
  final EdgeInsets? outerPadding;
  final double? horizontalGap;
  final double? verticalGap;

  const BrandStyleOne({
    super.key,
    this.brands = SampleSectionData.brands,
    this.isCustomImage = false,
    this.isGrid = false,
    this.crossAxisCount = 3,
    this.borderRadius,
    this.outerPadding,
    this.horizontalGap,
    this.verticalGap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final horizontalGapVal = horizontalGap ?? 12.0;
    final verticalGapVal = verticalGap ?? 14.0;

    if (!isGrid) {
      return SizedBox(
        height: 90.h,
        child: ListView.separated(
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
                  width: isTablet ? 65.w : 100.w,
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
              child: Container(
                width: isTablet ? 65.w : 100.w,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  borderRadius: borderRadius ?? BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.tertiary.withValues(alpha: 0.1),
                      blurRadius: 0.5,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: CustomImageContainer(
                  imagePath: tile.imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: Icon(Icons.storefront_rounded, color: scheme.primary),
                ),
              ),
            );
          },
        ),
      );
    }

    return Padding(
      padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: brands.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: verticalGapVal.h,
          crossAxisSpacing: horizontalGapVal.w,
          childAspectRatio: 1.0,
        ),
        padding: EdgeInsets.zero,
        itemBuilder: (context, i) {
          final tile = brands[i];
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
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
                borderRadius: borderRadius ?? BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: scheme.tertiary.withValues(alpha: 0.1),
                    blurRadius: 0.5,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: CustomImageContainer(
                imagePath: tile.imageUrl,
                fit: BoxFit.contain,
                errorWidget: Icon(Icons.storefront_rounded, color: scheme.primary),
              ),
            ),
          );
        },
      ),
    );
  }
}

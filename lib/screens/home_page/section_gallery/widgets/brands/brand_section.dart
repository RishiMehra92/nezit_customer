import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_see_all_button.dart';

import '../../data/sample_section_data.dart';
import '../../data/section_background.dart';
import 'brand_style_one.dart';
import 'brand_style_two.dart';

/// Selectable card layout for the brand section.
enum BrandCardStyle { cards, grid, customImage }

class BrandSection extends StatelessWidget {
  final String title;
  final List<SampleTile> brands;
  final BrandCardStyle style;
  final SectionBackground background;
  final VoidCallback? onSeeAll;
  final bool isGrid;
  final int gridColumns;
  final BorderRadius? borderRadius;
  final EdgeInsets? outerPadding;
  final double? horizontalGap;
  final double? verticalGap;

  const BrandSection({
    super.key,
    this.title = 'Shop by brand',
    this.brands = SampleSectionData.brands,
    this.style = BrandCardStyle.cards,
    this.background = const SectionBackground.none(),
    this.onSeeAll,
    this.isGrid = false,
    this.gridColumns = 3,
    this.borderRadius,
    this.outerPadding,
    this.horizontalGap,
    this.verticalGap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dec = background.toDecoration();
    final decoration = dec is BoxDecoration
        ? dec.copyWith(borderRadius: borderRadius)
        : (borderRadius != null ? BoxDecoration(borderRadius: borderRadius) : null);

    return Container(
      decoration: decoration,
      margin: outerPadding,
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared header — same in all styles.
          if (title.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _body(),
          if (onSeeAll != null)
            Center(
              child: CustomSeeAllButton(
                onTap: onSeeAll!,
                imageUrls: brands.map((b) => b.imageUrl).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (style) {
      case BrandCardStyle.cards:
        return BrandStyleOne(
          brands: brands,
          isCustomImage: false,
          isGrid: isGrid,
          crossAxisCount: gridColumns,
          borderRadius: borderRadius,
          outerPadding: null,
          horizontalGap: horizontalGap,
          verticalGap: verticalGap,
        );
      case BrandCardStyle.grid:
        return BrandStyleTwo(
          brands: brands,
          crossAxisCount: gridColumns,
          isCustomImage: false,
          isGrid: isGrid,
          borderRadius: borderRadius,
          outerPadding: null,
          horizontalGap: horizontalGap,
          verticalGap: verticalGap,
        );
      case BrandCardStyle.customImage:
        return BrandStyleTwo(
          brands: brands,
          crossAxisCount: gridColumns,
          isCustomImage: true,
          isGrid: isGrid,
          borderRadius: borderRadius,
          outerPadding: null,
          horizontalGap: horizontalGap,
          verticalGap: verticalGap,
        );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/home_page/section_gallery/widgets/categories/styles/category_cards_custom_image.dart';
import 'package:hyper_local/screens/home_page/section_gallery/widgets/categories/styles/category_cards_image.dart';
import 'package:hyper_local/utils/widgets/custom_see_all_button.dart';

import '../../data/sample_section_data.dart';
import '../../data/section_background.dart';
import 'styles/category_cards_title_overlay.dart';
import 'styles/category_cards_grid.dart';

/// Selectable card layout for the category section.
enum CategoryCardStyle { overlayTitle, grid, imageCards, customImage }

/// Category section wrapper.
/// Owns the shared section header (title + optional "See all") that stays the
/// same across every style, and renders the chosen card body underneath. Swap
/// only [style] to change the look — the header is identical each time.
class CategorySection extends StatelessWidget {
  final String title;
  final List<SampleTile> categories;
  final CategoryCardStyle style;
  final SectionBackground background;
  final VoidCallback? onSeeAll;
  final bool isGrid;
  final int gridColumns;
  final EdgeInsets? outerPadding;
  final double? horizontalGap;
  final double? verticalGap;
  final Color? textColor;

  const CategorySection({
    super.key,
    this.title = 'Shop by category',
    this.categories = SampleSectionData.categories,
    this.style = CategoryCardStyle.overlayTitle,
    this.background = const SectionBackground.none(),
    this.onSeeAll,
    this.isGrid = false,
    this.gridColumns = 3,
    this.outerPadding,
    this.horizontalGap,
    this.verticalGap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: background.toDecoration(),
      margin: outerPadding,
      padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared header — same in all styles.
          if (title.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 12.h),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor ?? scheme.onSurface,
                ),
              ),
            ),
          _body(),

          if (onSeeAll != null)
            Center(
              child: CustomSeeAllButton(
                onTap: onSeeAll!,
                imageUrls: categories.map((c) => c.imageUrl).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (style) {
      case CategoryCardStyle.overlayTitle:
        return CategoryCardsTitleOverlay(
          categories: categories,
          outerPadding: null,
          horizontalGap: horizontalGap,
          verticalGap: verticalGap,
          isGrid: isGrid,
          gridColumns: gridColumns,
        );
      case CategoryCardStyle.imageCards:
        return CategoryCardsImage(
          categories: categories,
          outerPadding: null,
          horizontalGap: horizontalGap,
          verticalGap: verticalGap,
        );
      case CategoryCardStyle.customImage:
        return CategoryCardsCustomImage(
          categories: categories,
          isGrid: isGrid,
          gridColumns: gridColumns,
          outerPadding: null,
          horizontalGap: horizontalGap,
          verticalGap: verticalGap,
        );
      case CategoryCardStyle.grid:
        return CategoryCardsGrid(
          categories: categories,
          outerPadding: null,
          horizontalGap: horizontalGap,
          verticalGap: verticalGap,
          isGrid: isGrid,
          crossAxisCount: gridColumns,
        );
    }
  }
}

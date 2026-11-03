import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import '../../../data/sample_section_data.dart';

/// Category cards — Circular style (body only, no section title).
/// Horizontal scrolling row of circular image tiles with a label underneath.
class CategoryCardsTitleOverlay extends StatelessWidget {
  final List<SampleTile> categories;
  final EdgeInsets? outerPadding;
  final double? horizontalGap;
  final double? verticalGap;
  final bool isGrid;
  final int gridColumns;

  const CategoryCardsTitleOverlay({
    super.key,
    this.categories = SampleSectionData.categories,
    this.outerPadding,
    this.horizontalGap,
    this.verticalGap,
    this.isGrid = false,
    this.gridColumns = 3,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final horizontalGapVal = horizontalGap ?? 12.0;
    final verticalGapVal = verticalGap ?? 10.0;

    if (isGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumns,
          crossAxisSpacing: horizontalGapVal.w,
          mainAxisSpacing: verticalGapVal.h,
          childAspectRatio: gridColumns == 2 ? 1.0 : (gridColumns == 3 ? 1.1 : 1.0),
        ),
        itemBuilder: (context, i) {
          final tile = categories[i];
          return GestureDetector(
            onTap: tile.onTap,
            behavior: HitTestBehavior.opaque,
            child: _buildItem(context, tile, scheme),
          );
        },
      );
    }

    return Container(
      height: 130.h,
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: horizontalGapVal.w),
        itemBuilder: (context, i) {
          final tile = categories[i];
          return GestureDetector(
            onTap: tile.onTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 125.w,
              child: _buildItem(context, tile, scheme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, SampleTile tile, ColorScheme scheme) {
    return Stack(
      children: [
        // 🔲 Image Card
        Positioned.fill(
          child: CustomImageContainer(
            imagePath: tile.imageUrl,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12.r),
            errorWidget: Icon(Icons.category_rounded, color: scheme.primary),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 50.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40.h,
            padding: const EdgeInsets.only(
              bottom: 6,
              left: 6,
              right: 6,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 📝 Text
                Expanded(
                  child: Text(
                    tile.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  height: 20,
                  width: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(TablerIcons.chevron_right, size: 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/home_page/home_layout/model/home_layout_models.dart';
import 'package:hyper_local/screens/discover_page/widgets/discover_grid_card.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import 'package:hyper_local/config/helper.dart';

class HomeReelsSection extends StatelessWidget {
  final HomeSection section;

  const HomeReelsSection({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final reels = section.reels;
    if (reels.isEmpty) return const SizedBox.shrink();

    final config = section.reelsConfig;
    final showLikes = config.showLikes;
    final showTitle = config.showTitle;
    final isGrid = section.style == 'grid';
    final outerPadding = parseOuterPadding(section.config) ??
        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
    final horizontalGap = parseItemGapHorizontal(section.config) ?? 12.0.w;

    final String? title = section.title;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorVal = section.config is Map ? (section.config as Map)['text_color'] : null;
    final Color? textColor = parseThemeColor(textColorVal, isDark);

    Widget content;

    if (isGrid) {
      content = StaggeredListAnimator.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: reels.length,
          type: StaggeredListType.masonryGridView,
          spacing: horizontalGap,
          itemBuilder: (context, index) {
            final item = reels[index];
            return DiscoverGridCard(
              item: item,
              index: index,
              reelsItems: reels,
              showLikes: showLikes,
              showTitle: showTitle,
              onLikeToggled: () {},
            );
          },
        );
    } else {
      // Use height and width specifically for card slider on home layout
      final double cardHeight = 200.0.h;
      final double cardWidth = 140.0.w;

      content = SizedBox(
        height: cardHeight,
        width: double.infinity,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final item = reels[index];

            return Padding(
              padding: EdgeInsets.only(
                  right: index == reels.length - 1 ? 0 : horizontalGap),
              child: DiscoverGridCard(
                item: item,
                index: index,
                reelsItems: reels,
                height: cardHeight,
                width: cardWidth,
                showLikes: showLikes,
                showTitle: showTitle,
                onLikeToggled: () {
                  // Here we can either dispatch a like event to a bloc or handle locally.
                  // Assuming it's view only or we dispatch to the discover bloc if needed.
                },
              ),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (title != null && title.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.w, 16.w, 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: outerPadding,
            child: content,
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hyper_local/screens/home_page/home_layout/model/home_layout_models.dart';

import 'play_image_row_widget.dart';

class PlayImageSection extends StatelessWidget {
  final HomeSection section;
  final void Function(PlayImageItem item)? onItemTap;

  const PlayImageSection({
    super.key,
    required this.section,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = section.playImageRows;
    if (rows.isEmpty) return const SizedBox.shrink();

    final config = section.playImageConfig;
    final outerPadding = config.outerPadding > 0 ? config.outerPadding : 0.0;
    final gridGap = config.gridGap > 0 ? config.gridGap : 0.0;
    final borderRadius = config.borderRadius > 0 ? config.borderRadius : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: outerPadding.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title != null && section.title!.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                section.title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0 && gridGap > 0) SizedBox(height: gridGap.h),
            PlayImageRowWidget(
              row: rows[i],
              sectionGridGap: gridGap,
              sectionBorderRadius: borderRadius,
              onItemTap: onItemTap,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/home_page/home_layout/model/home_layout_models.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class PlayImageItemCard extends StatelessWidget {
  final PlayImageItem item;
  final double borderRadius;
  final void Function(PlayImageItem item)? onTap;

  const PlayImageItemCard({
    super.key,
    required this.item,
    this.borderRadius = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final imageUrl = (!isTablet && (item.mobileImage?.isNotEmpty ?? false))
        ? item.mobileImage!
        : item.image;

    if (imageUrl.isEmpty) return const SizedBox.shrink();

    final parsedAspectRatio = item.config.parsedAspectRatio;

    Widget imageWidget = CustomImageContainer(
      imagePath: imageUrl,
      fit: parsedAspectRatio != null ? BoxFit.cover : BoxFit.fitWidth,
    );

    if (parsedAspectRatio != null) {
      imageWidget = AspectRatio(
        aspectRatio: parsedAspectRatio,
        child: imageWidget,
      );
    }

    return GestureDetector(
      onTap: () => onTap?.call(item),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: imageWidget,
      ),
    );
  }


}

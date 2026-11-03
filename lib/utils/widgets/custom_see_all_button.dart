import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class CustomSeeAllButton extends StatelessWidget {
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final List<String> imageUrls;

  const CustomSeeAllButton({
    super.key,
    required this.onTap,
    this.margin,
    this.padding,
    this.imageUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    Widget? overlappingImagesWidget;
    final displayImages = imageUrls.where((url) => url.isNotEmpty).take(3).toList();
    if (displayImages.isNotEmpty) {
      final double avatarSize = isTablet(context) ? 32.h : 24.h;
      final double overlapAmount = isTablet(context) ? 20.w : 12.w;

      overlappingImagesWidget = Padding(
        padding: EdgeInsetsDirectional.only(end: 8.w),
        child: SizedBox(
          width: avatarSize + (displayImages.length - 1) * (avatarSize - overlapAmount),
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(displayImages.length, (index) {
              return PositionedDirectional(
                start: index * (avatarSize - overlapAmount),
                child: Container(
                  height: avatarSize,
                  width: avatarSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(width: 0.2.w, color: Colors.grey.withValues(alpha: .5)),
                  ),
                  child: ClipOval(
                    child: CustomImageContainer(
                      imagePath: displayImages[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFEAECF2),
          ),
          borderRadius: BorderRadius.circular(6),
          color: isDarkMode(context) ? const Color(0xFF1A1A1A) : const Color(0xFFF3F5F7),
        ),
        padding: padding ?? const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (overlappingImagesWidget != null) overlappingImagesWidget,
            Text(
              context.tr('seeAll'),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isTablet(context) ? 18 : 14,
              ),
            ),
            const Icon(Icons.arrow_right_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

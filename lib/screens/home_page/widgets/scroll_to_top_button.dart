import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hyper_local/config/helper.dart';
class ScrollToTopButton extends StatelessWidget {
  final VoidCallback onScrollToTop;

  const ScrollToTopButton({
    super.key,
    required this.onScrollToTop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onScrollToTop,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.5.h),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDarkMode(context) ? Colors.black.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.3),
              blurRadius: isDarkMode(context) ? 10 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(20.r),
          color: isDarkMode(context) ? Colors.white : Colors.black,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('backToTop'),
              style: TextStyle(
                color: isDarkMode(context) ? Colors.black : Colors.white,
                fontSize: isTablet(context) ? 20 : 13.sp,
              ),
            ),
            SizedBox(width: 4.w),
            HugeIcon(
              icon: HugeIcons.strokeRoundedCircleArrowUp02,
              size: isTablet(context) ? 25 : 16.sp,
              color: isDarkMode(context) ? Colors.black : Colors.white,
            )
          ],
        ),
      ),
    );
  }
}

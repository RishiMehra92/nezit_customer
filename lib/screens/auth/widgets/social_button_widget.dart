import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/animated_button.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import '../../../config/helper.dart';

enum LoginType {
  google,
  apple,
  mobile
}

Widget socialButton({
  required VoidCallback onTap,
  String? asset,
  IconData? icon,
  Color? iconColor,
  required Color background,
  required Color borderColor,
  required LoginType type,
  required BuildContext context,
}) {
  String buttonText;
  switch (type) {
    case LoginType.google:
      buttonText = context.tr('continueWithGoogle');
      break;
    case LoginType.apple:
      buttonText = context.tr('continueWithApple');
      break;
    case LoginType.mobile:
      buttonText = context.tr('continueWithMobile');
      break;
  }

  return AnimatedButton(
    onTap: onTap,
    child: Container(
      height: 40.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          asset != null
              ? CustomImageContainer(
                  imagePath:  asset,
                  height: 24.h,
                  width: 24.w,
                  fit: BoxFit.contain,
                )
              : Icon(icon, size: 25.sp, color: iconColor),
          SizedBox(width: 10.w,),
          Text(
            buttonText,
            style: TextStyle(
              fontSize: isTablet(context) ? 24 : 14
            ),
          )
        ],
      )
    ),
  );
}
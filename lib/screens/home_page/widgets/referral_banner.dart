import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import '../../../config/helper.dart';

class ReferralBanner extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const ReferralBanner({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: isDarkMode(context) ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: isDarkMode(context) ? Colors.white : Colors.black,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('haveReferralCodeTitle'),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode(context) ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            context.tr('haveReferralCodeSubtitle'),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.sp,
                              color: isDarkMode(context) ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onNo,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Text(
                              context.tr('no'),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode(context) ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: onYes,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Text(
                              context.tr('yes'),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor, 
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }
}

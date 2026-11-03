import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../config/helper.dart';
import '../../../config/theme.dart';

class OrderNoteDisplayWidget extends StatelessWidget {
  final String? orderNote;
  final EdgeInsets? margin;

  const OrderNoteDisplayWidget({
    super.key,
    this.orderNote,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {

    // If no note, show nothing (or optional placeholder)
    if (orderNote == null || orderNote!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: margin ?? EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                TablerIcons.note,
                size: 20.sp,
                color: isDarkMode(context) ? const Color(0xFF64B5F6) : AppTheme.primaryColor,
              ),
              SizedBox(width: 10.w),
              Text(
                "Order Note",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // Note content
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDarkMode(context)
                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
            child: Text(
              orderNote!.trim(),
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.5,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
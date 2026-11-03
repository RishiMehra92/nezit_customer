import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderAddressCard extends StatelessWidget {
  final String label;
  final String address;
  final String? addressType;

  const OrderAddressCard({
    super.key,
    required this.label,
    required this.address,
    this.addressType,
  });

  @override
  Widget build(BuildContext context) {
    final chip = _addressTypeLabel(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (chip != null)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    chip,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            address,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String? _addressTypeLabel(BuildContext context) {
    final type = addressType?.toLowerCase().trim();
    if (type == null || type.isEmpty) return null;
    switch (type) {
      case 'home':
        return context.tr('addressTypeHome', fallback: 'HOME');
      case 'work':
      case 'office':
        return context.tr('addressTypeWork', fallback: 'WORK');
      default:
        return context.tr('addressTypeOther', fallback: type.toUpperCase());
    }
  }
}

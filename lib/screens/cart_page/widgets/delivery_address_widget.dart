import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/theme.dart';
import '../../../config/helper.dart';
import '../../address_list_page/model/get_address_list_model.dart';

class DeliveryAddressWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final AddressListData? selectedAddress;

  const DeliveryAddressWidget({
    super.key,
    this.onTap,
    this.selectedAddress,
  });

  @override
  State<DeliveryAddressWidget> createState() => _DeliveryAddressWidgetState();
}

class _DeliveryAddressWidgetState extends State<DeliveryAddressWidget> {

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final displayAddress = widget.selectedAddress != null 
        ? formatAddressFromModel(widget.selectedAddress!)
        : null;
    final accentColor = dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: dark ? AppTheme.mainDarkContainerBgColor : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
            width: 1,
          ),
          bottom: BorderSide(
            color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          children: [
            // Location pin icon badge
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: dark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Icon(
                  TablerIcons.map_pin_filled,
                  color: accentColor,
                  size: isTablet(context) ? 22.r : 18.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Address content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('deliverTo', fallback: 'Deliver to'),
                    style: TextStyle(
                      fontSize: isTablet(context) ? 16 : 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: dark ? Colors.white60 : Colors.grey.shade600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    displayAddress ?? '',
                    style: TextStyle(
                      fontSize: isTablet(context) ? 16 : 13.sp,
                      color: dark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 10.w),
            // Change button pill
            InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: dark
                      ? AppTheme.primaryColor.withValues(alpha: 0.18)
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: dark
                        ? const Color(0xFF64B5F6).withValues(alpha: 0.35)
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('change', fallback: 'Change'),
                      style: TextStyle(
                        fontSize: isTablet(context) ? 16 : 12.sp,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14.sp,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


String formatAddressFromModel(AddressListData address) {
  List<String> addressParts = [];

  if (address.addressLine1?.isNotEmpty == true) {
    addressParts.add(address.addressLine1!);
  }
  if (address.addressLine2?.isNotEmpty == true) {
    addressParts.add(address.addressLine2!);
  }
  if (address.city?.isNotEmpty == true) {
    addressParts.add(address.city!);
  }
  if (address.state?.isNotEmpty == true) {
    addressParts.add(address.state!);
  }
  if (address.zipcode?.isNotEmpty == true) {
    addressParts.add(address.zipcode!);
  }
  if (address.country?.isNotEmpty == true) {
    addressParts.add(address.country!);
  }

  return addressParts.join(', ');
}
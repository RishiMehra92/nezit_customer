import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'package:hyper_local/screens/address_list_page/model/get_address_list_model.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';

import '../../../config/helper.dart';
import '../../../router/app_routes.dart';

class AddressSelectionBottomSheet extends StatefulWidget {
  final Function(AddressListData) onAddressSelected;
  final AddressListData? selectedAddress;
  final int? deliveryZoneId;

  const AddressSelectionBottomSheet({
    super.key,
    required this.onAddressSelected,
    this.selectedAddress,
    this.deliveryZoneId,
  });

  @override
  State<AddressSelectionBottomSheet> createState() =>
      _AddressSelectionBottomSheetState();
}

class _AddressSelectionBottomSheetState
    extends State<AddressSelectionBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Only pass deliveryZoneId if available (for checkout in cart page)
    context
        .read<GetAddressListBloc>()
        .add(FetchUserAddressList(deliveryZoneId: widget.deliveryZoneId));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDarkMode(context)
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.only(
                left: 12.0.w, right: 12.0.w, top: 12.h, bottom: 12.h),
            child: Row(
              children: [
                Text(
                  'Select Delivery Address',
                  style: TextStyle(
                    fontSize: isTablet(context) ? 24 : 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                    size: isTablet(context) ? 20.h : 24.sp,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () async {
                await GoRouter.of(context).push(
                  AppRoutes.locationPicker,
                  extra: {'isFromAddressPage': true, 'isEdit': false},
                );
                if (context.mounted) {
                  context.read<GetAddressListBloc>().add(
                        FetchUserAddressList(
                            deliveryZoneId: widget.deliveryZoneId),
                      );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                decoration: BoxDecoration(
                  color: isDarkMode(context)
                      ? Theme.of(context).colorScheme.onSecondary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      TablerIcons.plus,
                      color: AppTheme.primaryColor,
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('addNewAddress'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      TablerIcons.chevron_right,
                      size: 22,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Address list
          Expanded(
            child: BlocBuilder<GetAddressListBloc, GetAddressListState>(
              builder: (context, state) {
                if (state is GetAddressListLoading) {
                  return _buildLoadingState();
                } else if (state is GetAddressListLoaded) {
                  return _buildAddressList(state);
                } else if (state is GetAddressListFailed) {
                  return _buildErrorState(state.error);
                } else {
                  return _buildEmptyState();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.sp),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.sp),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12.sp),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressList(GetAddressListLoaded state) {
    if (state.addressList.isEmpty) {
      return _buildEmptyState();
    }

    final sortedAddresses = List<AddressListData>.from(state.addressList)
      ..sort((a, b) {
        final aSelected = widget.selectedAddress?.id == a.id;
        final bSelected = widget.selectedAddress?.id == b.id;
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;

        final aDeliverable = a.isDeliverable != false;
        final bDeliverable = b.isDeliverable != false;
        if (aDeliverable && !bDeliverable) return -1;
        if (!aDeliverable && bDeliverable) return 1;
        return 0;
      });

    return StaggeredListAnimator(
      type: StaggeredListType.listView,
      shrinkWrap: false,
      padding:
          EdgeInsets.only(left: 12.0.w, right: 12.0.w, top: 12.h, bottom: 12.h),
      children: sortedAddresses.map((address) {
        final isDeliverable = address.isDeliverable != false;
        return _buildAddressCard(address, isDeliverable);
      }).toList(),
    );
  }

  Widget _buildAddressCard(AddressListData address, bool isDeliverable) {
    final isSelected = widget.selectedAddress?.id == address.id;

    return GestureDetector(
      onTap: isDeliverable
          ? () {
              widget.onAddressSelected(address);
              Navigator.pop(context);
            }
          : null,
      child: Opacity(
        opacity: isDeliverable ? 1.0 : 0.5,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.sp),
          decoration: BoxDecoration(
            color: isDarkMode(context)
                ? AppTheme.darkProductCardColor
                : Colors.white,
            borderRadius: BorderRadius.circular(12.sp),
            border: Border.all(
              color: isSelected && isDeliverable
                  ? AppTheme.primaryColor
                  : Colors.grey.withValues(alpha: 0.3),
              width: isSelected && isDeliverable ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Address type header
              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                decoration: BoxDecoration(
                  color: isSelected && isDeliverable
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.sp),
                    topRight: Radius.circular(12.sp),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.sp),
                      decoration: BoxDecoration(
                        color: _getAddressTypeColor(address.addressType)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      child: Text(
                        address.addressType ?? 'Other',
                        style: TextStyle(
                          color: _getAddressTypeColor(address.addressType),
                          fontSize: isTablet(context) ? 16 : 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected && isDeliverable)
                      Icon(
                        TablerIcons.circle_check,
                        color: AppTheme.primaryColor,
                        size: isTablet(context) ? 10.sp : 20.sp,
                      ),
                    if (!isDeliverable)
                      Row(
                        children: [
                          Icon(
                            TablerIcons.alert_circle,
                            color: Colors.red[700],
                            size: isTablet(context) ? 18 : 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Unavailable',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: isTablet(context) ? 14 : 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Address details
              Padding(
                padding: EdgeInsets.only(
                    left: 12.0.w, right: 12.0.w, top: 12.h, bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      TablerIcons.map_pin,
                      size: isTablet(context) ? 24 : 16.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAddress(address),
                            style: TextStyle(
                              fontSize: isTablet(context) ? 18 : 14.sp,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 8.sp),
                          Row(
                            children: [
                              Icon(
                                TablerIcons.phone,
                                size: isTablet(context) ? 24 : 14.sp,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4.sp),
                              Text(
                                address.mobile ?? 'No phone',
                                style: TextStyle(
                                  fontSize: isTablet(context) ? 18 : 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIcons.alert_circle,
            size: 48.sp,
            color: Colors.red,
          ),
          SizedBox(height: 16.sp),
          Text(
            'Failed to load addresses',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            error,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TablerIcons.map_pin_off,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24.sp),
            Text(
              'No addresses found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Add a new address to continue',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.sp),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to add address page
                Navigator.pushNamed(context, '/add-address');
              },
              icon: Icon(
                TablerIcons.plus,
                size: 20.sp,
              ),
              label: Text(
                'Add New Address',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 32.sp,
                  vertical: 16.sp,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.sp),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(AddressListData address) {
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

  Color _getAddressTypeColor(String? addressType) {
    switch (addressType?.toLowerCase()) {
      case 'home':
        return Colors.green;
      case 'office':
        return Colors.blue;
      case 'other':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

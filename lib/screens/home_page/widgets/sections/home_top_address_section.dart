import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hive_flutter/adapters.dart';
import '../location_bottom_sheet.dart';

class HomeTopAddressSection extends StatelessWidget {
  final Color? textColor;
  final ValueChanged<String?> onLocationChanged;

  const HomeTopAddressSection({
    super.key,
    required this.textColor,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<dynamic>('userLocationBox').listenable(),
      builder: (context, Box<dynamic> box, _) {
        final storedLocation = box.get('user_location');
        final locationIdentifier = storedLocation == null
            ? null
            : '${storedLocation.latitude}_${storedLocation.longitude}_${storedLocation.fullAddress}_${storedLocation.area}_${storedLocation.city}_${storedLocation.pincode}';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            onLocationChanged(locationIdentifier);
          }
        });

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => showHomeLocationBottomSheet(
                  context,
                  verticalPadding: 50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180.w,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            TablerIcons.map_pin_filled,
                            size: 22,
                            color: textColor,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              (storedLocation != null && storedLocation.area != null && storedLocation.area.toString().trim().isNotEmpty)
                                  ? storedLocation.area
                                  : (storedLocation != null && storedLocation.city != null && storedLocation.city.toString().trim().isNotEmpty)
                                      ? storedLocation.city
                                      : (storedLocation != null && storedLocation.fullAddress != null && storedLocation.fullAddress.toString().trim().isNotEmpty)
                                          ? storedLocation.fullAddress
                                          : (context.tr('selectLocation', fallback: 'Select Location')),
                              style: TextStyle(
                                fontSize: 15,
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            TablerIcons.chevron_down,
                            size: 20,
                            color: textColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 230.w,
                      child: Text(
                        (storedLocation != null && storedLocation.fullAddress != null && storedLocation.fullAddress.toString().trim().isNotEmpty)
                            ? storedLocation.fullAddress
                            : (context.tr('chooseAddressForDelivery', fallback: 'Choose address for delivery')),
                        style: TextStyle(
                          fontSize: 13,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

void showHomeLocationBottomSheet(
  BuildContext context, {
  double verticalPadding = 30,
}) {
  showModalBottomSheet(
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (context) => const LocationBottomSheet(),
  );
}

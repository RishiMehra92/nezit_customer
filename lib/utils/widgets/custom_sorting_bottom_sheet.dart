import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/helper.dart';
import '../../model/sorting_model/sorting_model.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';

class CustomSortBottomSheet extends StatefulWidget {
  final SortType currentSortType;
  final bool isFromStore;
  final Function(SortOption) onSortSelected;

  const CustomSortBottomSheet({
    super.key,
    required this.currentSortType,
    this.isFromStore = false,
    required this.onSortSelected,
  });

  @override
  State<CustomSortBottomSheet> createState() => _CustomSortBottomSheetState();

  static void show({
    required BuildContext context,
    required SortType currentSortType,
    required Function(SortOption) onSortSelected,
    bool isFromStore = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CustomSortBottomSheet(
        currentSortType: currentSortType,
        onSortSelected: onSortSelected,
        isFromStore: isFromStore,
      ),
    );
  }
}

class _CustomSortBottomSheetState extends State<CustomSortBottomSheet> {
  late SortType selectedSortType;

  @override
  void initState() {
    super.initState();
    selectedSortType = widget.currentSortType;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(14.r),
        topRight: Radius.circular(14.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('sortBy', fallback: 'Sort by'),
                    style: TextStyle(
                      fontSize: isTablet(context) ? 24 : 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: isDarkMode(context) ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                  ),
                  icon: const Icon(TablerIcons.x, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1.h, color: Theme.of(context).colorScheme.outlineVariant),

          // Sort options
          Flexible(
            child: RadioGroup<SortType>(
              groupValue: selectedSortType,
              onChanged: (SortType? value) {
                if (value != null) {
                  setState(() {
                    selectedSortType = value;
                  });
                  final sortOption = widget.isFromStore
                      ? SortOption.sortOptionsForStores.firstWhere(
                          (option) => option.type == value,
                        )
                      : SortOption.sortOptions.firstWhere(
                          (option) => option.type == value,
                        );
                  widget.onSortSelected(sortOption);
                  Navigator.pop(context);
                }
              },
              child: StaggeredListAnimator(
                type: StaggeredListType.listView,
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                children:
                    (widget.isFromStore ? SortOption.sortOptionsForStores : SortOption.sortOptions).map((sortOption) {
                  final isSelected = selectedSortType == sortOption.type;

                  return RadioListTile<SortType>(
                    key: ValueKey(sortOption.type),
                    title: Text(
                      sortOption.displayName,
                      style: TextStyle(
                        fontSize: isTablet(context) ? 20 : 14.sp,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppTheme.primaryColor : Colors.grey,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    value: sortOption.type,
                    radioScaleFactor: 1.0,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryColor;
                      }
                      return AppTheme.primaryColor;
                    }),
                    activeColor: AppTheme.primaryColor, // Color of the selected radio
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                    dense: true, // Makes it tighter vertically
                    visualDensity: VisualDensity.compact, // Optional: even more compact
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// lib/screens/my_orders/widgets/order_filter_sheet.dart

import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../model/order_filter_model.dart';

class OrderFilterSheet extends StatefulWidget {
  final List<String> dateOptions; // from settings API
  final List<String> sortOptions; // from settings API
  final OrderFilter currentFilter;
  final ValueChanged<OrderFilter> onApply;

  const OrderFilterSheet({
    super.key,
    required this.dateOptions,
    required this.sortOptions,
    required this.currentFilter,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required List<String> dateOptions,
    required List<String> sortOptions,
    required OrderFilter currentFilter,
    required ValueChanged<OrderFilter> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => OrderFilterSheet(
        dateOptions: dateOptions,
        sortOptions: sortOptions,
        currentFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<OrderFilterSheet> {
  String? _selectedDateFilter;
  String? _selectedStatusSort;
  String? _selectedDeliveryType;
  bool _isScheduled = false;

  @override
  void initState() {
    super.initState();
    _selectedDateFilter = widget.currentFilter.selectedDateFilter;
    _selectedStatusSort = widget.currentFilter.selectedStatusSort;
    _selectedDeliveryType = widget.currentFilter.selectedDeliveryType;
    _isScheduled = widget.currentFilter.isScheduled;
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_selectedDateFilter == status) {
        _selectedDateFilter = null;
      } else {
        _selectedDateFilter = status;
      }
    });
  }

  void _toggleSort(String sort) {
    setState(() {
      if (_selectedStatusSort == sort) {
        _selectedStatusSort = null;
      } else {
        _selectedStatusSort = sort;
      }
    });
  }

  void _toggleDeliveryType(String type) {
    setState(() {
      if (_selectedDeliveryType == type) {
        _selectedDeliveryType = null;
      } else {
        _selectedDeliveryType = type;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedDateFilter = null;
      _selectedStatusSort = null;
      _selectedDeliveryType = null;
      _isScheduled = false;
    });
    widget.onApply(OrderFilter(
      selectedDateFilter: _selectedDateFilter,
      selectedStatusSort: _selectedStatusSort,
      selectedDeliveryType: _selectedDeliveryType,
      isScheduled: _isScheduled,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: kToolbarHeight),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr('filters'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: _clearAll,
                  child: Text(context.tr('clearAll')),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: StaggeredListAnimator(
                type: StaggeredListType.column,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Section 1: Order Status (single-select) ---
                  _SectionLabel(label: context.tr('dateRange')),
                  _ChipWrap(
                    options: widget.dateOptions,
                    selected: _selectedDateFilter != null ? {_selectedDateFilter!} : {},
                    onTap: _toggleStatus,
                  ),

                  const SizedBox(height: 8),

                  // --- Section 2: Sort By (single-select) ---
                  _SectionLabel(label: context.tr('sortBy')),
                  _ChipWrap(
                    options: widget.sortOptions,
                    selected: _selectedStatusSort != null ? {_selectedStatusSort!} : {},
                    onTap: _toggleSort,
                    singleSelect: true,
                  ),

                  const SizedBox(height: 8),

                  // --- Section 3: Delivery Type (single-select) ---
                  _SectionLabel(label: context.tr('deliveryType')),
                  _ChipWrap(
                    options: const ['pos', 'regular', 'pickup'],
                    selected: _selectedDeliveryType != null ? {_selectedDeliveryType!} : {},
                    onTap: _toggleDeliveryType,
                    singleSelect: true,
                  ),

                  const SizedBox(height: 8),

                  _SectionLabel(label: context.tr('deliverySchedule', fallback: 'Delivery Schedule')),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilterChip(
                      label: Text(
                        context.tr('scheduledOrders', fallback: 'Scheduled Orders'),
                        style: TextStyle(
                          color: _isScheduled ? Colors.white : null,
                        ),
                      ),
                      selected: _isScheduled,
                      onSelected: (selected) {
                        setState(() {
                          _isScheduled = selected;
                        });
                      },
                      showCheckmark: false,
                      color: WidgetStatePropertyAll(
                          _isScheduled ? AppTheme.primaryColor.withValues(alpha: 0.8) : Colors.transparent),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Apply button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: () {
                          widget.onApply(OrderFilter(
                            selectedDateFilter: _selectedDateFilter,
                            selectedStatusSort: _selectedStatusSort,
                            selectedDeliveryType: _selectedDeliveryType,
                            isScheduled: _isScheduled,
                          ));
                          Navigator.pop(context);
                        },
                        child: Text(context.tr('applyFilters'), style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  final bool singleSelect;

  const _ChipWrap({
    required this.options,
    required this.selected,
    required this.onTap,
    this.singleSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = selected.contains(option);
          String labelText;
          if (option.toLowerCase() == 'pos') {
            labelText = 'POS';
          } else if (option.toLowerCase() == 'regular') {
            labelText = 'Delivery';
          } else {
            labelText = removeUnderscores(capitalizeFirstLetter(option));
          }
          return FilterChip(
            label: Text(
              labelText,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onTap(option),
            showCheckmark: false,
            color:
                WidgetStatePropertyAll(isSelected ? AppTheme.primaryColor.withValues(alpha: 0.8) : Colors.transparent),
          );
        }).toList(),
      ),
    );
  }
}

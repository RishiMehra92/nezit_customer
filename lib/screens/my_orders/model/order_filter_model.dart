class OrderFilter {
  final String? selectedDateFilter;
  final String? selectedStatusSort;
  final String? selectedDeliveryType;
  final bool isScheduled;

  const OrderFilter({
    this.selectedDateFilter,
    this.selectedStatusSort,
    this.selectedDeliveryType,
    this.isScheduled = false,
  });

  OrderFilter copyWith({
    String? selectedStatuses,
    String? selectedSort,
    String? selectedDelivery,
    bool? isScheduledVal,
  }) {
    return OrderFilter(
      selectedDateFilter: selectedStatuses ?? selectedDateFilter,
      selectedStatusSort: selectedSort ?? selectedStatusSort,
      selectedDeliveryType: selectedDelivery ?? selectedDeliveryType,
      isScheduled: isScheduledVal ?? isScheduled,
    );
  }

  int get activeCount =>
      (selectedDateFilter != null ? 1 : 0) +
      (selectedStatusSort != null ? 1 : 0) +
      (selectedDeliveryType != null ? 1 : 0) +
      (isScheduled ? 1 : 0);

  bool get hasFilters => activeCount > 0;
}
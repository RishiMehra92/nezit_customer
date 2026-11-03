import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:hyper_local/config/theme.dart';

class DeliveryDatePicker extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  final int maxDays;
  final List<String>? availableDays;

  const DeliveryDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.maxDays,
    this.availableDays,
  });

  @override
  State<DeliveryDatePicker> createState() => _DeliveryDatePickerState();
}

class _DeliveryDatePickerState extends State<DeliveryDatePicker> {
  late final DateRangePickerController _datePickerController;
  String _headerText = '';
  late DateTime _currentDisplayDate;

  @override
  void initState() {
    super.initState();
    _currentDisplayDate = widget.selectedDate ?? DateTime.now();
    _datePickerController = DateRangePickerController();
    _datePickerController.displayDate = _currentDisplayDate;
    _datePickerController.selectedDate = widget.selectedDate;
    _headerText = DateFormat('MMMM yyyy').format(_currentDisplayDate);
  }

  @override
  void didUpdateWidget(covariant DeliveryDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDate(oldWidget.selectedDate, widget.selectedDate)) {
      _datePickerController.selectedDate = widget.selectedDate;
      if (widget.selectedDate != null) {
        _datePickerController.displayDate = widget.selectedDate!;
      }
    }
  }

  bool isSameDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == null && b == null;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _datePickerController.dispose();
    super.dispose();
  }

  void _onViewChanged(DateRangePickerViewChangedArgs args) {
    final DateTime visibleDate = args.visibleDateRange.startDate!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentDisplayDate = visibleDate;
          _headerText = DateFormat('MMMM yyyy').format(visibleDate);
        });
      }
    });
  }

  bool _isDateSelectable(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (date.isBefore(today)) return false;

    final maxDate = today.add(Duration(days: widget.maxDays - 1));
    if (date.isAfter(maxDate)) return false;

    if (widget.availableDays != null && widget.availableDays!.isNotEmpty) {
      final List<String> weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      final String weekdayName = weekdays[date.weekday % 7];
      final cleanAvailableDays = widget.availableDays!
          .map((day) => day.trim().toLowerCase())
          .toList();
      return cleanAvailableDays.contains(weekdayName.toLowerCase());
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    const primary = AppTheme.primaryColor;

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final lastDayOfPrevMonth = DateTime(_currentDisplayDate.year, _currentDisplayDate.month, 0);
    final bool canGoBackward = lastDayOfPrevMonth.isAfter(today) || lastDayOfPrevMonth.isAtSameMomentAs(today);

    final firstDayOfNextMonth = DateTime(_currentDisplayDate.year, _currentDisplayDate.month + 1, 1);
    final maxDate = today.add(Duration(days: widget.maxDays - 1));
    final bool canGoForward = firstDayOfNextMonth.isBefore(maxDate) || firstDayOfNextMonth.isAtSameMomentAs(maxDate);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF22223A) : const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: dark ? Colors.white10 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Month Navigation Header ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: Icons.chevron_left_rounded,
                enabled: canGoBackward,
                onTap: () => _datePickerController.backward!(),
              ),
              Text(
                _headerText,
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF111827),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                enabled: canGoForward,
                onTap: () => _datePickerController.forward!(),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // ── Day Name Row ────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
                final String weekdayFull = {
                  'Sun': 'Sunday',
                  'Mon': 'Monday',
                  'Tue': 'Tuesday',
                  'Wed': 'Wednesday',
                  'Thu': 'Thursday',
                  'Fri': 'Friday',
                  'Sat': 'Saturday',
                }[day]!;

                final bool isAvailable = widget.availableDays == null ||
                    widget.availableDays!.isEmpty ||
                    widget.availableDays!
                        .map((e) => e.trim().toLowerCase())
                        .contains(weekdayFull.toLowerCase());

                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isAvailable
                            ? (dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                            : (dark ? Colors.grey[700] : Colors.grey[300]),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Calendar Grid ───────────────────────────────────
          SizedBox(
            height: 200.h,
            child: SfDateRangePicker(
              controller: _datePickerController,
              headerHeight: 0,
              onViewChanged: _onViewChanged,
              backgroundColor: Colors.transparent,
              view: DateRangePickerView.month,
              selectionMode: DateRangePickerSelectionMode.single,
              initialSelectedDate: widget.selectedDate,
              minDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
              maxDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
                  .add(Duration(days: widget.maxDays - 1)),
              selectableDayPredicate: _isDateSelectable,
              onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                if (args.value is DateTime) {
                  final selectedDate = args.value as DateTime;
                  if (isSameDate(selectedDate, widget.selectedDate)) {
                    widget.onDateSelected(null);
                    _datePickerController.selectedDate = null;
                  } else {
                    widget.onDateSelected(selectedDate);
                  }
                } else {
                  widget.onDateSelected(null);
                }
              },
              monthViewSettings: const DateRangePickerMonthViewSettings(
                showTrailingAndLeadingDates: false,
                viewHeaderHeight: 0,
              ),
              cellBuilder: (BuildContext context, DateRangePickerCellDetails details) {
                final displayDate = _datePickerController.displayDate ?? widget.selectedDate ?? DateTime.now();
                final bool isCurrentMonth = details.date.month == displayDate.month;
                if (!isCurrentMonth) return const SizedBox.shrink();

                final bool isSelected = widget.selectedDate != null &&
                    widget.selectedDate!.year == details.date.year &&
                    widget.selectedDate!.month == details.date.month &&
                    widget.selectedDate!.day == details.date.day;

                final todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                final bool isToday = details.date.year == todayDate.year &&
                    details.date.month == todayDate.month &&
                    details.date.day == todayDate.day;

                final bool isSelectable = _isDateSelectable(details.date);

                Color textColor;
                FontWeight fontWeight;
                BoxDecoration? deco;

                if (isSelected) {
                  deco = BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  );
                  textColor = Colors.white;
                  fontWeight = FontWeight.w800;
                } else if (!isSelectable) {
                  textColor = dark ? Colors.grey[700]! : Colors.grey[300]!;
                  fontWeight = FontWeight.w400;
                } else if (isToday) {
                  deco = BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primary, width: 1.5),
                  );
                  textColor = primary;
                  fontWeight = FontWeight.w700;
                } else {
                  textColor = dark ? Colors.white : const Color(0xFF1F2937);
                  fontWeight = FontWeight.w500;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: deco,
                  child: Text(
                    details.date.day.toString(),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: fontWeight,
                      fontSize: 12.sp,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.25,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: enabled
                ? AppTheme.primaryColor.withValues(alpha: 0.10)
                : (dark ? Colors.white10 : Colors.grey.shade100),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20.sp, color: enabled ? AppTheme.primaryColor : Colors.grey),
        ),
      ),
    );
  }
}

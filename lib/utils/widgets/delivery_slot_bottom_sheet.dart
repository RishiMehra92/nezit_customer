import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/cart_page/model/get_cart_model.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/delivery_date_picker.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';

class DeliverySlotBottomSheet extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialTimeSlot;
  final int? initialTimeSlotId;
  final int maxDays;
  final List<String>? availableDays;
  final Future<List<DeliverySlot>> Function(DateTime date) onFetchSlots;
  final String? rescheduleDeadline;
  final bool showCancelOrderButton;

  const DeliverySlotBottomSheet({
    super.key,
    required this.initialDate,
    required this.initialTimeSlot,
    this.initialTimeSlotId,
    required this.maxDays,
    this.availableDays,
    required this.onFetchSlots,
    this.rescheduleDeadline,
    this.showCancelOrderButton = false,
  });

  static Future<dynamic> show({
    required BuildContext context,
    required DateTime? initialDate,
    required String? initialTimeSlot,
    int? initialTimeSlotId,
    required int maxDays,
    List<String>? availableDays,
    required Future<List<DeliverySlot>> Function(DateTime date) onFetchSlots,
    String? rescheduleDeadline,
    bool showCancelOrderButton = false,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => DeliverySlotBottomSheet(
        initialDate: initialDate,
        initialTimeSlot: initialTimeSlot,
        initialTimeSlotId: initialTimeSlotId,
        maxDays: maxDays,
        availableDays: availableDays,
        onFetchSlots: onFetchSlots,
        rescheduleDeadline: rescheduleDeadline,
        showCancelOrderButton: showCancelOrderButton,
      ),
    );
  }

  @override
  State<DeliverySlotBottomSheet> createState() => _DeliverySlotBottomSheetState();
}

class _DeliverySlotBottomSheetState extends State<DeliverySlotBottomSheet> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  int? _selectedTimeSlotId;
  bool _isLoadingSlots = false;
  List<DeliverySlot> _availableSlots = [];

  String _formattedDeadline() {
    if (widget.rescheduleDeadline == null || widget.rescheduleDeadline!.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(widget.rescheduleDeadline!);
      return DateFormat('dd-MMM-yy').format(parsedDate);
    } catch (_) {
      return widget.rescheduleDeadline!;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? _getFirstSelectableDate();
    _selectedTimeSlot = widget.initialTimeSlot;
    _selectedTimeSlotId = widget.initialTimeSlotId;
    if (_selectedDate != null) {
      _fetchSlotsForDate(_selectedDate!);
    }
  }

  Future<void> _fetchSlotsForDate(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _availableSlots = [];
      _selectedTimeSlot = null;
      _selectedTimeSlotId = null;
    });

    List<DeliverySlot> slots = [];
    try {
      slots = await widget.onFetchSlots(date);
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _isLoadingSlots = false;
      _availableSlots = slots;
    });
  }

  DateTime? _getFirstSelectableDate() {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final int limit = widget.maxDays;

    for (int i = 0; i < limit; i++) {
      final date = today.add(Duration(days: i));
      bool isSelectable = true;
      if (widget.availableDays != null && widget.availableDays!.isNotEmpty) {
        final List<String> weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        final String weekdayName = weekdays[date.weekday % 7];
        final cleanAvailableDays = widget.availableDays!.map((day) => day.trim().toLowerCase()).toList();
        isSelectable = cleanAvailableDays.contains(weekdayName.toLowerCase());
      }
      if (isSelectable) return date;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    const primary = AppTheme.primaryColor;

    final bool isConfirmEnabled = _selectedDate != null && _selectedTimeSlot != null;

    final double sheetHeight = MediaQuery.of(context).size.height - kToolbarHeight;

    return Container(
      height: sheetHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 12.w, 16.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(TablerIcons.calendar_event, size: 18.sp, color: primary),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('scheduleDelivery'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : const Color(0xFF111827),
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      context.tr('pickDateAndTime'),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: dark ? Colors.grey[400] : Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(TablerIcons.x, size: 16.sp, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  if (widget.rescheduleDeadline != null && widget.rescheduleDeadline!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: dark ? Colors.red.shade800 : Colors.red.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.alert_triangle,
                            color: dark ? Colors.red.shade300 : Colors.red.shade800,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              context.tr('rescheduleDeadlineWarning', positionalArgs: [_formattedDeadline()]),
                              style: TextStyle(
                                color: dark ? Colors.red.shade200 : Colors.red.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  _SectionLabel(
                    icon: TablerIcons.calendar,
                    label: context.tr('selectDeliveryDate'),
                  ),
                  SizedBox(height: 10.h),
                  DeliveryDatePicker(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                        _selectedTimeSlot = null;
                        _selectedTimeSlotId = null;
                      });
                      if (date != null) _fetchSlotsForDate(date);
                    },
                    maxDays: widget.maxDays,
                    availableDays: widget.availableDays,
                  ),
                  SizedBox(height: 20.h),
                  _SectionLabel(
                    icon: TablerIcons.clock,
                    label: context.tr('selectTimeSlot'),
                  ),
                  SizedBox(height: 12.h),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _isLoadingSlots
                        ? const CustomCircularProgressIndicator(
                            key: ValueKey('loading'),
                          )
                        : _availableSlots.isNotEmpty
                            ? _TimeSlotGrid(
                                key: ValueKey('slots_${_selectedDate?.toIso8601String()}'),
                                slots: _availableSlots,
                                selectedTimeSlot: _selectedTimeSlot,
                                dark: dark,
                                onSlotTap: (slot) {
                                  setState(() {
                                    if (_selectedTimeSlot == slot.label) {
                                      _selectedTimeSlot = null;
                                      _selectedTimeSlotId = null;
                                    } else {
                                      _selectedTimeSlot = slot.label;
                                      _selectedTimeSlotId = slot.id;
                                    }
                                  });
                                },
                              )
                            : _EmptySlots(
                                key: const ValueKey('empty'),
                                dark: dark,
                              ),
                  ),
                  SizedBox(height: 20.h),
                  if (widget.showCancelOrderButton)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50.h,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context, 'cancel');
                              },
                              child: Text(
                                'Cancel Order',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: CustomButton(
                            text: context.tr('confirmSlot'),
                            isDisabled: !isConfirmEnabled,
                            width: double.infinity,
                            height: 50.h,
                            onPressed: () {
                              DeliverySlot? selectedSlot;
                              for (final slot in _availableSlots) {
                                if (slot.label == _selectedTimeSlot) {
                                  selectedSlot = slot;
                                  break;
                                }
                              }
                              Navigator.pop(context, (
                                date: _selectedDate,
                                timeSlot: _selectedTimeSlot,
                                slotId: _selectedTimeSlotId,
                                startTime: selectedSlot?.startTime,
                                endTime: selectedSlot?.endTime,
                              ));
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    CustomButton(
                      text: context.tr('confirmSlot'),
                      isDisabled: !isConfirmEnabled,
                      width: double.infinity,
                      height: 50.h,
                      onPressed: () {
                        DeliverySlot? selectedSlot;
                        for (final slot in _availableSlots) {
                          if (slot.label == _selectedTimeSlot) {
                            selectedSlot = slot;
                            break;
                          }
                        }
                        Navigator.pop(context, (
                          date: _selectedDate,
                          timeSlot: _selectedTimeSlot,
                          slotId: _selectedTimeSlotId,
                          startTime: selectedSlot?.startTime,
                          endTime: selectedSlot?.endTime,
                        ));
                      },
                    ),
                  SizedBox(height: 24.h),
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
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 13.sp, color: AppTheme.primaryColor),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: dark ? Colors.grey[400] : Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _TimeSlotGrid extends StatelessWidget {
  final List<DeliverySlot> slots;
  final String? selectedTimeSlot;
  final bool dark;
  final void Function(DeliverySlot) onSlotTap;

  const _TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selectedTimeSlot,
    required this.dark,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = AppTheme.primaryColor;

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: slots.map((slot) {
          final bool isSelected = selectedTimeSlot == slot.label;
          final bool isEnabled = slot.isAvailable != false && slot.maxOrdersReached != true;
          final double chipWidth = (MediaQuery.of(context).size.width - 32.w - 20.w) / 3;

          return GestureDetector(
            onTap: isEnabled ? () => onSlotTap(slot) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: chipWidth,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [primary.withValues(alpha: 0.15), primary.withValues(alpha: 0.07)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : (dark ? const Color(0xFF2A2A3E) : const Color(0xFFF8F9FB)),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? primary : (dark ? Colors.white12 : Colors.grey.shade200),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Opacity(
                opacity: isEnabled ? 1 : 0.35,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TablerIcons.clock_hour_4,
                      size: 14.sp,
                      color: isSelected ? primary : (dark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      slot.label ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? primary : (dark ? Colors.grey[200] : Colors.grey[700]),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptySlots extends StatelessWidget {
  final bool dark;

  const _EmptySlots({super.key, required this.dark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Icon(TablerIcons.calendar_off, size: 16.sp, color: Colors.grey[400]),
          SizedBox(width: 8.w),
          Text(
            context.tr('noSlotsAvailable'),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

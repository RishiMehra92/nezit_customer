import 'package:flutter/material.dart';

class CustomDatePicker {
  /// Displays a styled date picker matching the app's design system.
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    bool Function(DateTime)? selectableDayPredicate,
    Color? primaryColor,
  }) async {
    return showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: selectableDayPredicate,
      builder: (BuildContext context, Widget? child) {
        if (primaryColor == null) return child!;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );
  }
}

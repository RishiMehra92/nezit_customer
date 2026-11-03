import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local/config/helper.dart';
import '../model/near_by_store_model.dart';

class StoreStatusHelper {
  static const List<double> greyscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      0.65, 0,
  ];

  static String getStatusText(StoreData store, BuildContext context) {
    if (store.status?.isOpen == false || store.status?.status == 'offline') {
      return context.tr('closedText', fallback: 'Closed');
    }

    bool isOpen = store.status?.isOpen ?? true;
    String statusText = isOpen
        ? (context.tr('openNow', fallback: 'Open Now'))
        : (context.tr('closedText', fallback: 'Closed'));

    if (store.operatingHours != null) {
      DateTime now = DateTime.now();
      int weekday = now.weekday; // 1 = Monday, 7 = Sunday

      DayOperatingHours? todayHours;
      switch (weekday) {
        case 1:
          todayHours = store.operatingHours!.monday;
          break;
        case 2:
          todayHours = store.operatingHours!.tuesday;
          break;
        case 3:
          todayHours = store.operatingHours!.wednesday;
          break;
        case 4:
          todayHours = store.operatingHours!.thursday;
          break;
        case 5:
          todayHours = store.operatingHours!.friday;
          break;
        case 6:
          todayHours = store.operatingHours!.saturday;
          break;
        case 7:
          todayHours = store.operatingHours!.sunday;
          break;
      }

      if (todayHours != null) {
        if (todayHours.isOpen != true) {
          return context.tr('closedText', fallback: 'Closed');
        } else {
          if (todayHours.openTime != null && todayHours.closeTime != null) {
            try {
              final timeFormat = DateFormat("HH:mm");
              final openTime = timeFormat.parse(todayHours.openTime!);
              final closeTime = timeFormat.parse(todayHours.closeTime!);

              final currentMinutes = now.hour * 60 + now.minute;
              final openMinutes = openTime.hour * 60 + openTime.minute;
              final closeMinutes = closeTime.hour * 60 + closeTime.minute;

              if (currentMinutes < openMinutes || currentMinutes >= closeMinutes) {
                return context.tr('closedText', fallback: 'Closed');
              }

              if (todayHours.hasBreak == true &&
                  todayHours.breakStartTime != null &&
                  todayHours.breakEndTime != null) {
                final breakStart = timeFormat.parse(todayHours.breakStartTime!);
                final breakEnd = timeFormat.parse(todayHours.breakEndTime!);

                final bStartMinutes = breakStart.hour * 60 + breakStart.minute;
                final bEndMinutes = breakEnd.hour * 60 + breakEnd.minute;

                if (currentMinutes >= bStartMinutes && currentMinutes < bEndMinutes) {
                  final outFormat = DateFormat.jm();
                  final dateStart = DateTime(
                      now.year, now.month, now.day, breakStart.hour, breakStart.minute);
                  final dateEnd = DateTime(
                      now.year, now.month, now.day, breakEnd.hour, breakEnd.minute);

                  return 'Break (${outFormat.format(dateStart)} - ${outFormat.format(dateEnd)})';
                }
              }

              return context.tr('openNow', fallback: 'Open Now');
            } catch (_) {
              // Fallback if parsing fails
            }
          }
        }
      }
    }

    return statusText;
  }

  static Color getStatusColor(String statusText, BuildContext context) {
    final dark = isDarkMode(context);
    final closedText = context.tr('closedText', fallback: 'Closed');
    if (statusText == closedText) {
      return dark ? const Color(0xFFEF5350) : Colors.red.shade700;
    } else if (statusText.startsWith('Break')) {
      return dark ? Colors.orange.shade300 : Colors.orange.shade800;
    } else {
      return dark ? const Color(0xFF66BB6A) : Colors.green.shade700;
    }
  }

  static bool isClosed(StoreData store, BuildContext context) {
    if (store.status?.isOpen == false || store.status?.status == 'offline') {
      return true;
    }
    final text = getStatusText(store, context);
    final openNow = context.tr('openNow', fallback: 'Open Now');
    return text != openNow;
  }
}

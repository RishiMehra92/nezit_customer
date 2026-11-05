import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/language_bloc/language_list_bloc/language_list_bloc.dart';
import '../../l10n/default_en_labels.dart';
import '../../repo/language_repo.dart';

extension TranslationExtension on BuildContext {
  /// Resolves a dynamic translation label from [LanguageListBloc]
  /// with dynamic placeholder replacement: `{placeholder}` -> `value`.
  /// Automatically subscribes the calling widget to rebuild on label changes
  /// when called within [build].
  String tr(
    String key, {
    Map<String, dynamic>? args,
    List<dynamic>? positionalArgs,
    String? fallback,
  }) {
    String? text;

    try {
      LanguageListState? state;
      try {
        state = watch<LanguageListBloc>().state;
      } catch (_) {
        state = read<LanguageListBloc>().state;
      }
      if (state is LanguageListLoaded) {
        text = state.labels[key];
      }
    } catch (_) {
      // In case context doesn't have LanguageListBloc in scope
    }

    if (text == null || text.trim().isEmpty) {
      text = LanguageRepo.activeLabels[key]?.toString();
    }

    if (text == null || text.trim().isEmpty) {
      text =
          defaultEnglishLabels[key] ??
          ((fallback != null && fallback.trim().isNotEmpty) ? fallback : key);
    }

    if (args != null && args.isNotEmpty) {
      args.forEach((placeholder, value) {
        text = text!.replaceAll('{$placeholder}', value.toString());
      });
    }

    // Handle ICU plural messages if present (e.g. {count, plural, =1{1 Product} other{{count} Products}})
    if (text!.contains('plural,')) {
      num? count;
      if (args != null && args.containsKey('count') && args['count'] is num) {
        count = args['count'] as num;
      } else if (positionalArgs != null &&
          positionalArgs.isNotEmpty &&
          positionalArgs.first is num) {
        count = positionalArgs.first as num;
      }
      if (count != null) {
        text = _resolvePlural(text!, count);
      } else if (fallback != null && fallback.trim().isNotEmpty) {
        text = fallback;
      }
    }

    if (positionalArgs != null && positionalArgs.isNotEmpty) {
      for (var i = 0; i < positionalArgs.length; i++) {
        text = text!.replaceAll('{$i}', positionalArgs[i].toString());
      }
      final regex = RegExp(r'\{[a-zA-Z0-9_]+\}');
      final matches = regex.allMatches(text!).toList();
      for (var i = 0; i < positionalArgs.length && i < matches.length; i++) {
        text = text!.replaceAll(matches[i].group(0)!, positionalArgs[i].toString());
      }
    }

    // Never leak raw ICU plural format to the UI
    if (text!.contains('plural,') && fallback != null && fallback.trim().isNotEmpty) {
      text = fallback;
    }

    return text!;
  }

  static String _resolvePlural(String text, num count) {
    final pluralRegex = RegExp(r'\{[a-zA-Z0-9_]+,\s*plural\s*,\s*(.+)\}', dotAll: true);
    final match = pluralRegex.firstMatch(text);
    if (match == null) return text;

    final body = match.group(1)!;
    const nestedPattern = r'((?:[^{}]|\{[^{}]*\})*)';

    final exactMatch = RegExp('=$count\\{$nestedPattern\\}').firstMatch(body);
    if (exactMatch != null) {
      final res = exactMatch.group(1)!;
      return text.replaceRange(match.start, match.end, res).replaceAll('{count}', count.toString());
    }

    final otherMatch = RegExp('other\\{$nestedPattern\\}').firstMatch(body);
    if (otherMatch != null) {
      final res = otherMatch.group(1)!;
      return text.replaceRange(match.start, match.end, res).replaceAll('{count}', count.toString());
    }

    return text;
  }
}

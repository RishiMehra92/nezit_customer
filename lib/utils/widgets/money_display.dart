import 'package:intl/intl.dart';
import '../../config/helper.dart';

/// Implements the authoritative 4-tier amount display priority:
/// 1. Direct formatted_* field from backend.
/// 2. currency_snapshot.formatted.*
/// 3. Format using resolved currency symbol (e.g. $ for USD, ₹ for INR) + raw amount.
/// 4. Legacy global currencySymbol only when response has no record currency information.
class MoneyDisplay {
  MoneyDisplay._();

  /// Resolves the symbol for a currency code (e.g. USD -> $, INR -> ₹, EUR -> €).
  static String resolveCurrencySymbol(String? currencyCode, {String? legacySymbol}) {
    if (currencyCode == null || currencyCode.trim().isEmpty) {
      return legacySymbol ?? AppHelpers.currency;
    }
    final code = currencyCode.trim().toUpperCase();
    switch (code) {
      case 'USD':
        return '\$';
      case 'INR':
        return '₹';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
      case 'AUD':
      case 'NZD':
      case 'SGD':
        return '\$';
      case 'AED':
        return 'AED ';
      case 'SAR':
        return 'SAR ';
      case 'QAR':
        return 'QAR ';
      case 'KWD':
        return 'KWD ';
      case 'BHD':
        return 'BHD ';
      case 'OMR':
        return 'OMR ';
      default:
        try {
          final sym = NumberFormat.simpleCurrency(name: code).currencySymbol;
          if (sym.isNotEmpty && sym != code) {
            return sym;
          }
        } catch (_) {}
        return '$code ';
    }
  }

  /// Primary formatting method implementing the backend multi-currency specification.
  static String format(
    dynamic amount, {
    String? formatted,
    String? formattedAmount,
    String? snapshotFormatted,
    String? currencyCode,
    String? legacySymbol,
  }) {
    // 1. Direct formatted_* field (already includes ISO code and/or symbol)
    final direct = (formatted != null && formatted.trim().isNotEmpty)
        ? formatted.trim()
        : (formattedAmount != null && formattedAmount.trim().isNotEmpty)
            ? formattedAmount.trim()
            : null;
    if (direct != null) {
      return direct;
    }

    // 2. currency_snapshot.formatted.*
    if (snapshotFormatted != null && snapshotFormatted.trim().isNotEmpty) {
      return snapshotFormatted.trim();
    }

    // Format raw amount nicely
    final formattedRaw = _formatRawAmount(amount);

    // 3. Format using resolved currency symbol (e.g. USD -> $, INR -> ₹)
    final symbol = resolveCurrencySymbol(currencyCode, legacySymbol: legacySymbol);
    return '$symbol$formattedRaw';
  }

  static String _formatRawAmount(dynamic amount) {
    if (amount == null) return '0.00';
    if (amount is num) {
      if (amount == amount.toInt()) {
        return amount.toInt().toString();
      }
      return amount.toStringAsFixed(2);
    }
    final parsed = double.tryParse(amount.toString());
    if (parsed != null) {
      if (parsed == parsed.toInt()) {
        return parsed.toInt().toString();
      }
      return parsed.toStringAsFixed(2);
    }
    return amount.toString();
  }
}

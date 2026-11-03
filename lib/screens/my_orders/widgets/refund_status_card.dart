import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_local/screens/my_orders/model/order_status.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';
import 'package:intl/intl.dart';

enum _RefundUiState { processing, credited }

class RefundStatusCard extends StatelessWidget {
  final OrderDetailData order;
  final OrderStatus status;

  const RefundStatusCard({
    super.key,
    required this.order,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
        final state = _resolveState();
    final amount = _resolveAmount();
    final amountText = MoneyDisplay.format(amount, currencyCode: order.currencyCode);
    final note = _resolveNote(context, state, amountText);
    final label = state == _RefundUiState.credited
        ? context.tr('refundLabel', fallback: 'Refund') : context.tr('refundStatusLabel', fallback: 'Refund status');
    final pillText = state == _RefundUiState.credited
        ? context.tr('refundCredited', fallback: 'Credited') : context.tr('refundProcessing', fallback: 'Processing');
    final pillColor = state == _RefundUiState.credited
        ? AppTheme.successColor
        : AppTheme.warningColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                pillText,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: pillColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            note,
            style: TextStyle(
              fontSize: 11.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  _RefundUiState _resolveState() {
    if (status == OrderStatus.returned) return _RefundUiState.credited;
    return _RefundUiState.processing;
  }

  double _resolveAmount() {
    final value = order.finalTotal ?? order.totalPayable ?? '0';
    return double.tryParse(value) ?? 0.0;
  }

  String _resolveNote(
    BuildContext context,
    _RefundUiState state,
    String amountText,
  ) {
    if (state == _RefundUiState.credited) {
      final dateRaw = order.updatedAt ?? order.createdAt;
      final date = _formatDate(dateRaw);
      return context.tr('refundCreditedNote', positionalArgs: [amountText, date ?? ''], fallback:
          '$amountText added to your wallet on ${date ?? ''}');
    }
    return context.tr('refundProcessingNote', positionalArgs: [amountText], fallback:
        '$amountText will be credited to your wallet in 1–3 days');
  }

  String? _formatDate(String? raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return DateFormat('d MMM').format(dt.toLocal());
  }
}

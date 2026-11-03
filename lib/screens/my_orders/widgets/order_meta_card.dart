import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/date_formatter.dart';

class OrderMetaCard extends StatelessWidget {
  final String orderId;
  final String paymentMethod;
  final String? createdAt;
  final String? invoiceUrl;
  final VoidCallback? onDownloadInvoice;

  const OrderMetaCard({
    super.key,
    required this.orderId,
    required this.paymentMethod,
    this.createdAt,
    this.invoiceUrl,
    this.onDownloadInvoice,
  });

  @override
  Widget build(BuildContext context) {
        final placedOn = createdAt != null ? DateFormatter.fullDate(createdAt!) : null;
    final divider = Divider(
      height: 1.h,
      thickness: 0.5,
      color: Theme.of(context).colorScheme.outline,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Column(
        children: [
          _row(
            context: context,
            label: context.tr('orderId', fallback: 'Order ID'),
            value: '#$orderId',
            trailing: Semantics(
              label: 'Copy order ID',
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8.r),
                onTap: () => _copyOrderId(context),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    TablerIcons.copy,
                    size: 13.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          divider,
          _row(
            context: context,
            label: context.tr('payment', fallback: 'Payment'),
            value: _paymentLabel(context),
          ),
          if (placedOn != null) ...[
            divider,
            _row(
              context: context,
              label: context.tr('placedOn', fallback: 'Placed on'),
              value: placedOn,
            ),
          ],
          if (invoiceUrl != null && invoiceUrl!.isNotEmpty) ...[
            divider,
            _row(
              context: context,
              label: context.tr('invoiceLabel', fallback: 'Invoice'),
              value: context.tr('downloadLabel', fallback: 'Download'),
              valueColor: AppTheme.primaryColor,
              trailing: Icon(
                TablerIcons.download,
                size: 13.sp,
                color: AppTheme.primaryColor,
              ),
              onTap: onDownloadInvoice,
            ),
          ],
        ],
      ),
    );
  }

  Widget _row({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: 6.w),
                  trailing,
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }

  String _paymentLabel(BuildContext context) {
    switch (paymentMethod) {
      case 'cod':
        return context.tr('cashOnDelivery', fallback: 'Cash on Delivery');
      case 'wallet':
        return context.tr('wallet', fallback: 'Wallet');
      default:
        return context.tr('paidOnline', fallback: 'Paid Online');
    }
  }

  void _copyOrderId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: orderId));
    ToastManager.show(
      context: context,
      message: context.tr('orderIdCopied', fallback: 'Order ID copied!'),
      type: ToastType.success,
      duration: const Duration(seconds: 1),
    );
  }
}

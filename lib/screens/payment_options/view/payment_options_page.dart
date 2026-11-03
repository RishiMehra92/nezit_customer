import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/payment_config.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../../../../utils/widgets/custom_toast.dart';
import '../../../utils/widgets/money_display.dart';

class PaymentOptionsPage extends StatefulWidget {
  final double totalAmount;
  final bool? isFromAddMoney;
  final String? deliveryType;
  final bool? isPickupCodEnabled;
  final List<String>? nonCodPickupStores;
  final bool? hasTip;
  final double? codCharges;
  final String? currencyCode;
  final List<dynamic>? availablePaymentMethods;

  const PaymentOptionsPage({
    super.key,
    required this.totalAmount,
    this.isFromAddMoney = false,
    this.deliveryType,
    this.isPickupCodEnabled,
    this.nonCodPickupStores,
    this.hasTip = false,
    this.codCharges,
    this.currencyCode,
    this.availablePaymentMethods,
  });

  @override
  State<PaymentOptionsPage> createState() => _PaymentOptionsPageState();
}

class _PaymentOptionsPageState extends State<PaymentOptionsPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      appBar: AppBar(
        title: Text(
          'Payment Options',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Payment Summary
          _buildPaymentSummary(),
          // Payment Options
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Online Payment Methods
                  _buildPaymentSection(
                    title: context.tr('onlinePaymentMethods'),
                    methods: PaymentConfig.getContextualPaymentMethods(availableMethods: widget.availablePaymentMethods),
                    showAddIcon: false,
                  ),
                  SizedBox(height: 16.h),
                  // Unavailable payment method message
                  SizedBox(height: 20.h), // Bottom spacing
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            context.tr('toPay'),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            MoneyDisplay.format(widget.totalAmount, currencyCode: widget.currencyCode),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection({
    required String title,
    required List<PaymentMethod> methods,
    required bool showAddIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: methods.asMap().entries.map((entry) {
          final index = entry.key;
          final method = entry.value;
          final isLast = index == methods.length - 1;

          return _buildPaymentOption(
            method: method,
            showAddIcon: showAddIcon,
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required bool showAddIcon,
    required bool isLast,
  }) {
    final isSettingsEnabled = PaymentConfig.isPaymentMethodEnabledInSettings(method.id);
    final isPickupCodDisabled =
        method.type == PaymentMethodType.cod && widget.deliveryType == 'pickup' && (widget.isPickupCodEnabled != true);
    final isTipCodDisabled = method.type == PaymentMethodType.cod && (widget.hasTip == true);
    final isEnabled = isSettingsEnabled && !isPickupCodDisabled && !isTipCodDisabled;
    final isFromAddMoney = widget.isFromAddMoney ?? false;

    if (isSettingsEnabled) {
      if (method.type == PaymentMethodType.cod && isFromAddMoney) {
        return const SizedBox.shrink();
      } else {
        return Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              leading: SizedBox(
                width: 35.w,
                height: 35.w,
                child: Opacity(
                  opacity: isEnabled ? 1.0 : 0.5,
                  child: method.getDisplayWidget(size: 20.sp),
                ),
              ),
              title: Text(
                method.name,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? Theme.of(context).colorScheme.tertiary : Colors.grey[600],
                ),
              ),
              subtitle: !isEnabled
                  ? Text(
                      isPickupCodDisabled
                          ? ((widget.nonCodPickupStores != null && widget.nonCodPickupStores!.isNotEmpty)
                              ? 'COD is not supported by: ${widget.nonCodPickupStores!.join(', ')}'
                              : 'Cash on Delivery is not available for Pickup orders')
                          : (isTipCodDisabled
                              ? context.tr('tipCodDisabledSubtitle')
                              : context.tr('currentlyUnavailable')),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : (method.type == PaymentMethodType.cod
                      ? Text(
                          (widget.codCharges != null && widget.codCharges! > 0)
                              ? context.tr('codHandlingFeeSubtitle', positionalArgs: [MoneyDisplay.format(widget.codCharges!, currencyCode: widget.currencyCode)])
                              : context.tr('codSubtitle'),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        )
                      : null),
              trailing: showAddIcon
                  ? Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    )
                  : isEnabled
                      ? Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 16.sp,
                        )
                      : Icon(
                          Icons.block,
                          color: Colors.grey[400],
                          size: 16.sp,
                        ),
              onTap: () {
                if (isEnabled && !showAddIcon) {
                  Navigator.pop(context, method.type);
                } else if (isPickupCodDisabled) {
                  final storesList = widget.nonCodPickupStores ?? [];
                  final storesText = storesList.isNotEmpty ? storesList.join(', ') : 'selected store';
                  ToastManager.show(
                    context: context,
                    message: 'The following store(s) do not support COD: $storesText',
                    type: ToastType.error,
                  );
                } else if (isTipCodDisabled) {
                  ToastManager.show(
                    context: context,
                    message: context.tr('tipCodDisabledToast'),
                    type: ToastType.error,
                  );
                }
              },
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}

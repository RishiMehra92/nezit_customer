import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_items_card.dart';

Future<void> showOrderItemsBottomSheet({
  required BuildContext context,
  required List<OrderItems> items,
  String? deliveryOtpMode,
  String? currencyCode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderItemsBottomSheetContent(
      items: items,
      deliveryOtpMode: deliveryOtpMode,
      currencyCode: currencyCode,
    ),
  );
}

class _OrderItemsBottomSheetContent extends StatelessWidget {
  final List<OrderItems> items;
  final String? deliveryOtpMode;
  final String? currencyCode;
  const _OrderItemsBottomSheetContent({
    required this.items,
    this.deliveryOtpMode,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                child: Row(
                  children: [
                    Text(
                      context.tr('itemsCount', positionalArgs: [items.length], fallback: '${items.length} items'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      iconSize: 20.sp,
                      color: scheme.onSurfaceVariant,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 24.h),
                  child: OrderItemsCard(
                    items: items,
                    totalItems: items.length.toString(),
                    currencyCode: currencyCode,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

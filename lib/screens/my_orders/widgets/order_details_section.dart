import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
class OrderDetailsSection extends StatelessWidget {
  final String orderId;
  final String payment;
  final String orderPlaced;
  final String placedAt;

  const OrderDetailsSection({
    super.key,
    required this.orderId,
    required this.payment,
    required this.orderPlaced,
    required this.placedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('orderDetails'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Column(
              children: [
                _buildOrderDetailRow(context.tr('orderId'), orderId, context),
                _buildOrderDetailRow(context.tr('payment'), payment, context),
                _buildOrderDetailRow(context.tr('orderPlaced'), placedAt, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.tertiary,
              )),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

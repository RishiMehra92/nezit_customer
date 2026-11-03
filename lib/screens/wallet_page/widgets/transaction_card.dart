import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';

import '../model/prepare_wallet_recharge_model.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.transactionType?.toLowerCase() == 'deposit';
    final isWithdrawal = transaction.transactionType?.toLowerCase() == 'withdrawal';
    final isRefund = transaction.transactionType?.toLowerCase() == 'refund';

    return GestureDetector(
      onTap: () => _showTransactionDetailsBottomSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode(context) ? AppTheme.darkProductCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(isDeposit, isWithdrawal, isRefund),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTransactionIcon(isDeposit, isWithdrawal, isRefund),
                color: _getIconColor(isDeposit, isWithdrawal, isRefund),
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    _formatDescription(transaction.description),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  // Date and Payment Method
                  Row(
                    children: [
                      Icon(
                        TablerIcons.clock,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(transaction.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Payment Method
                  if (transaction.paymentMethod != null)
                    Row(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(transaction.paymentMethod),
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatPaymentMethod(transaction.paymentMethod),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Amount and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Amount
                Text(
                  '${isDeposit || isRefund ? '+' : '-'} ${_formatAmount(transaction.amount, transaction.currencyCode)}',
                  style: TextStyle(
                    color: isDeposit || isRefund ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(transaction.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatus(removeUnderscores(transaction.status!)),
                    style: TextStyle(
                      color: _getStatusTextColor(transaction.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getTransactionIcon(bool isDeposit, bool isWithdrawal, bool isRefund) {
    if (isDeposit) return TablerIcons.coins;
    if (isWithdrawal) return TablerIcons.coins;
    if (isRefund) return TablerIcons.coins;
    return TablerIcons.coins;
  }

  Color _getIconColor(bool isDeposit, bool isWithdrawal, bool isRefund) {
    if (isDeposit || isRefund) return const Color(0xFF10B981);
    if (isWithdrawal) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  Color _getIconBackgroundColor(bool isDeposit, bool isWithdrawal, bool isRefund) {
    if (isDeposit || isRefund) return const Color(0xFF10B981).withValues(alpha: 0.1);
    if (isWithdrawal) return const Color(0xFFEF4444).withValues(alpha: 0.1);
    return const Color(0xFF6B7280).withValues(alpha: 0.1);
  }

  Color _getStatusBackgroundColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'credited':
        return const Color(0xFF10B981).withValues(alpha: 0.15);
      case 'pending':
        return const Color(0xFFF59E0B).withValues(alpha: 0.15);
      case 'failed':
      case 'cancelled':
        return const Color(0xFFEF4444).withValues(alpha: 0.15);
      default:
        return Colors.grey.withValues(alpha: 0.15);
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'credited':
        return const Color(0xFF059669);
      case 'pending':
        return const Color(0xFFD97706);
      case 'failed':
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'N/A';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _formatDescription(String? description) {
    if (description == null || description == 'string') return 'Wallet Transaction';
    return description;
  }

  String _formatPaymentMethod(String? method) {
    if (method == null) return '';

    // Handle specific payment methods
    if (method.toLowerCase().contains('razorpay')) {
      return 'Razorpay';
    }

    // Convert snake_case or camelCase to Title Case
    return method
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .split(RegExp(r'[_\s]+'))
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ')
        .trim();
  }

  IconData _getPaymentMethodIcon(String? method) {
    if (method == null) return TablerIcons.credit_card;

    final lowercaseMethod = method.toLowerCase();
    if (lowercaseMethod.contains('razorpay')) return TablerIcons.brand_stripe;
    if (lowercaseMethod.contains('upi')) return TablerIcons.qrcode;
    if (lowercaseMethod.contains('card')) return TablerIcons.credit_card;
    if (lowercaseMethod.contains('wallet')) return TablerIcons.wallet;

    return TablerIcons.credit_card;
  }

  String _formatAmount(String? amount, String? currencyCode) {
    if (amount == null) return '0';

    if (currencyCode?.toLowerCase() == 'points' || currencyCode?.toLowerCase() == 'coins') {
      final double amountValue = double.tryParse(amount) ?? 0;
      return '${amountValue.toInt()}';
    }

    final double amountValue = double.tryParse(amount) ?? 0;

    return MoneyDisplay.format(amountValue, currencyCode: currencyCode);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours < 1) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else {
        return DateFormat('dd MMM').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  void _showTransactionDetailsBottomSheet(BuildContext context) {
    final isDeposit = transaction.transactionType?.toLowerCase() == 'deposit';
    final isWithdrawal = transaction.transactionType?.toLowerCase() == 'withdrawal';
    final isRefund = transaction.transactionType?.toLowerCase() == 'refund';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode(context) ? AppTheme.darkProductCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SafeArea(
            child: StaggeredListAnimator(
              type: StaggeredListType.column,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDarkMode(context) ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        context.tr('transactions', fallback: 'Transaction Details'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor:
                              isDarkMode(context) ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(36, 36),
                        ),
                        icon: const Icon(TablerIcons.x, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 0.5),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      // Status Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _getIconBackgroundColor(isDeposit, isWithdrawal, isRefund),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTransactionIcon(isDeposit, isWithdrawal, isRefund),
                          color: _getIconColor(isDeposit, isWithdrawal, isRefund),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description / Header
                      Text(
                        _formatDescription(transaction.description),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Large Amount
                      Text(
                        '${isDeposit || isRefund ? '+' : '-'} ${_formatAmount(transaction.amount, transaction.currencyCode)}',
                        style: TextStyle(
                          color: isDeposit || isRefund ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusBackgroundColor(transaction.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatStatus(removeUnderscores(transaction.status!)),
                          style: TextStyle(
                            color: _getStatusTextColor(transaction.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 0.5),

                // Details list in a neat container
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode(context) ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (transaction.id != null) ...[
                          const SizedBox(height: 12),
                          _buildCopyableDetailRow(
                            context,
                            label: context.tr('transactionId', fallback: 'Transaction ID'),
                            value: transaction.id.toString(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          label: context.tr('dateAndTime', fallback: 'Date & Time'),
                          value: _formatFullDate(transaction.createdAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildDetailRow(BuildContext context, {required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableDetailRow(BuildContext context,
      {required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

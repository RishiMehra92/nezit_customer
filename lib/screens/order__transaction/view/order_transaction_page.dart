import 'package:hyper_local/utils/extensions/translation_extension.dart';
//

// order_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../../wallet_page/widgets/empty_transaction_widget.dart';
import '../bloc/order_transactions/order_transactions_bloc.dart';
import '../widgets/order_transaction_card.dart';

class OrderTransactionPage extends StatefulWidget {
  const OrderTransactionPage({super.key});

  @override
  State<OrderTransactionPage> createState() => _OrderTransactionPageState();
}

class _OrderTransactionPageState extends State<OrderTransactionPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedPaymentStatus;

  final List<String> paymentStatuses = [
    '', // All
    'completed',
    'pending',
    'failed',
  ];

  @override
  void initState() {
    super.initState();
    context.read<OrderTransactionsBloc>().add(FetchOrderTransactions());
  }

  void _applyFilter() {
    context.read<OrderTransactionsBloc>().add(UpdateFilter(
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          paymentStatus: _selectedPaymentStatus?.isEmpty == true
              ? null
              : _selectedPaymentStatus,
        ));
  }

  @override
  Widget build(BuildContext context) {
    
    return CustomScaffold(
      showViewCart: false,
      title: context.tr('transactions', fallback: 'Transactions'),
      showAppBar: true,
      appBarActions: [
        DropdownButton<String>(
          value: _selectedPaymentStatus,
          hint: Text(context.tr('status', fallback: "Status")),
          underline: const SizedBox.shrink(),
          isDense: true,
          alignment: AlignmentGeometry.topRight,
          iconSize: 20,
          items: paymentStatuses.map((status) {
            return DropdownMenuItem(
              value: status.isEmpty ? null : status,
              child: Text(
                status.isEmpty
                    ? (context.tr('all', fallback: "All"))
                    : _formatStatusLabel(status),
                style: const TextStyle(fontSize: 11),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPaymentStatus = value;
            });
            _applyFilter();
          },
        ),
        const SizedBox(
          width: 16,
        )
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: CustomTextFormField(
                    controller: _searchController,
                    hintText: context.tr('searchTransactionsPlaceholder', fallback:
                        'Search by order ID, payment ID...'),
                    prefixIcon: Icons.search,
                    onFieldSubmitted: (_) => _applyFilter(),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: BlocBuilder<OrderTransactionsBloc, OrderTransactionsState>(
              builder: (context, state) {
                if (state is OrderTransactionsLoading) {
                  return const Center(child: CustomCircularProgressIndicator());
                }

                if (state is OrderTransactionsFailure) {
                  return EmptyTransactionsState(
                    onRetry: () => context.read<OrderTransactionsBloc>().add(
                          FetchOrderTransactions(
                            search: _searchController.text.trim(),
                            paymentStatus: _selectedPaymentStatus,
                          ),
                        ),
                  );
                }

                if (state is OrderTransactionsLoaded) {
                  if (state.transactions.isEmpty) {
                    return EmptyTransactionsState(
                      onRetry: _applyFilter,
                    );
                  }

                  return CustomRefreshIndicator(
                    onRefresh: () async => _applyFilter(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo is ScrollUpdateNotification &&
                            !state.hasReachedMax &&
                            scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent - 50) {
                          context
                              .read<OrderTransactionsBloc>()
                              .add(FetchMoreOrderTransactions());
                        }
                        return false;
                      },
                      child: StaggeredListAnimator(
                        type: StaggeredListType.listView,
                        shrinkWrap: false,
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...state.transactions
                              .map((tx) => OrderTransactionCard(
                                    key: ValueKey(tx.id),
                                    transaction: tx,
                                  )),
                          if (!state.hasReachedMax)
                            const SizedBox(
                              height: 50,
                              child: Center(
                                  child: CustomCircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'completed') return context.tr('statusSuccess', fallback: 'SUCCESS');
    if (s == 'pending') return context.tr('statusPending', fallback: 'PENDING');
    if (s == 'failed') return context.tr('statusFailed', fallback: 'FAILED');
    return status.toUpperCase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

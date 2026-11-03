import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/coins_page/bloc/coins_bloc.dart';
import 'package:hyper_local/screens/wallet_page/widgets/transaction_card.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';

class CoinsPage extends StatefulWidget {
  const CoinsPage({super.key});

  @override
  State<CoinsPage> createState() => _CoinsPageState();
}

class _CoinsPageState extends State<CoinsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScaffold(
      showViewCart: false,
      title: context.tr('coins', fallback: "Coins"),
      showAppBar: true,
      body: BlocBuilder<CoinsBloc, CoinsState>(
        builder: (context, state) {
          if (state.status == ApiStatus.loading || state.status == ApiStatus.initial) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Column(
                spacing: 5,
                children: [
                  ShimmerWidget.rectangular(
                    height: 140.h,
                    isBorder: true,
                    borderRadius: 24.r,
                  ),
                  SizedBox(height: 20.h),
                  ...List.generate(10, (i) {
                    return ShimmerWidget.rectangular(
                      height: 80.h,
                      isBorder: true,
                      borderRadius: 16.r,
                    );
                  }),
                ],
              ),
            );
          } else if (state.status == ApiStatus.failure && state.transactions.isEmpty) {
            return EmptyStatePage(
              title: state.error ?? "Failed to load loyalty summary",
              description: "Something went wrong while fetching your loyalty points history.",
              imageAsset: 'assets/images/no_internet.png',
              onRetry: () {
                context.read<CoinsBloc>().add(FetchCoinsSummary());
              },
            );
          }

          final balance = state.summary?.pointsBalance ?? 0;

          return CustomRefreshIndicator(
            onRefresh: () async {
              context.read<CoinsBloc>().add(FetchCoinsSummary());
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo is ScrollUpdateNotification &&
                    !state.hasReachedMax &&
                    !state.isLoadingMore &&
                    scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 50) {
                  context.read<CoinsBloc>().add(FetchMoreCoinsSummary());
                }
                return false;
              },
              child: StaggeredListAnimator(
                type: StaggeredListType.listView,
                shrinkWrap: false,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F11),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // "Your Rewards" Badge
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.03),
                                          borderRadius: BorderRadius.circular(30.r),
                                          border: Border.all(
                                            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.workspace_premium_rounded,
                                              color: const Color(0xFFFFD700),
                                              size: 15.sp,
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              "Your Rewards",
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: AppTheme.fontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Big Coin Balance Row
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (bounds) => const LinearGradient(
                                              colors: [Color(0xFFFFF176), Color(0xFFFFB300)],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ).createShader(bounds),
                                            child: Text(
                                              "$balance",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 64.sp,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: AppTheme.fontFamily,
                                                height: 1.0,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Text(
                                            context.tr('coins', fallback: "Coins"),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 32.sp,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: AppTheme.fontFamily,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Monetary Value Subtext Row
                            Row(
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.04),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.confirmation_number_outlined,
                                    color: const Color(0xFFFFD700),
                                    size: 16.sp,
                                  ),
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "≈ ",
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: AppTheme.fontFamily,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              "${MoneyDisplay.format(state.summary?.equivalentMonetaryValue ?? balance, formattedAmount: state.summary?.formattedEquivalentMonetaryValue, currencyCode: state.summary?.currencyCode)} OFF",
                                          style: TextStyle(
                                            color: const Color(0xFFFFD700),
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: AppTheme.fontFamily,
                                          ),
                                        ),
                                        TextSpan(
                                          text: " ${context.tr('onYourNextOrder', fallback: 'on your next order')}",
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: AppTheme.fontFamily,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 10.w,
                        bottom: 28.h,
                        child: const CustomImageContainer(
                          imagePath: "assets/images/more_coin.png",
                          height: 150,
                          width: 150,
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 24.h, bottom: 12.h),
                    child: Text(
                      context.tr('transactions', fallback: "Transaction History"),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (state.transactions.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 60.sp,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            context.tr('noTransactionYet', fallback: "No transactions yet"),
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ...state.transactions.map((tx) => TransactionCard(
                          key: ValueKey(tx.id),
                          transaction: tx.toTransaction(),
                        )),
                    if (!state.hasReachedMax)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: const Center(
                          child: CustomCircularProgressIndicator(),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

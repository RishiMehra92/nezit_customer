import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/wallet_page/bloc/user_wallet/user_wallet_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import '../../../config/helper.dart';

import '../../../utils/widgets/money_display.dart';

class WalletUsageWidget extends StatefulWidget {
  final bool isWalletEnabled;
  final Function(bool) onWalletToggle;
  final bool isLoading;
  final double? walletAmountUsed;
  final double? availableBalance;
  final String? cartCurrencyCode;

  const WalletUsageWidget({
    super.key,
    required this.isWalletEnabled,
    required this.onWalletToggle,
    this.isLoading = false,
    this.walletAmountUsed,
    this.availableBalance,
    this.cartCurrencyCode,
  });

  @override
  State<WalletUsageWidget> createState() => _WalletUsageWidgetState();
}

class _WalletUsageWidgetState extends State<WalletUsageWidget> {
  double balance = 0.00;
  double remainingBalance = 0.00;
  double usedBalance = 0.00;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: dark ? AppTheme.mainDarkContainerBgColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: BlocBuilder<UserWalletBloc, UserWalletState>(
        builder: (context, walletState) {
          String? walletCurrency;
          if (walletState is UserWalletLoaded && walletState.userWallet.isNotEmpty) {
            final wallet = walletState.userWallet.first;
            balance = widget.availableBalance ?? (double.tryParse(wallet.balance ?? '0.00') ?? 0.00);
            walletCurrency = wallet.currencyCode;
          }

          final bool isCurrencyMismatch = widget.cartCurrencyCode != null &&
              widget.cartCurrencyCode!.isNotEmpty &&
              walletCurrency != null &&
              walletCurrency.isNotEmpty &&
              widget.cartCurrencyCode != walletCurrency;

          usedBalance = (widget.isWalletEnabled && !isCurrencyMismatch)
              ? (widget.walletAmountUsed ?? 0.00)
              : 0.00;
          final rem = balance - usedBalance;
          remainingBalance = rem < 0 ? 0.0 : rem;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: isTablet(context) ? 22 : 16.sp,
                        color: dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Use Wallet Balance',
                        style: TextStyle(
                          fontSize: isTablet(context) ? 22 : 15.sp,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  widget.isLoading
                      ? const CustomCircularProgressIndicator()
                      : SizedBox(
                          height: 25,
                          child: Switch(
                            value: widget.isWalletEnabled && !isCurrencyMismatch,
                            onChanged: (balance > 0.0 && !isCurrencyMismatch)
                                ? (value) {
                                    widget.onWalletToggle(value);
                                  }
                                : null,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            activeThumbColor: dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor,
                            activeTrackColor: dark
                                ? AppTheme.primaryColor.withValues(alpha: 0.45)
                                : AppTheme.primaryColor.withValues(alpha: 0.28),
                            inactiveThumbColor: dark ? Colors.grey.shade400 : Colors.grey.shade300,
                            inactiveTrackColor: dark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200,
                          ),
                        ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildBalanceRow(
                context: context,
                label: 'Available Balance',
                value: MoneyDisplay.format(balance, currencyCode: walletCurrency),
                dark: dark,
              ),
              SizedBox(height: 8.h),
              _buildBalanceRow(
                context: context,
                label: 'Wallet Amount Used',
                value: MoneyDisplay.format(usedBalance, currencyCode: walletCurrency),
                dark: dark,
              ),
              SizedBox(height: 8.h),
              _buildBalanceRow(
                context: context,
                label: 'Remaining Wallet Balance',
                value: MoneyDisplay.format(remainingBalance, currencyCode: walletCurrency),
                dark: dark,
              ),
              if (isCurrencyMismatch) ...[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: dark
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                          : Colors.orange.shade200,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.r,
                        color: dark ? const Color(0xFFFBBF24) : Colors.orange.shade800,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Wallet currency ($walletCurrency) does not match cart currency (${widget.cartCurrencyCode}). Wallet payment is disabled for this order.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: dark ? const Color(0xFFFBBF24) : Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (balance <= 0) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: dark
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                              : Colors.orange.shade200,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16.r,
                            color: dark ? const Color(0xFFFBBF24) : Colors.orange.shade800,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Insufficient wallet balance',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: dark ? const Color(0xFFFBBF24) : Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
    );
  }

  Widget _buildBalanceRow({
    required BuildContext context,
    required String label,
    required String value,
    required bool dark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTablet(context) ? 16 : 13.5.sp,
              color: dark ? Colors.white70 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet(context) ? 16 : 13.5.sp,
            color: dark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


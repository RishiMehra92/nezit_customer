import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';

import '../../../utils/widgets/custom_image_container.dart';
import '../../../utils/widgets/money_display.dart';
import '../bloc/shared_cart_cubit.dart';
import '../model/shared_cart.dart';

enum SharedCartSheetOutcome { login, location, imported }

class SharedCartBottomSheet extends StatelessWidget {
  const SharedCartBottomSheet({super.key});

  void _import(BuildContext context, SharedCartAction action) {
    final cubit = context.read<SharedCartCubit>();
    if (!cubit.service.loggedIn) {
      Navigator.pop(context, SharedCartSheetOutcome.login);
      return;
    }
    cubit.importCart(action);
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);

    return BlocConsumer<SharedCartCubit, SharedCartState>(
      listener: (context, state) {
        if (state.result != null &&
            state.result!.skippedCount == 0 &&
            state.error == null) {
          Navigator.pop(context, SharedCartSheetOutcome.imported);
        }
      },
      builder: (context, state) => PopScope(
        canPop: !state.importing,
        child: SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.sizeOf(context).height *
                (MediaQuery.sizeOf(context).height < 500 ? .94 : .85),
            decoration: BoxDecoration(
              color: dark ? AppTheme.mainDarkContainerBgColor : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('sharedCartTitle'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet(context) ? 22 : 18.sp,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('close'),
                        onPressed: state.importing ? null : () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: dark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.preview?.title?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        state.preview!.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet(context) ? 16 : 13.sp,
                          color: dark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                Expanded(child: _body(context, state)),
                if (state.error != null && state.preview != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: dark
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.red.shade200,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: dark ? const Color(0xFFF87171) : Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: dark ? const Color(0xFFF87171) : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state.result != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(
                            context, SharedCartSheetOutcome.imported),
                        child: Text(
                          context.tr('close'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (state.preview?.items.isNotEmpty == true &&
                    state.preview?.isExpired != true)
                  Flexible(
                    flex: 0,
                    child: _actions(context, state),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SharedCartState state) {
    final dark = isDarkMode(context);

    if (state.loading) {
      return Center(
        child: CircularProgressIndicator(
          color: dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor,
        ),
      );
    }

    if (state.result != null) {
      final result = state.result!;
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: result.skippedItems.length + 1,
        itemBuilder: (context, index) => index == 0
            ? Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${context.tr('sharedCartImported')}${result.skippedCount > 0 ? '\n${context.tr('sharedCartSkipped')} (${result.skippedCount})' : ''}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
              )
            : _item(context, result.skippedItems[index - 1]),
      );
    }

    final preview = state.preview;
    if (preview == null) {
      final needsLocation = state.needsLocation;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                needsLocation
                    ? Icons.location_on_outlined
                    : Icons.error_outline_rounded,
                size: 48,
                color: dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                needsLocation
                    ? context.tr('sharedCartLocationRequired')
                    : state.error ?? context.tr('somethingWentWrong'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: dark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (needsLocation) {
                    Navigator.pop(context, SharedCartSheetOutcome.location);
                  } else {
                    context.read<SharedCartCubit>().load();
                  }
                },
                child: Text(
                  needsLocation ? context.tr('selectLocation') : context.tr('retry'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (preview.isExpired) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_off_outlined,
              size: 48,
              color: dark ? Colors.white38 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('sharedCartExpired'),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (preview.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_shopping_cart_outlined,
              size: 48,
              color: dark ? Colors.white38 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('sharedCartEmpty'),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: preview.items.length,
      itemBuilder: (context, index) => _item(context, preview.items[index]),
    );
  }

  Widget _item(BuildContext context, SharedCartItem item) {
    final dark = isDarkMode(context);
    final availability = item.reason ??
        (!item.storeOnline
            ? context.tr('storeCurrentlyClosed')
            : !item.available
                ? context.tr('outOfStock')
                : !item.deliverable
                    ? context.tr('notDeliverableToThisLocation')
                    : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                width: 0.5,
              ),
            ),
            child: item.image.isEmpty
                ? Icon(
                    Icons.shopping_bag_outlined,
                    color: dark ? Colors.white38 : Colors.grey.shade400,
                  )
                : CustomImageContainer(
                    imagePath: item.image,
                    fit: BoxFit.contain,
                    errorWidget: Icon(
                      Icons.shopping_bag_outlined,
                      color: dark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variantName.isNotEmpty && item.variantName != item.name) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.variantName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: dark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${context.tr('quantity')}: ${item.quantity}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: dark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    if (item.unitPrice != null && item.unitPrice! > 0)
                      Text(
                        MoneyDisplay.format(
                          item.unitPrice,
                          formattedAmount: item.formattedUnitPrice,
                          currencyCode: item.currencyCode,
                        ),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor,
                        ),
                      ),
                  ],
                ),
                if (availability?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      availability!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: dark ? const Color(0xFFF87171) : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, SharedCartState state) {
    final dark = isDarkMode(context);
    final service = context.read<SharedCartCubit>().service;
    final authenticated = service.loggedIn;
    final hasExistingItems = service.hasExistingItems;
    final accentColor = dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      decoration: BoxDecoration(
        color: dark ? AppTheme.mainDarkContainerBgColor : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          if (!authenticated)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.3 : 0.2),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasExistingItems
                          ? context.tr('sharedCartLoginRequired',
                              fallback: 'Sign in to combine or replace your cart.')
                          : context.tr('sharedCartLoginRequiredEmpty',
                              fallback: 'Sign in to add these items to your cart.'),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: state.importing
                  ? null
                  : () => _import(context, SharedCartAction.merge),
              child: state.importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      hasExistingItems
                          ? context.tr('mergeSharedCart',
                              fallback: 'Combine with my cart')
                          : context.tr('addToCart', fallback: 'Add to Cart'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          if (hasExistingItems) ...[
            const SizedBox(height: 4),
            Text(
              context.tr('mergeSharedCartDescription',
                  fallback: 'Keep your existing items and add the shared items.'),
              style: TextStyle(
                fontSize: 11.sp,
                color: dark ? Colors.white60 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: state.importing
                    ? null
                    : () => _import(context, SharedCartAction.replace),
                child: Text(
                  context.tr('replaceSharedCart',
                      fallback: 'Replace my cart'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('replaceSharedCartDescription',
                  fallback: 'Clear your current items and start fresh with these.'),
              style: TextStyle(
                fontSize: 11.sp,
                color: dark ? Colors.white60 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      ),
    );
  }
}

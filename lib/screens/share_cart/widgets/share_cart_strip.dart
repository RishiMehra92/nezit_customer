import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';

import '../../../config/helper.dart';
import '../../../config/theme.dart';
import '../../../config/dependency_injection_container.dart';
import '../../../services/auth_guard.dart';
import '../../../utils/widgets/custom_toast.dart';
import '../../../utils/widgets/money_display.dart';
import '../service/cart_native_share.dart';
import '../service/shared_cart_service.dart';

class ShareCartStrip extends StatefulWidget {
  final int? itemCount;
  final double? totalAmount;
  final String? currencyCode;
  const ShareCartStrip({super.key, this.itemCount, this.totalAmount, this.currencyCode});
  @override
  State<ShareCartStrip> createState() => _ShareCartStripState();
}

class _ShareCartStripState extends State<ShareCartStrip> {
  bool _sharing = false;

  int _resolveItemCount(int serverCount) {
    if (serverCount > 0) return serverCount;
    if (widget.itemCount != null && widget.itemCount! > 0) {
      return widget.itemCount!;
    }
    return getIt<SharedCartService>().cart.localRepo.getAllItems().length;
  }

  double _resolveTotalAmount() {
    if (widget.totalAmount != null && widget.totalAmount! > 0) {
      return widget.totalAmount!;
    }
    final items = getIt<SharedCartService>().cart.localRepo.getAllItems();
    return items.fold<double>(0.0, (sum, item) {
      final addonsTotal =
          item.addons.fold<double>(0.0, (aSum, a) => aSum + a.price);
      return sum + ((item.price + addonsTotal) * item.quantity);
    });
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      if (!await AuthGuard.ensureLoggedIn(context) || !mounted) return;
      final link = await getIt<SharedCartService>().createLink();
      if (!mounted) return;
      final count = _resolveItemCount(link.itemsCount);
      final total = _resolveTotalAmount();
      final formattedTotal = MoneyDisplay.format(
        total.truncateToDouble() == total
            ? total.toStringAsFixed(0)
            : total.toStringAsFixed(2),
        currencyCode: widget.currencyCode,
      );
      final message = context.tr(
        'shareCartMessage',
        args: {
          'count': count,
          'total': formattedTotal,
          'currency': widget.currencyCode ?? AppHelpers.currency,
          'url': link.url,
        },
        fallback:
            '🛒 Check out this cart! Picked out $count items worth $formattedTotal.\nTap the link to add them to your cart and place the order together:\n👉 ${link.url}',
      );
      final box = context.findRenderObject() as RenderBox;
      await CartNativeShare.share(
          url: link.url,
          message: message,
          title: context.tr('shareCart'),
          copyLabel: context.tr('copyCartLink'),
          copiedLabel: context.tr('cartLinkCopied'),
          origin: box.localToGlobal(Offset.zero) & box.size);
    } catch (error) {
      if (mounted) {
        ToastManager.show(
            context: context, message: error.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryColor,
      child: InkWell(
        onTap: _sharing ? null : _share,
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.share_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('shareCartPrompt'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              if (_sharing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('shareCartLinkLabel'),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

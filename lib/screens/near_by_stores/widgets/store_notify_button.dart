import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/store_detail/store_detail_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/screens/near_by_stores/repo/near_by_store_repo.dart';
import 'package:hyper_local/services/auth_guard.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'store_status_helper.dart';

class StoreNotifyButton extends StatefulWidget {
  final StoreData store;
  final ValueChanged<bool>? onNotificationChanged;

  const StoreNotifyButton({
    super.key,
    required this.store,
    this.onNotificationChanged,
  });

  @override
  State<StoreNotifyButton> createState() => _StoreNotifyButtonState();
}

class _StoreNotifyButtonState extends State<StoreNotifyButton> {
  late bool _isNotify;
  bool _isLoading = false;
  final NearByStoreRepo _repo = NearByStoreRepo();

  @override
  void initState() {
    super.initState();
    _isNotify = widget.store.isNotify ?? false;
  }

  @override
  void didUpdateWidget(covariant StoreNotifyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.store.isNotify != oldWidget.store.isNotify) {
      _isNotify = widget.store.isNotify ?? false;
    }
  }

  Future<void> _handleNotify() async {
    if (_isLoading) return;
    if (widget.store.id == null) return;

    if (!await AuthGuard.ensureLoggedIn(context)) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _repo.toggleStoreNotification(
        storeId: widget.store.id!,
        isNotify: true,
      );

      if (!mounted) return;

      setState(() {
        _isNotify = true;
      });

      _syncBlocs(true);
      widget.onNotificationChanged?.call(true);

      final message = response['message']?.toString() ??
          context.tr('notifyMeSuccess', fallback: 'You will be notified when this store is back online.');

      ToastManager.show(
        context: context,
        message: message,
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      final rawError =
          e.toString().replaceFirst('Exception: ', '').replaceAll('ApiException: ', '');
      ToastManager.show(
        context: context,
        message: rawError.isNotEmpty ? rawError : 'Failed to update notification',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUnnotify() async {
    if (_isLoading) return;
    if (widget.store.id == null) return;


    // Show warning confirmation dialog following existing UI structure & color scheme
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(TablerIcons.alert_triangle, color: Colors.amber[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('cancelNotification', fallback: 'Cancel Notification'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            context.tr('unnotifyStoreConfirm', fallback: 'Are you sure you want to stop receiving notifications when this store is back online?'),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                context.tr('cancel', fallback: 'Cancel'),
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(context.tr('confirm', fallback: 'Remove')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _repo.toggleStoreNotification(
        storeId: widget.store.id!,
        isNotify: false,
      );

      if (!mounted) return;

      setState(() {
        _isNotify = false;
      });

      _syncBlocs(false);
      widget.onNotificationChanged?.call(false);

      final message = response['message']?.toString() ??
          context.tr('notificationCancelledSuccess', fallback: 'Notification subscription cancelled.');

      ToastManager.show(
        context: context,
        message: message,
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      final rawError =
          e.toString().replaceFirst('Exception: ', '').replaceAll('ApiException: ', '');
      ToastManager.show(
        context: context,
        message: rawError.isNotEmpty ? rawError : 'Failed to cancel notification',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _syncBlocs(bool isNotify) {
    if (widget.store.id == null) return;
    try {
      context.read<NearByStoreBloc>().add(
            UpdateStoreNotification(
              storeId: widget.store.id!,
              isNotify: isNotify,
            ),
          );
    } catch (_) {}

    try {
      context.read<StoreDetailBloc>().add(
            UpdateStoreDetailNotification(
              isNotify: isNotify,
            ),
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.store.id == null) {
      return const SizedBox.shrink();
    }

    // Only show notify me button on stores which are closed
    final isClosed = StoreStatusHelper.isClosed(widget.store, context);
    if (!isClosed) {
      return const SizedBox.shrink();
    }

    final dark = isDarkMode(context);

    if (_isNotify) {
      // -------------------------------------------------------------
      // Notified State: Right Icon (Checkmark) + "Notified" + Minus Icon
      // -------------------------------------------------------------
      final badgeBg = dark ? Colors.green.shade900.withValues(alpha: 0.25) : Colors.green.shade50;
      final badgeBorder = dark ? Colors.green.shade700 : Colors.green.shade300;
      final accentColor = dark ? Colors.green.shade300 : Colors.green.shade700;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // Absorb taps so parent card doesn't trigger
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
              else ...[
                // Right (checkmark) icon
                Icon(
                  TablerIcons.check,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 4),
                // Notified text
                Text(
                  context.tr('notified', fallback: 'Notified'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(width: 6),
                // Minus icon (tap to unnotify with warning dialog)
                InkWell(
                  onTap: _isLoading ? null : _handleUnnotify,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade900,
                    ),
                    child: const Icon(TablerIcons.minus, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      // -------------------------------------------------------------
      // Initial State: "Notify Me" button
      // -------------------------------------------------------------
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isLoading ? null : _handleNotify,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                const Icon(
                  TablerIcons.bell,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr('notifyMe', fallback: 'Notify Me'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }
}

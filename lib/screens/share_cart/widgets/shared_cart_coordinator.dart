import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/dependency_injection_container.dart';
import '../../../config/global_keys.dart';
import '../../../deep_link.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_toast.dart';
import '../bloc/shared_cart_cubit.dart';
import '../service/shared_cart_links.dart';
import '../service/shared_cart_service.dart';
import 'shared_cart_bottom_sheet.dart';

/// Owns presentation across every route, including transitions through auth.
class SharedCartCoordinator extends StatefulWidget {
  final Widget child;
  const SharedCartCoordinator({super.key, required this.child});
  @override
  State<SharedCartCoordinator> createState() => _SharedCartCoordinatorState();
}

class _SharedCartCoordinatorState extends State<SharedCartCoordinator> {
  final _links = AppLinksDeepLink.instance;
  bool _presenting = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _links.pendingSharedCart.addListener(_schedule);
    MyAppRoute.router.routerDelegate.addListener(_schedule);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _links.initDeepLinks();
        _schedule();
      }
    });
  }

  void _schedule() {
    if (!mounted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      _links.handlePendingProductLink();
      final path = MyAppRoute.router.routeInformationProvider.value.uri.path;
      final code = _links.pendingSharedCart.value;
      if (!_presenting && code != null && canPresentSharedCart(path)) {
        _present(code);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _present(String code) async {
    final navigator = GlobalKeys.navigatorKey.currentState;
    final overlayContext = navigator?.overlay?.context;
    if (navigator == null ||
        overlayContext == null ||
        !overlayContext.mounted) {
      return;
    }
    _presenting = true;
    final cubit =
        SharedCartCubit(service: getIt<SharedCartService>(), code: code);
    final route = _SharedCartModalRoute(
      cubit: cubit,
      builder: (_) => BlocProvider.value(
          value: cubit, child: const SharedCartBottomSheet()),
    );
    // Rebuild the barrier when an import begins: dismissal is disabled until
    // the server responds, so closing cannot be mistaken for cancellation.
    final subscription =
        cubit.stream.listen((_) => route.changedExternalState());
    cubit.load();
    try {
      final result = await navigator.push(route);
      if (!mounted) return;
      final continuing = result == SharedCartSheetOutcome.login ||
          result == SharedCartSheetOutcome.location;
      if (!continuing && _links.pendingSharedCart.value == code) {
        _links.pendingSharedCart.value = null;
      }
      if (result == SharedCartSheetOutcome.login) {
        MyAppRoute.router.push(AppRoutes.login);
      } else if (result == SharedCartSheetOutcome.location) {
        MyAppRoute.router.push(AppRoutes.locationPicker, extra: {
          'isFromAddressPage': false,
          'isEdit': false,
          'isFromCartPage': false,
        });
      } else if (result == SharedCartSheetOutcome.imported &&
          overlayContext.mounted) {
        ToastManager.show(
            context: overlayContext,
            message: overlayContext.tr('sharedCartImported'),
            type: ToastType.success);
      }
    } finally {
      await subscription.cancel();
      await cubit.close();
      _presenting = false;
      _schedule();
    }
  }

  @override
  void dispose() {
    _links.pendingSharedCart.removeListener(_schedule);
    MyAppRoute.router.routerDelegate.removeListener(_schedule);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SharedCartModalRoute
    extends ModalBottomSheetRoute<SharedCartSheetOutcome> {
  final SharedCartCubit cubit;
  _SharedCartModalRoute({required this.cubit, required super.builder})
      : super(
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          useSafeArea: true,
          constraints: const BoxConstraints(maxWidth: 640),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          settings: const RouteSettings(name: 'shared-cart-preview'),
        );

  @override
  bool get barrierDismissible => !cubit.state.importing;

  @override
  bool get enableDrag => !cubit.state.importing;
}

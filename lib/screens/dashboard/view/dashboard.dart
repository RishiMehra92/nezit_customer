import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/config/notification_service.dart';
import 'package:hyper_local/config/theme.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../services/location/location_service.dart';
import '../../../services/cart_service.dart';
import '../../../services/clarity_service.dart';
import '../../../utils/widgets/custom_toast.dart';

class Dashboard extends StatefulWidget {
  final int index;
  final StatefulNavigationShell navigationShell;
  const Dashboard({super.key, required this.index, required this.navigationShell});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  late int _currentIndex;
  DateTime? _lastBackPressed;

  /// Drives the hide-on-scroll animation for the bottom nav.
  late final AnimationController _bottomNavController;

  @override
  void initState() {
    super.initState();
    _currentIndex = _calculateCurrentIndex();
    _bottomNavController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0, // start visible
    );
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings initializationSettingsDarwin = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Notification response received: ${response.payload}');
        if (response.payload != null) {
          try {
            log('User navigating from foreground notification tap');
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            NotificationService.handleNotificationNavigation(data);
          } catch (e) {
            log('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Debug: Print stored location
    final storedLocation = LocationService.getStoredLocation();
    if (storedLocation != null) {
      log('Stored Location: ${storedLocation.fullAddress}');
      log('Area: ${storedLocation.area}');
      log('City: ${storedLocation.city}');
      log('State: ${storedLocation.state}');
    } else {
      log('No location stored in Hive');
    }
    context.read<CartBloc>().add(LoadCart());
    ClarityService.initialize(context);
  }

  int _calculateCurrentIndex() {
    int shellIndex = widget.navigationShell.currentIndex;
    final bool isDiscoverEnabled = SettingsData.instance.watchAndBuy?.enabled == true;

    if (AppHelpers.systemVendorTypeIsSingle) {
      if (shellIndex == 0) return 0;
      if (shellIndex == 1) return 1;
      if (shellIndex == 5) return isDiscoverEnabled ? 2 : 0; // Fallback to 0 if hidden
      if (shellIndex == 4) return isDiscoverEnabled ? 3 : 2; // My Orders
      if (shellIndex == 3) return isDiscoverEnabled ? 4 : 3; // Account
      return 0;
    } else {
      if (shellIndex == 0) return 0;
      if (shellIndex == 1) return 1;
      if (shellIndex == 5) return isDiscoverEnabled ? 2 : 0; // Discover
      if (shellIndex == 3) return isDiscoverEnabled ? 3 : 2; // Account (Stores hidden)
      return 0;
    }
  }

  void _goBranch(int index) {
    // Always reveal the bottom nav when user switches tabs — they'd expect
    _bottomNavController.forward();

    final bool isDiscoverEnabled = SettingsData.instance.watchAndBuy?.enabled == true;

    int targetShellIndex;
    if (AppHelpers.systemVendorTypeIsSingle) {
      if (index == 0) {
        targetShellIndex = 0;
      } else if (index == 1) {
        targetShellIndex = 1;
      } else if (isDiscoverEnabled && index == 2) {
        targetShellIndex = 5; // Discover
      } else if ((isDiscoverEnabled && index == 3) || (!isDiscoverEnabled && index == 2)) {
        targetShellIndex = 4; // My Orders
      } else if ((isDiscoverEnabled && index == 4) || (!isDiscoverEnabled && index == 3)) {
        targetShellIndex = 3; // Account
      } else {
        targetShellIndex = 0;
      }
    } else {
      if (index == 0) {
        targetShellIndex = 0;
      } else if (index == 1) {
        targetShellIndex = 1;
      } else if (isDiscoverEnabled && index == 2) {
        targetShellIndex = 5; // Discover
      } else if ((isDiscoverEnabled && index == 3) || (!isDiscoverEnabled && index == 2)) {
        targetShellIndex = 3; // Account
      } else {
        targetShellIndex = 0;
      }
    }

    widget.navigationShell.goBranch(targetShellIndex);
    _currentIndex = index;
    setState(() {});
    context.read<CartBloc>().add(LoadCart());
  }

  /// Reacts to any vertical scroll anywhere inside the shell body and.
  bool _handleScrollNotification(UserScrollNotification notification) {
    // Ignore horizontal scrolls (carousels, TabBarViews, etc).
    if (notification.metrics.axis != Axis.vertical || _currentIndex == 4) {
      return false;
    }

    switch (notification.direction) {
      case ScrollDirection.reverse:
        // User is scrolling DOWN → hide.
        if (_bottomNavController.status != AnimationStatus.dismissed &&
            _bottomNavController.status != AnimationStatus.reverse) {
          _bottomNavController.reverse();
        }
        break;
      case ScrollDirection.forward:
        // User is scrolling UP → show.
        if (_bottomNavController.status != AnimationStatus.completed &&
            _bottomNavController.status != AnimationStatus.forward) {
          _bottomNavController.forward();
        }
        break;
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  Future<void> _handleBack(BuildContext context) async {
    if (widget.index != 0) {
      _goBranch(0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ToastManager.show(
        context: context,
        message: context.tr('pressAgainToExitTheApp', fallback: 'Press again to exit the app'),
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (Global.shouldRedirectToHome) {
      Global.homeNeedsReferralCheckNotifier.value = true;
      Global.shouldRedirectToHome = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goBranch(0);
      });
    }
    _currentIndex = _calculateCurrentIndex();
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartLoaded) {
          if (state.errorMessage != null) {
            ToastManager.show(
              context: context,
              message: state.errorMessage ?? 'Failed to add item to cart',
              type: ToastType.error,
            );
          }
        }
        // context.read<GetUserCartBloc>().add(FetchUserCart());
        CartService.triggerCartAnimationOnFirstAdd(context, state);
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          await _handleBack(context);
        },
        child: Scaffold(
          // Listen to scroll notifications from any descendant page and
          body: NotificationListener<UserScrollNotification>(
            onNotification: _handleScrollNotification,
            child: widget.navigationShell,
          ),
          // SizeTransition both slides the nav down and shrinks its
          bottomNavigationBar: SizeTransition(
            sizeFactor: _bottomNavController,
            alignment: Alignment.topCenter,
            child: Container(
              height: AppHelpers.bottomNavBarHeight,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1.0,
                  ),
                ),
              ),
              // Stack the moving indicator on top of the BottomNavigationBar
              child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _currentIndex,
                  selectedItemColor:
                      isDarkMode(context) ? AppTheme.primaryColor : Theme.of(context).colorScheme.tertiary,
                  unselectedItemColor: isDarkMode(context)
                      ? const Color(0xFF6B6B6B)
                      : Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  onTap: _goBranch,
                  items: [
                    BottomNavigationBarItem(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedHome03)

                      // Icon(widget.navigationShell.currentIndex == 0
                      //     ? RemixIcons.home_smile_fill
                      //     : RemixIcons.home_smile_line)

                      ,
                      label: context.tr('home', fallback: 'Home'),
                    ),
                    BottomNavigationBarItem(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedMenuSquare),

                      // Icon(widget.navigationShell.currentIndex == 1
                      //     ? HeroiconsSolid.squares2x2
                      //     : HeroiconsOutline.squares2x2)

                      label: context.tr('categories', fallback: 'Categories'),
                    ),
                    if (SettingsData.instance.watchAndBuy?.enabled == true)
                      BottomNavigationBarItem(
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlayListFavourite02),
                        label: SettingsData.instance.watchAndBuy?.title ?? 'Watch & Buy',
                      ),
                    if (AppHelpers.systemVendorTypeIsSingle)
                      BottomNavigationBarItem(
                        icon: Icon(widget.navigationShell.currentIndex == 4
                            ? HeroiconsSolid.shoppingCart
                            : HeroiconsOutline.shoppingCart),
                        label: context.tr('myOrders', fallback: 'My Orders'),
                      ),
                    BottomNavigationBarItem(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedUserCircle02)

                      // Icon(widget.navigationShell.currentIndex == 3
                      //     ? HeroiconsSolid.userCircle
                      //     : HeroiconsOutline.userCircle)

                      ,
                      label: context.tr('account', fallback: 'Account'),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bottomNavController.dispose();
    super.dispose();
  }
}

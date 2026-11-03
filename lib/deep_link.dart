import 'dart:async';
import 'dart:developer';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'screens/share_cart/service/shared_cart_links.dart';

class AppLinksDeepLink {
  AppLinksDeepLink._privateConstructor();
  static final AppLinksDeepLink _instance =
      AppLinksDeepLink._privateConstructor();
  static AppLinksDeepLink get instance => _instance;

  final AppLinks _appLinks = AppLinks();
  final pendingSharedCart = ValueNotifier<String?>(null);
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;
  Uri? _lastProcessedUri;
  Uri? _pendingProductUri;

  Future<void> initDeepLinks() async {
    if (_isInitialized) return;
    _isInitialized = true;
    // Subscribe before reading the launch URI to avoid losing a warm link.
    _linkSubscription = _appLinks.uriLinkStream.listen(_receive,
        onError: (Object error) => log('Deep link error: $error'));
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _receive(initialUri);
    } catch (error) {
      log('Deep link initialization error: $error');
    }
  }

  void _receive(Uri uri) {
    if (_isFirebaseAuthCallback(uri) || _lastProcessedUri == uri) return;
    _lastProcessedUri = uri;
    Future.delayed(const Duration(seconds: 2), () {
      if (_lastProcessedUri == uri) {
        _lastProcessedUri = null;
      }
    });
    final code = sharedCartCodeFromUri(uri);
    if (code != null) {
      pendingSharedCart.value = code;
      return;
    }
    if (uri.pathSegments.contains('cart') &&
        uri.pathSegments.contains('shared')) {
      return;
    }
    _pendingProductUri = uri;
    handlePendingProductLink();
  }

  void handlePendingProductLink() {
    final uri = _pendingProductUri;
    final location = MyAppRoute.router.routeInformationProvider.value.uri.path;
    if (uri == null || !canPresentSharedCart(location)) return;
    _pendingProductUri = null;
    final slug = _extractProductSlug(uri);
    if (slug == null || slug.isEmpty) return;
    MyAppRoute.router.go(AppRoutes.home);
    MyAppRoute.router
        .push(AppRoutes.productDetailPage, extra: {'productSlug': slug});
  }

  /// Returns true when the URI is a Firebase Auth callback that the Firebase.
  bool _isFirebaseAuthCallback(Uri uri) {
    // Google's reverse-client-ID scheme is used for OAuth + Firebase callbacks.
    if (uri.scheme.startsWith('com.googleusercontent.apps.')) return true;

    // Custom `<bundle>://firebaseauth/...` or `<scheme>://firebase-auth/...`
    final host = uri.host.toLowerCase();
    if (host == 'firebaseauth' || host == 'firebase-auth') return true;

    // Firebase Auth callback query params (any of these means Firebase owns it).
    if (uri.queryParameters.containsKey('deep_link_id')) return true;
    if (uri.queryParameters.containsKey('authType')) return true;

    // Email-link sign-in and reCAPTCHA callbacks on the Firebase hosting domain.
    if (uri.path.contains('/__/auth/')) return true;

    return false;
  }

  String? _extractProductSlug(Uri uri) {
    if (uri.pathSegments.contains('cart') &&
        uri.pathSegments.contains('shared')) {
      return null;
    }
    if (uri.pathSegments.contains('product') ||
        uri.pathSegments.contains('p')) {
      final index = uri.pathSegments.contains('product')
          ? uri.pathSegments.indexOf('product')
          : uri.pathSegments.indexOf('p');

      if (index != -1 && index + 1 < uri.pathSegments.length) {
        final slug = uri.pathSegments[index + 1];
        if (slug.isNotEmpty) return slug;
      }
    }

    // 2. Check query parameters (e.g., ?slug=my-slug or ?product_slug=my-slug)
    if (uri.queryParameters.containsKey('slug')) {
      return uri.queryParameters['slug'];
    }
    if (uri.queryParameters.containsKey('product_slug')) {
      return uri.queryParameters['product_slug'];
    }

    // 3.
    const keywords = {'product', 'p', 'home', 'shop', 'categories', 'cart'};
    if (uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last;
      if (lastSegment.isNotEmpty &&
          !keywords.contains(lastSegment.toLowerCase())) {
        return lastSegment;
      }
    }

    return null;
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }
}

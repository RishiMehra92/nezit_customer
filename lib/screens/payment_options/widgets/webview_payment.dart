import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'dart:async';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/helper.dart';
import '../repo/payment_repository.dart';

class WebViewPaymentPage extends StatefulWidget {
  final Function()? onPaymentSuccess;
  final Function()? onPaymentFailure;
  final String paymentUrl;
  final String? orderSlug;
  final String? transactionUuid;
  final bool isTipPayment;

  const WebViewPaymentPage({
    super.key,
    this.onPaymentSuccess,
    required this.onPaymentFailure,
    required this.paymentUrl,
    this.orderSlug,
    this.transactionUuid,
    this.isTipPayment = false,
  });

  @override
  State<WebViewPaymentPage> createState() => _WebViewPaymentPageState();
}

class _WebViewPaymentPageState extends State<WebViewPaymentPage> {
  late final WebViewController _controller;
  bool isLoading = true;
  late String checkoutUrl = '';

  // Flag to track if we've already handled redirection
  bool hasRedirected = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    checkoutUrl = widget.paymentUrl;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
            _checkForRedirection(url);
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            _checkForRedirection(url);
          },
          onUrlChange: (UrlChange change) {
            _checkForRedirection(change.url ?? '');
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            _checkForRedirection(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(checkoutUrl));

    if (widget.transactionUuid != null && widget.transactionUuid!.isNotEmpty) {
      _startTransactionPolling(widget.transactionUuid!);
    } else if (widget.orderSlug != null && widget.orderSlug!.isNotEmpty) {
      _startPolling(widget.orderSlug!);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startTransactionPolling(String uuid) {
    log('Starting background polling for transaction: $uuid');
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final dataResponse = await PaymentRepository().checkPaymentTransactionStatus(uuid);
        if (dataResponse != null) {
          final data = dataResponse['data'];
          if (data != null) {
            final status = data['status']?.toString().toLowerCase().trim();
            final paymentStatus = data['payment_status']?.toString().toLowerCase().trim();
            
            if (status == 'payment_failed' || paymentStatus == 'failed') {
              log('Payment FAILURE detected via transaction polling. UUID: $uuid');
              _pollingTimer?.cancel();
              _handleFailure();
            } else if (status == 'order_created' && paymentStatus == 'completed') {
              log('Payment SUCCESS detected via transaction polling. UUID: $uuid');
              final order = data['order'];
              if (order != null && order['slug'] != null) {
                final orderSlug = order['slug'];
                _pollingTimer?.cancel();
                
                try {
                  // Fetch order details before navigating
                  await AppHelpers.apiBaseHelper.getAPICall(
                    '${ApiRoutes.orderDetailApi}$orderSlug',
                    {},
                  );
                } catch (e) {
                  log('Error fetching order detail: $e');
                }

                _handleSuccessWithSlug(orderSlug);
              }
            } else if (paymentStatus == 'completed' && status != 'order_created') {
               log('Payment SUCCESS (No order) detected via transaction polling. UUID: $uuid');
               _pollingTimer?.cancel();
               _handleSuccess(null);
            }
          }
        }
      } catch (e) {
        log('Error polling transaction status: $e');
      }
    });
  }

  void _startPolling(String orderSlug) {
    log('Starting background polling for order: $orderSlug');
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final response = await AppHelpers.apiBaseHelper.getAPICall(
          '${ApiRoutes.orderDetailApi}$orderSlug',
          {},
        );
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data['data'];
          if (data != null) {
            final orderData = data['order'] ?? data;

            if (widget.isTipPayment) {
              final double riderTip = double.tryParse(
                      orderData['rider_tip_amount']?.toString() ?? '0') ??
                  0.0;
              log('Background polling rider tip for $orderSlug: $riderTip');
              if (riderTip > 0) {
                log('Payment SUCCESS detected via Tip Polling. Order: $orderSlug, Tip: $riderTip');
                _pollingTimer?.cancel();
                _handleSuccess(null);
              }
            } else {
              final paymentStatus =
                  orderData['payment_status']?.toString().toLowerCase().trim();
              log('Background polling status for $orderSlug: $paymentStatus');
              if (paymentStatus == 'paid' ||
                  paymentStatus == 'success' ||
                  paymentStatus == 'completed') {
                log('Payment SUCCESS detected via OPTION 2 (Background API Polling). Order: $orderSlug, Status: $paymentStatus');
                _pollingTimer?.cancel();
                _handleSuccess(null);
              }
            }
          }
        }
      } catch (e) {
        log('Error polling order status: $e');
      }
    });
  }

  void _checkForRedirection(String url) {
    log('Redirection URL $url');
    if (hasRedirected) return;

    if (widget.transactionUuid != null && widget.transactionUuid!.isNotEmpty) {
      // For transaction polling, we only intercept failure URLs. 
      // Success is handled by the background poller to ensure we get the order slug.
      if (url.contains('cancel') ||
          url.contains('payment_intent=failed') ||
          url.contains('status=failed') ||
          url.contains('error')) {
        log('Payment FAILURE detected via URL parameter interception. URL: $url');
        hasRedirected = true;
        _handleFailure();
      }
      return;
    }

    if (url.contains('success') ||
        url.contains('payment_intent=succeeded') ||
        url.contains('status=succeeded') ||
        url.contains('status=completed') ||
        url.contains('payment_status=paid') ||
        url.contains('status=approved') ||
        url.contains('collection_status=approved') ||
        url.contains('trxref')) {
      log('Payment SUCCESS detected via OPTION 1 (URL parameter interception). URL: $url');
      final uri = Uri.parse(url);
      final ref = uri.queryParameters['reference'] ??
          uri.queryParameters['trxref'] ??
          uri.queryParameters['payment_id'] ??
          uri.queryParameters['collection_id'];
      hasRedirected = true;
      _handleSuccess(ref);
    } else if (url.contains('cancel') ||
        url.contains('payment_intent=failed') ||
        url.contains('status=failed') ||
        url.contains('error')) {
      log('Payment FAILURE detected via URL parameter interception. URL: $url');
      hasRedirected = true;
      _handleFailure();
    }
  }

  void _handleSuccess(String? reference) {
    // Show success message
    ToastManager.show(
        context: context,
        message: context.tr('paymentSuccessful'),
        type: ToastType.success);

    // Delay to allow the user to see the message
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (widget.onPaymentSuccess != null) {
          widget.onPaymentSuccess!();
        }
        Navigator.of(context).pop({
          'success': true,
          'message': 'Payment completed successfully',
          'payment_id': reference,
          'signature': reference,
          'order_id': reference,
          'reference': reference,
        });
      }
    });
  }

  void _handleSuccessWithSlug(String orderSlug) {
    ToastManager.show(
        context: context,
        message: context.tr('paymentSuccessful'),
        type: ToastType.success);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (widget.onPaymentSuccess != null) {
          widget.onPaymentSuccess!();
        }
        Navigator.of(context).pop({
          'success': true,
          'message': 'Payment completed successfully',
          'order_slug': orderSlug,
          'order_id': orderSlug,
          'payment_id': orderSlug,
          'reference': orderSlug,
        });
      }
    });
  }

  void _handleFailure() {
    // Show failure message
    ToastManager.show(
        context: context,
        message: context.tr('paymentFailedOrCancelled'),
        type: ToastType.error);

    // Delay to allow the user to see the message
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (widget.onPaymentFailure != null) {
          widget.onPaymentFailure!();
        }
        Navigator.of(context).pop({
          'success': false,
          'error': 'Payment cancelled or failed',
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: hasRedirected,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !hasRedirected) {
          // If user tried to pop but we're not allowing it, treat as cancellation
          _handleFailure();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F2027),
          title: Text(
            context.tr('paymentMethod'),
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Handle manual back button press
              if (!hasRedirected) {
                _handleFailure();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          elevation: 0,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2C5364),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('loadingPaymentPage'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF203A43),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

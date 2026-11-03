import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/payment_config.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/screens/payment_options/widgets/webview_payment.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe
    hide PaymentMethodType;

import '../../../config/helper.dart';

/// Repository class to handle all payment gateway integrations.
class PaymentRepository {
  // Singleton pattern
  static final PaymentRepository _instance = PaymentRepository._internal();
  factory PaymentRepository() => _instance;
  PaymentRepository._internal();

  Future<Map<String, dynamic>> initiatePayment({
    required BuildContext context,
    required PaymentMethodType paymentMethodType,
    required double amount,
    required bool addMoneyToWallet,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      switch (paymentMethodType) {
        case PaymentMethodType.razorpay:
          return await _initiateRazorpayPayment(
              context: context,
              amount: amount,
              additionalData: additionalData,
              addMoneyToWallet: addMoneyToWallet);

        case PaymentMethodType.stripe:
          return await _initiateStripePayment(
              context: context,
              amount: amount,
              additionalData: additionalData,
              addMoneyToWallet: addMoneyToWallet);

        case PaymentMethodType.paystack:
          return await _initiatePaystackPayment(
              context: context,
              amount: amount,
              additionalData: additionalData,
              addMoneyToWallet: addMoneyToWallet);

        case PaymentMethodType.paypal:
          return {};

        case PaymentMethodType.flutterwave:
          return await _initiateFlutterWavePayment(
              context: context,
              amount: amount,
              additionalData: additionalData,
              addMoneyToWallet: addMoneyToWallet);

        case PaymentMethodType.mercadoPago:
          return await _initiateMercadoPagoPayment(
              context: context,
              amount: amount,
              additionalData: additionalData,
              addMoneyToWallet: addMoneyToWallet);

        case PaymentMethodType.xendit:
          return await _initiateXenditPayment(
              context: context,
              amount: amount,
              additionalData: additionalData,
              addMoneyToWallet: addMoneyToWallet);

        case PaymentMethodType.wallet:
          return {};

        case PaymentMethodType.cod:
          return {};

        default:
          return {
            'success': false,
            'error': 'Payment method not supported',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _initiateRazorpayPayment({
    required BuildContext context,
    required double amount,
    Map<String, dynamic>? additionalData,
    required bool addMoneyToWallet,
  }) async {
    try {
      dynamic response;
      final String currencyCode = (additionalData?['currency'] != null && additionalData!['currency'].toString().isNotEmpty)
          ? additionalData['currency'].toString()
          : (additionalData?['currency_code'] != null && additionalData!['currency_code'].toString().isNotEmpty)
              ? additionalData['currency_code'].toString()
              : (SettingsData.instance.system?.currency ?? 'INR');

      if (addMoneyToWallet) {
        response = await AppHelpers.apiBaseHelper.postAPICall(
            ApiRoutes.prepareWalletRechargeApi, {
          "amount": amount.toInt(),
          "payment_method": 'razorpayPayment',
          "currency": currencyCode,
          "description": ''
        });
      } else {
        response =
            await AppHelpers.apiBaseHelper.postAPICall(ApiRoutes.razorpayApi, {
          "amount": amount,
          "currency": currencyCode,
          "receipt": DateTime.now().toString()
        });
      }

      if (response.data['success'] == true) {
        final Completer<Map<String, dynamic>> paymentCompleter =
            Completer<Map<String, dynamic>>();

        final razorpay = Razorpay();

        final walletResponse = response.data['data']['payment_response'];
        final normalResponse = response.data['data'];

        final int finalAmount = addMoneyToWallet
            ? (walletResponse['amount_due'] is int
                ? walletResponse['amount_due']
                : double.tryParse(walletResponse['amount_due'].toString())
                        ?.toInt() ??
                    0)
            : (amount * 100).toInt();

        final String? finalOrderId = addMoneyToWallet
            ? walletResponse['id']
            : normalResponse['id'] ?? normalResponse['order_id'];

        var options = {
          'key': SettingsData.instance.payment!.razorpayKeyId,
          'amount': finalAmount,
          'name': AppConstant.appName,
          'currency': currencyCode,
          'description': addMoneyToWallet ? 'Recharge' : 'Order',
          'order_id': finalOrderId,
          'prefill': {
            'contact': additionalData?['phone'] ?? '',
            'email': additionalData?['email'] ?? ''
          },
        };

        razorpay.open(options);

        razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
            (PaymentSuccessResponse response) {
          // Complete the future with success result
          if (!paymentCompleter.isCompleted) {
            paymentCompleter.complete({
              'success': true,
              'message': 'Payment done successfully',
              'signature': response.signature,
              'order_id': response.orderId,
              'payment_id': response.paymentId,
            });
          }
          // Clean up
          razorpay.clear();
        });

        // Error callback
        razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
            (PaymentFailureResponse response) {
          // Complete the future with error result
          if (!paymentCompleter.isCompleted) {
            paymentCompleter.complete({
              'success': false,
              'message': response.message ?? 'Payment failed',
              'error_code': response.code,
              'error_description': response.error?.toString(),
            });
          }

          // Clean up
          razorpay.clear();
        });

        // External wallet callback (optional)
        razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
            (ExternalWalletResponse response) {
          if (!paymentCompleter.isCompleted) {
            paymentCompleter.complete({
              'success': false,
              'message': 'Payment cancelled - External wallet selected',
              'wallet_name': response.walletName,
            });
          }

          razorpay.clear();
        });

        // Wait for payment completion and return result
        return await paymentCompleter.future;
      } else {
        return {
          'success': false,
          'error': 'Razorpay integration pending',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Razorpay payment failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _initiateStripePayment({
    required BuildContext context,
    required double amount,
    Map<String, dynamic>? additionalData,
    required bool addMoneyToWallet,
  }) async {
    try {
      final paymentSettings = SettingsData.instance.payment;

      // Validation
      if (paymentSettings?.stripePublishableKey!.isEmpty != false) {
        return {'success': false, 'error': 'Stripe not configured'};
      }

      // Initialize Stripe
      stripe.Stripe.publishableKey = paymentSettings!.stripePublishableKey!;

      // Create Payment Intent
      final systemCurrency = SettingsData.instance.system?.currency?.toString();
      final currency = (systemCurrency != null && systemCurrency.isNotEmpty)
          ? systemCurrency
          : (paymentSettings.stripeCurrencyCode!.isNotEmpty
              ? paymentSettings.stripeCurrencyCode
              : 'USD');

      dynamic response;

      if (addMoneyToWallet) {
        response = await AppHelpers.apiBaseHelper.postAPICall(
            ApiRoutes.prepareWalletRechargeApi, {
          "amount": amount.toInt(),
          "payment_method": 'stripePayment',
          "description": ''
        });
      } else {
        response = await AppHelpers.apiBaseHelper.postAPICall(
          ApiRoutes.stripeCreatePaymentIntentApi,
          {
            'amount': amount.toInt(),
            'currency': currency,
            if (additionalData != null) 'additionalData': additionalData,
          },
        );
      }

      if (response.data['success'] != true) {
        return {
          'success': false,
          'error': response.data['data']?['error'] ??
              response.data['message'] ??
              'Payment failed'
        };
      }

      // Get client secret
      final data = response.data['data'] ?? {};
      final clientSecret = addMoneyToWallet
          ? data['payment_response']['clientSecret'].toString()
          : data['clientSecret'].toString();

      if (response.data['data'].isEmpty || response.data['data'] == null) {
        return {'success': false, 'error': 'Invalid payment response'};
      }

      if (context.mounted) {
        await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            merchantDisplayName: AppConstant.appName,
            paymentIntentClientSecret: clientSecret,
            googlePay: stripe.PaymentSheetGooglePay(
              merchantCountryCode: 'US',
              testEnv: true,
              currencyCode: currency,
            ),
            billingDetailsCollectionConfiguration:
                const stripe.BillingDetailsCollectionConfiguration(
              name: stripe.CollectionMode.always,
              email: stripe.CollectionMode.always,
            ),
            allowsDelayedPaymentMethods: true,
            style: Theme.of(context).brightness == Brightness.dark
                ? ThemeMode.light
                : ThemeMode.light,
          ),
        );
      }

      await stripe.Stripe.instance.presentPaymentSheet();

      // Extract payment ID and return success
      final paymentId = _extractPaymentId(clientSecret);

      return {
        'success': true,
        'message': 'Payment completed successfully',
        'payment_id': paymentId,
        'signature': clientSecret,
        'order_id': clientSecret,
      };
    } on stripe.StripeException catch (e) {
      return {
        'success': false,
        'error': e.error.message ?? 'Payment cancelled'
      };
    } catch (e) {
      return {'success': false, 'error': 'Payment failed: ${e.toString()}'};
    }
  }

  // Helper function (place outside the main function)
  String _extractPaymentId(String clientSecret) {
    final parts = clientSecret.split('_');
    return parts.length >= 2 ? '${parts[0]}_${parts[1]}' : clientSecret;
  }

  Future<Map<String, dynamic>> _initiatePaystackPayment({
    required BuildContext context,
    required double amount,
    Map<String, dynamic>? additionalData,
    required bool addMoneyToWallet,
  }) async {
    try {
      final paymentSettings = SettingsData.instance.payment;

      // Validation
      if (paymentSettings?.paystackPublicKey!.isEmpty != false) {
        return {'success': false, 'error': 'Paystack not configured'};
      }

      dynamic response;
      if (addMoneyToWallet) {
        response = await AppHelpers.apiBaseHelper.postAPICall(
            ApiRoutes.prepareWalletRechargeApi, {
          "amount": amount.toInt(),
          "payment_method": 'paystackPayment',
          "description": ''
        });
      } else {
        response = await AppHelpers.apiBaseHelper.postAPICall(
          ApiRoutes.paystackCreateOrderApi,
          {
            'amount': amount.toInt(),
          },
        );
      }

      // Check if order creation was successful
      if (response.data['success'] != true) {
        return {
          'success': false,
          'error': response.data['message'] ?? 'Failed to create order',
        };
      }

      // Extract order details from response
      final data = response.data['data'] ?? {};
      // Access code is required for the new SDK
      final accessCode = data['payment_response']['access_code']?.toString();
      final authorizationUrl =
          data['payment_response']['authorization_url']?.toString();

      if (accessCode == null || accessCode.isEmpty || accessCode == 'null') {
        return {
          'success': false,
          'error': 'Access code not received from server',
        };
      }

      final orderId = addMoneyToWallet
          ? (data['wallet_transaction_id']?.toString() ?? accessCode)
          : (data['order_id']?.toString() ?? accessCode);

      if (!context.mounted) {
        return {'success': false, 'error': 'Context not mounted'};
      }

      // Launch Paystack WebView
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewPaymentPage(
            paymentUrl: authorizationUrl!,
            onPaymentSuccess: () {},
            onPaymentFailure: () {},
          ),
        ),
      );

      if (result['success'] == true) {
        // We assume success if we got the redirect signal.

        return {
          'success': true,
          'message': 'Payment completed successfully',
          'payment_id': result['payment_id'],
          'signature': result['signature'],
          'order_id': orderId,
          'reference': result['reference'],
        };
      } else {
        return {
          'success': false,
          'error': 'Payment cancelled or failed',
        };
      }
    } catch (e) {
      log('Paystack error: $e');
      return {
        'success': false,
        'error': 'Paystack payment failed: ${e.toString()}'
      };
    }
  }

  String generateSimpleReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'REF_$timestamp';
  }

  Future<Map<String, dynamic>> _initiateFlutterWavePayment({
    required BuildContext context,
    required double amount,
    Map<String, dynamic>? additionalData,
    required bool addMoneyToWallet,
  }) async {
    try {
      dynamic response;

      if (addMoneyToWallet) {
        response = await AppHelpers.apiBaseHelper
            .postAPICall(ApiRoutes.prepareWalletRechargeApi, {
          "amount": amount.toInt(),
          "payment_method": 'flutterwavePayment',
          "description": ''
        });
      } else {
        final rawOrderId = additionalData?['orderId'] ?? additionalData?['order_id'] ?? 0;
        final int orderId = rawOrderId is int ? rawOrderId : (int.tryParse(rawOrderId.toString()) ?? 0);
        if (orderId == 0) {
          return {'success': false, 'error': 'Order ID is required'};
        }

        response = await AppHelpers.apiBaseHelper.postAPICall(
            ApiRoutes.flutterwavePostTipApi,
            {
              "order_id": orderId,
              "rider_tip_amount": amount.toInt(),
            }
        );
      }

      if (response.data['success'] != true) {
        return {
          'success': false,
          'error': response.data['data']?['error'] ??
              response.data['message'] ??
              'Payment failed'
        };
      }

      final data = response.data['data'] ?? {};

      if (data.isEmpty) {
        return {'success': false, 'error': 'Invalid payment response'};
      }

      String paymentUrl = '';
      if (data is String) {
        paymentUrl = data;
      } else if (data is Map) {
        paymentUrl = data['link']?.toString() ??
            data['payment_url']?.toString() ??
            data['invoice_url']?.toString() ??
            data['payment_response']?['link']?.toString() ??
            data['payment_response']?['invoice_url']?.toString() ??
            data['payment_response']?['url']?.toString() ??
            '';
      }

      if (paymentUrl.isEmpty) {
        return {'success': false, 'error': 'Payment URL not found'};
      }

      if (addMoneyToWallet) {
        return {
          'success': true,
          'message': 'Payment completed successfully',
          'payment_id': paymentUrl,
          'signature': paymentUrl,
          'order_id': paymentUrl,
        };
      }

      // Launch WebView Payment for checkout flow (rider tips, etc. where order exists)
      if (!context.mounted) {
        return {'success': false, 'error': 'Context not mounted'};
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewPaymentPage(
            paymentUrl: paymentUrl,
            orderSlug: additionalData?['orderSlug']?.toString() ?? '',
            isTipPayment: true,
            onPaymentSuccess: () {},
            onPaymentFailure: () {},
          ),
        ),
      );

      if (result != null && result is Map && result['success'] == true) {
        return {
          'success': true,
          'message': 'Payment completed successfully',
          'payment_id': result['payment_id'] ?? result['reference'] ?? 'FLUTTERWAVE_REF',
          'signature': result['signature'] ?? result['reference'] ?? 'FLUTTERWAVE_REF',
          'order_id': result['order_id'] ?? result['reference'] ?? 'FLUTTERWAVE_REF',
        };
      } else {
        return {
          'success': false,
          'error': 'Payment cancelled or failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Payment failed: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> _initiateXenditPayment({
    required BuildContext context,
    required double amount,
    Map<String, dynamic>? additionalData,
    required bool addMoneyToWallet,
  }) async {
    try {
      dynamic response;

      if (addMoneyToWallet) {
        response = await AppHelpers.apiBaseHelper.postAPICall(
            ApiRoutes.prepareWalletRechargeApi, {
          "amount": amount.toInt(),
          "payment_method": 'xenditPayment',
          "description": ''
        });
      } else {
        final rawOrderId = additionalData?['orderId'] ?? additionalData?['order_id'] ?? 0;
        final int orderId = rawOrderId is int ? rawOrderId : (int.tryParse(rawOrderId.toString()) ?? 0);
        if (orderId == 0) {
          return {'success': false, 'error': 'Order ID is required'};
        }

        response = await AppHelpers.apiBaseHelper.postAPICall(
            ApiRoutes.xenditPostTipApi,
            {
              "order_id": orderId,
              "rider_tip_amount": amount.toInt(),
            }
        );
      }

      if (response.data['success'] != true) {
        return {
          'success': false,
          'error': response.data['data']?['error'] ??
              response.data['message'] ??
              'Payment failed'
        };
      }

      final data = response.data['data'] ?? {};

      if (data.isEmpty) {
        return {'success': false, 'error': 'Invalid payment response'};
      }

      String paymentUrl = '';
      if (data is String) {
        paymentUrl = data;
      } else if (data is Map) {
        paymentUrl = data['link']?.toString() ??
            data['payment_url']?.toString() ??
            data['invoice_url']?.toString() ??
            data['payment_response']?['link']?.toString() ??
            data['payment_response']?['invoice_url']?.toString() ??
            data['payment_response']?['url']?.toString() ??
            '';
      }

      if (paymentUrl.isEmpty) {
        return {'success': false, 'error': 'Payment URL not found'};
      }

      if (addMoneyToWallet) {
        return {
          'success': true,
          'message': 'Payment completed successfully',
          'payment_id': paymentUrl,
          'signature': paymentUrl,
          'order_id': paymentUrl,
        };
      }

      // Launch WebView Payment for checkout flow (rider tips, etc. where order exists)
      if (!context.mounted) {
        return {'success': false, 'error': 'Context not mounted'};
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewPaymentPage(
            paymentUrl: paymentUrl,
            orderSlug: additionalData?['orderSlug']?.toString() ?? '',
            isTipPayment: true,
            onPaymentSuccess: () {},
            onPaymentFailure: () {},
          ),
        ),
      );

      if (result != null && result is Map && result['success'] == true) {
        return {
          'success': true,
          'message': 'Payment completed successfully',
          'payment_id': result['payment_id'] ?? result['reference'] ?? 'XENDIT_REF',
          'signature': result['signature'] ?? result['reference'] ?? 'XENDIT_REF',
          'order_id': result['order_id'] ?? result['reference'] ?? 'XENDIT_REF',
        };
      } else {
        return {
          'success': false,
          'error': 'Payment cancelled or failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Payment failed: ${e.toString()}'};
    }
  }

  /// Initiates Mercado Pago payment for wallet recharge or order checkout.
  Future<Map<String, dynamic>> _initiateMercadoPagoPayment({
    required BuildContext context,
    required double amount,
    Map<String, dynamic>? additionalData,
    required bool addMoneyToWallet,
  }) async {
    try {
      dynamic response;

      if (addMoneyToWallet) {
        response = await AppHelpers.apiBaseHelper.postAPICall(
            ApiRoutes.prepareWalletRechargeApi, {
          "amount": amount.toInt(),
          "payment_method": 'mercadoPagoPayment',
          "description": ''
        });
      } else {
        final rawOrderId = additionalData?['orderId'] ?? additionalData?['order_id'] ?? 0;
        final int orderId = rawOrderId is int ? rawOrderId : (int.tryParse(rawOrderId.toString()) ?? 0);
        if (orderId != 0) {
          response = await AppHelpers.apiBaseHelper.postAPICall(
            '${AppConstant.baseUrl}mercadopago/post-tip',
            {
              "order_id": orderId,
              "rider_tip_amount": amount.toInt(),
            },
          );
        } else {
          return {'success': false, 'error': 'Order checkout uses the order-first flow'};
        }
      }

      if (response.data['success'] != true) {
        return {
          'success': false,
          'error': response.data['data']?['error'] ??
              response.data['message'] ??
              'Payment failed'
        };
      }

      final data = response.data['data'] ?? {};

      if (data.isEmpty) {
        return {'success': false, 'error': 'Invalid payment response'};
      }

      String paymentUrl = '';
      if (data is String) {
        paymentUrl = data;
      } else if (data is Map) {
        final pr = data['payment_response'];
        if (pr is Map) {
          paymentUrl = (pr['init_point'] ??
                  pr['sandbox_init_point'] ??
                  pr['link'] ??
                  pr['checkout_url'] ??
                  pr['url'] ??
                  pr['invoice_url'])
              ?.toString() ??
              '';
        }
        if (paymentUrl.isEmpty) {
          paymentUrl = (data['init_point'] ??
                  data['sandbox_init_point'] ??
                  data['link'] ??
                  data['checkout_url'] ??
                  data['url'] ??
                  data['payment_url'] ??
                  data['invoice_url'])
              ?.toString() ??
              '';
        }
      }

      if (paymentUrl.isEmpty) {
        return {'success': false, 'error': 'Payment URL not found'};
      }

      if (addMoneyToWallet) {
        return {
          'success': true,
          'message': 'Payment completed successfully',
          'payment_id': paymentUrl,
          'signature': paymentUrl,
          'order_id': paymentUrl,
        };
      }

      if (!context.mounted) {
        return {'success': false, 'error': 'Context not mounted'};
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewPaymentPage(
            paymentUrl: paymentUrl,
            orderSlug: additionalData?['orderSlug']?.toString() ?? '',
            isTipPayment: true,
            onPaymentSuccess: () {},
            onPaymentFailure: () {},
          ),
        ),
      );

      if (result != null && result is Map && result['success'] == true) {
        return {
          'success': true,
          'message': 'Payment completed successfully',
          'payment_id': result['payment_id'] ?? result['reference'] ?? 'MERCADOPAGO_REF',
          'signature': result['signature'] ?? result['reference'] ?? 'MERCADOPAGO_REF',
          'order_id': result['order_id'] ?? result['reference'] ?? 'MERCADOPAGO_REF',
        };
      } else {
        return {
          'success': false,
          'error': 'Payment cancelled or failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Payment failed: ${e.toString()}'};
    }
  }

  Future<dynamic> checkPaymentTransactionStatus(String uuid) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.paymentTransactionStatusApi(uuid),
        {},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      log('Error checking payment transaction status: $e');
      return null;
    }
  }
}

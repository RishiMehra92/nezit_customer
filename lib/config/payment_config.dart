import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'settings_data_instance.dart';

/// Enum for payment method types
enum PaymentMethodType {
  razorpay,
  stripe,
  paystack,
  phonepe,
  paypal,
  flutterwave,
  mercadoPago,
  xendit,
  wallet,
  cod,
}

/// Model class for payment method configuration
class PaymentMethod {
  final PaymentMethodType type;
  final String id;
  final String name;
  final String? logoPath;
  final IconData? icon;
  final Color? color;
  final bool isOnline;
  final bool isAvailable;

  const PaymentMethod({
    required this.type,
    required this.id,
    required this.name,
    this.logoPath,
    this.icon,
    this.color,
    required this.isOnline,
    this.isAvailable = true,
  });

  /// Get the display logo/icon widget
  Widget getDisplayWidget({double size = 24.0}) {
    if (logoPath != null) {
      return CustomImageContainer(
        imagePath: logoPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else if (icon != null) {
      return Icon(
        icon!,
        size: size,
        color: color ?? Colors.grey,
      );
    } else {
      return Icon(
        Icons.payment,
        size: size,
        color: Colors.grey,
      );
    }
  }
}

/// Centralized payment configuration class
class PaymentConfig {
  static const String _logoBasePath = 'assets/images/payment-logos/';

  /// All available payment methods configuration
  static final List<PaymentMethod> _paymentMethods = [
    // Online Payment Methods
    const PaymentMethod(
      type: PaymentMethodType.razorpay,
      id: 'razorpay',
      name: 'Razorpay',
      logoPath: '${_logoBasePath}razorpay.png',
      isOnline: true,
    ),
    const PaymentMethod(
      type: PaymentMethodType.stripe,
      id: 'stripe',
      name: 'Stripe',
      logoPath: '${_logoBasePath}stripe.png',
      isOnline: true,
    ),
    const PaymentMethod(
      type: PaymentMethodType.paystack,
      id: 'paystack',
      name: 'Paystack',
      logoPath: '${_logoBasePath}paystack.png',
      isOnline: true,
    ),
    const PaymentMethod(
      type: PaymentMethodType.paypal,
      id: 'paypal',
      name: 'PayPal',
      logoPath: '${_logoBasePath}pay-pal.png',
      isOnline: true,
    ),
    const PaymentMethod(
      type: PaymentMethodType.flutterwave,
      id: 'flutterwave',
      name: 'Flutterwave',
      logoPath: '${_logoBasePath}flutter-wave.png',
      isOnline: true,
    ),
    const PaymentMethod(
      type: PaymentMethodType.mercadoPago,
      id: 'mercadoPago',
      name: 'Mercado Pago',
      logoPath: '${_logoBasePath}margedopedo.png',
      isOnline: true,
    ),
    const PaymentMethod(
      type: PaymentMethodType.xendit,
      id: 'xendit',
      name: 'Xendit',
      logoPath: '${_logoBasePath}xendit.png',
      isOnline: true,
    ),

    const PaymentMethod(
      type: PaymentMethodType.cod,
      id: 'cod',
      name: 'Cash on Delivery',
      logoPath: '${_logoBasePath}cash-on-delivery.png',
      icon: TablerIcons.coins,
      color: Colors.grey,
      isOnline: false,
    ),
  ];

  /// Get all online payment methods
  static List<PaymentMethod> get onlinePaymentMethods {
    return _paymentMethods.where((method) => method.isOnline).toList();
  }

  /// Get all wallet and COD payment methods
  static List<PaymentMethod> get walletAndCODPaymentMethods {
    return _paymentMethods.where((method) => !method.isOnline).toList();
  }

  /// Get all available payment methods
  static List<PaymentMethod> get allPaymentMethods {
    return _paymentMethods.where((method) => method.isAvailable).toList();
  }

  /// Get payment method by ID
  static PaymentMethod? getPaymentMethodById(String id) {
    try {
      return _paymentMethods.firstWhere((method) => method.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get payment method by type
  static PaymentMethod? getPaymentMethodByType(PaymentMethodType type) {
    try {
      return _paymentMethods.firstWhere((method) => method.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Get payment method display name
  static String getPaymentMethodName(String id) {
    final method = getPaymentMethodById(id);
    return method?.name ?? 'Unknown';
  }

  /// Get payment method display widget
  static Widget getPaymentMethodWidget(String id, {double size = 24.0}) {
    final method = getPaymentMethodById(id);
    return method?.getDisplayWidget(size: size) ??
        Icon(Icons.payment, size: size, color: Colors.grey);
  }

  /// Check if a payment method is enabled in settings
  static bool isPaymentMethodEnabledInSettings(String id) {
    final paymentSettings = SettingsData.instance.payment;
    if (paymentSettings == null) {
      return true; // Default to enabled if settings not loaded
    }

    switch (id) {
      case 'stripe':
        return paymentSettings.stripePayment ?? false;
      case 'razorpay':
        return paymentSettings.razorpayPayment ?? false;
      case 'cod':
        return paymentSettings.cod ?? false;
      case 'paystack':
        return paymentSettings.paystackPayment ?? false;
      case 'paypal':
        return false;
      case 'flutterwave':
        return paymentSettings.flutterWavePayment ?? false;
      case 'mercadoPago':
      case 'mercadopago':
      case 'mercado_pago':
        return paymentSettings.mercadoPagoPayment ?? paymentSettings.mercadopagoPayment ?? false;
      case 'xendit':
        return paymentSettings.xenditPayment ?? false;
      default:
        return false;
    }
  }

  /// Get payment methods filtered by settings availability
  static List<PaymentMethod> getEnabledPaymentMethods() {
    return _paymentMethods
        .where((method) => method.isAvailable && isPaymentMethodEnabledInSettings(method.id))
        .toList();
  }

  /// Get payment methods filtered by contextual available_payment_methods if provided,
  /// otherwise fallback to global settings.
  static List<PaymentMethod> getContextualPaymentMethods({
    List<dynamic>? availableMethods,
  }) {
    if (availableMethods != null && availableMethods.isNotEmpty) {
      final validKeys = <String>{};
      for (final m in availableMethods) {
        bool isEnabled = false;
        bool isAvailable = false;
        String key = '';
        String name = '';

        if (m is Map) {
          isEnabled = m['is_enabled'] == true || m['is_enabled'] == 1 || m['is_enabled'] == 'true';
          isAvailable =
              m['is_available'] == true || m['is_available'] == 1 || m['is_available'] == 'true';
          key = m['key']?.toString().toLowerCase().trim() ?? '';
          name = m['name']?.toString().toLowerCase().trim() ?? '';
        } else {
          try {
            isEnabled = m.isEnabled == true;
            isAvailable = m.isAvailable == true;
            key = m.key.toString().toLowerCase().trim();
            name = m.name.toString().toLowerCase().trim();
          } catch (_) {}
        }

        if (isEnabled && isAvailable) {
          if (key.isNotEmpty) {
            validKeys.add(key);
            validKeys.add(key.replaceAll('payment', '').replaceAll('_payment', '').trim());
          }
          if (name.isNotEmpty) {
            validKeys.add(name);
            validKeys.add(name.replaceAll('payment', '').replaceAll('_payment', '').trim());
          }
        }
      }

      return _paymentMethods
          .where((method) =>
              validKeys.contains(method.id.toLowerCase().trim()) &&
              isPaymentMethodEnabledInSettings(method.id))
          .toList();
    }
    return getEnabledPaymentMethods();
  }
}

import 'dart:convert';

import 'package:hyper_local/config/helper.dart';

/// Base model for individual settings items from the API response.
class SettingsApiModel {
  final String variable;
  final dynamic value; // Will be parsed to specific models in SettingsData

  SettingsApiModel({
    required this.variable,
    required this.value,
  });

  factory SettingsApiModel.fromJson(Map<String, dynamic> json) {
    return SettingsApiModel(
      variable: json['variable'] as String,
      value: json['value'], // Keep as dynamic Map for now; parsed later
    );
  }
}

/// Model for the entire API response.
class SettingsResponse {
  final bool success;
  final String message;
  final List<SettingsApiModel> data;

  SettingsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SettingsResponse.fromJson(Map<String, dynamic> json) {
    return SettingsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map(
              (item) => SettingsApiModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convenience method to parse from a JSON string.
  static SettingsResponse fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return SettingsResponse.fromJson(json);
  }
}

/// Specific model for 'system' settings.
class SystemSettings {
  final String? appName;
  final String? sellerSupportNumber;
  final String? sellerSupportEmail;
  final String? systemTimezone;
  final String? copyrightDetails;
  final String? logo;
  final String? favicon;
  final bool? enableThirdPartyStoreSync;
  final bool? shopify;
  final bool? woocommerce;
  final bool? etsy;
  final String? systemVendorType;
  final String? layoutType;
  final String? checkoutType;
  final int? minimumCartAmount;
  final int? maximumItemsAllowedInCart;
  final String? lowStockLimit;
  final String? maximumDistanceToNearestStore;
  final bool? enableWallet;
  final int? welcomeWalletBalanceAmount;
  final bool? sellerAppMaintenanceMode;
  final String? sellerAppMaintenanceMessage;
  final bool? webMaintenanceMode;
  final String? webMaintenanceMessage;
  final bool? demoMode;
  final String? adminDemoModeMessage;
  final String? sellerDemoModeMessage;
  final String? customerDemoModeMessage;
  final String? customerLocationDemoModeMessage;
  final String? deliveryBoyDemoModeMessage;
  final bool? referEarnStatus;
  final String? referEarnMethodUser;
  final String? referEarnBonusUser;
  final String? referEarnMaximumBonusAmountUser;
  final String? referEarnMethodReferral;
  final String? referEarnBonusReferral;
  final String? referEarnMaximumBonusAmountReferral;
  final String? referEarnMinimumOrderAmount;
  final String? referEarnNumberOfTimesBonus;
  final String? currency;
  final String? currencySymbol;
  final String? countryCode;
  final List<String>? notificationTypes;
  final List<String>? dataFilterEnum;
  final List<String>? orderStatusEnum;

  SystemSettings(
      {required this.appName,
      required this.sellerSupportNumber,
      required this.sellerSupportEmail,
      required this.systemTimezone,
      required this.copyrightDetails,
      required this.logo,
      required this.favicon,
      required this.enableThirdPartyStoreSync,
      required this.shopify,
      required this.woocommerce,
      required this.etsy,
      required this.systemVendorType,
      required this.layoutType,
      required this.checkoutType,
      required this.minimumCartAmount,
      required this.maximumItemsAllowedInCart,
      required this.lowStockLimit,
      required this.maximumDistanceToNearestStore,
      required this.enableWallet,
      required this.welcomeWalletBalanceAmount,
      required this.sellerAppMaintenanceMode,
      required this.sellerAppMaintenanceMessage,
      required this.webMaintenanceMode,
      required this.webMaintenanceMessage,
      required this.demoMode,
      required this.adminDemoModeMessage,
      required this.sellerDemoModeMessage,
      required this.customerDemoModeMessage,
      required this.customerLocationDemoModeMessage,
      required this.deliveryBoyDemoModeMessage,
      required this.referEarnStatus,
      required this.referEarnMethodUser,
      required this.referEarnBonusUser,
      required this.referEarnMaximumBonusAmountUser,
      required this.referEarnMethodReferral,
      required this.referEarnBonusReferral,
      required this.referEarnMaximumBonusAmountReferral,
      required this.referEarnMinimumOrderAmount,
      required this.referEarnNumberOfTimesBonus,
      required this.currency,
      required this.currencySymbol,
      required this.countryCode,
      required this.notificationTypes,
      required this.dataFilterEnum,
      required this.orderStatusEnum});

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
        appName: parseString(json['appName']),
        sellerSupportNumber: parseString(json['sellerSupportNumber']),
        sellerSupportEmail: parseString(json['sellerSupportEmail']),
        systemTimezone: parseString(json['systemTimezone']),
        copyrightDetails: parseString(json['copyrightDetails']),
        logo: parseString(json['logo']),
        favicon: parseString(json['favicon']),
        enableThirdPartyStoreSync: parseBool(json['enableThirdPartyStoreSync']),
        shopify: parseBool(json['Shopify']),
        woocommerce: parseBool(json['Woocommerce']),
        etsy: parseBool(json['etsy']),
        systemVendorType: parseString(json['systemVendorType']),
        layoutType: parseString(json['layoutType']),
        checkoutType: parseString(json['checkoutType']),
        minimumCartAmount: parseInt(json['minimumCartAmount']),
        maximumItemsAllowedInCart: parseInt(json['maximumItemsAllowedInCart']),
        lowStockLimit: parseString(json['lowStockLimit']),
        maximumDistanceToNearestStore:
            parseString(json['maximumDistanceToNearestStore']),
        enableWallet: parseBool(json['enableWallet']),
        welcomeWalletBalanceAmount:
            parseInt(json['welcomeWalletBalanceAmount']),
        sellerAppMaintenanceMode: parseBool(json['sellerAppMaintenanceMode']),
        sellerAppMaintenanceMessage:
            parseString(json['sellerAppMaintenanceMessage']),
        webMaintenanceMode: parseBool(json['webMaintenanceMode']),
        webMaintenanceMessage: parseString(json['webMaintenanceMessage']),
        demoMode: parseBool(json['demoMode']),
        adminDemoModeMessage: parseString(json['adminDemoModeMessage']),
        sellerDemoModeMessage: parseString(json['sellerDemoModeMessage']),
        customerDemoModeMessage: parseString(json['customerDemoModeMessage']),
        customerLocationDemoModeMessage:
            parseString(json['customerLocationDemoModeMessage']),
        deliveryBoyDemoModeMessage:
            parseString(json['deliveryBoyDemoModeMessage']),
        referEarnStatus: parseBool(json['referEarnStatus']),
        referEarnMethodUser: parseString(json['referEarnMethodUser']),
        referEarnBonusUser: parseString(json['referEarnBonusUser']),
        referEarnMaximumBonusAmountUser:
            parseString(json['referEarnMaximumBonusAmountUser']),
        referEarnMethodReferral: parseString(json['referEarnMethodReferral']),
        referEarnBonusReferral: parseString(json['referEarnBonusReferral']),
        referEarnMaximumBonusAmountReferral:
            parseString(json['referEarnMaximumBonusAmountReferral']),
        referEarnMinimumOrderAmount:
            parseString(json['referEarnMinimumOrderAmount']),
        referEarnNumberOfTimesBonus:
            parseString(json['referEarnNumberOfTimesBonus']),
        currency: parseString(json['currency']),
        currencySymbol: parseString(json['currencySymbol']),
        countryCode: parseString(json['countryCode']),
        notificationTypes:
            (json['notificationType'] as List<dynamic>).cast<String>(),
        dataFilterEnum:
            (json['dataFilterEnum'] as List<dynamic>).cast<String>(),
        orderStatusEnum:
            (json['orderStatusEnum'] as List<dynamic>).cast<String>());
  }
}

/// Specific model for 'storage' settings.
class StorageSettings {
  final String? awsRegion;
  final String? awsBucket;
  final String? awsAssetUrl;

  StorageSettings({
    required this.awsRegion,
    required this.awsBucket,
    required this.awsAssetUrl,
  });

  factory StorageSettings.fromJson(Map<String, dynamic> json) {
    return StorageSettings(
      awsRegion: parseString(json['awsRegion']),
      awsBucket: parseString(json['awsBucket']),
      awsAssetUrl: parseString(json['awsAssetUrl']),
    );
  }
}

/// Specific model for 'email' settings.
class EmailSettings {
  final String? smtpHost;
  final String? smtpPort;
  final String? smtpEmail;
  final String? smtpEncryption;
  final String? smtpContentType;

  EmailSettings({
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpEmail,
    required this.smtpEncryption,
    required this.smtpContentType,
  });

  factory EmailSettings.fromJson(Map<String, dynamic> json) {
    return EmailSettings(
      smtpHost: parseString(json['smtpHost']),
      smtpPort: parseString(json['smtpPort']),
      smtpEmail: parseString(json['smtpEmail']),
      smtpEncryption: parseString(json['smtpEncryption']),
      smtpContentType: parseString(json['smtpContentType']),
    );
  }
}

/// Specific model for 'payment' settings.
class PaymentSettings {
  final bool? stripePayment;
  final String? stripePaymentMode;
  final String? stripePublishableKey;
  final String? stripeCurrencyCode;
  final bool? razorpayPayment;
  final String? razorpayPaymentMode;
  final String? razorpayKeyId;
  final bool? paystackPayment;
  final String? paystackPaymentMode;
  final String? paystackPublicKey;
  final bool? wallet;
  final bool? cod;
  final bool? directBankTransfer;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankCode;
  final String? bankExtraNote;
  final bool? flutterWavePayment;
  final String? flutterWavePaymentMode;
  final String? flutterWavePublicKey;
  final String? flutterWaveCurrencyCode;
  final bool? xenditPayment;
  final String? xenditPaymentMode;
  final String? xenditCurrencyCode;
  final bool? mercadoPagoPayment;
  final String? mercadoPagoPaymentMode;
  final String? mercadoPagoPublicKey;
  final String? mercadoPagoCurrencyCode;
  final String? mercadoPagoAccessToken;
  final List<String>? walletOptionalNotes;
  final String? optionalNote;

  bool? get mercadopagoPayment => mercadoPagoPayment;
  String? get mercadopagoPaymentMode => mercadoPagoPaymentMode;
  String? get mercadopagoPublicKey => mercadoPagoPublicKey;
  String? get mercadopagoCurrencyCode => mercadoPagoCurrencyCode;
  String? get mercadopagoAccessToken => mercadoPagoAccessToken;

  PaymentSettings({
    required this.stripePayment,
    required this.stripePaymentMode,
    required this.stripePublishableKey,
    required this.stripeCurrencyCode,
    required this.razorpayPayment,
    required this.razorpayPaymentMode,
    required this.razorpayKeyId,
    required this.paystackPayment,
    required this.paystackPaymentMode,
    required this.paystackPublicKey,
    required this.wallet,
    required this.cod,
    required this.directBankTransfer,
    required this.bankAccountName,
    required this.bankAccountNumber,
    required this.bankName,
    required this.bankCode,
    required this.bankExtraNote,
    required this.flutterWavePayment,
    required this.flutterWavePaymentMode,
    required this.flutterWavePublicKey,
    required this.flutterWaveCurrencyCode,
    this.xenditPayment,
    this.xenditPaymentMode,
    this.xenditCurrencyCode,
    this.mercadoPagoPayment,
    this.mercadoPagoPaymentMode,
    this.mercadoPagoPublicKey,
    this.mercadoPagoCurrencyCode,
    this.mercadoPagoAccessToken,
    this.walletOptionalNotes,
    this.optionalNote,
  });

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    return PaymentSettings(
      stripePayment: parseBool(json['stripePayment']),
      stripePaymentMode: parseString(json['stripePaymentMode']),
      stripePublishableKey: parseString(json['stripePublishableKey']),
      stripeCurrencyCode: parseString(json['stripeCurrencyCode']),
      razorpayPayment: parseBool(json['razorpayPayment']),
      razorpayPaymentMode: parseString(json['razorpayPaymentMode']),
      razorpayKeyId: parseString(json['razorpayKeyId']),
      paystackPayment: parseBool(json['paystackPayment']),
      paystackPaymentMode: parseString(json['paystackPaymentMode']),
      paystackPublicKey: parseString(json['paystackPublicKey']),
      wallet: parseBool(json['wallet']),
      cod: parseBool(json['cod']),
      directBankTransfer: parseBool(json['directBankTransfer']),
      bankAccountName: parseString(json['bankAccountName']),
      bankAccountNumber: parseString(json['bankAccountNumber']),
      bankName: parseString(json['bankName']),
      bankCode: parseString(json['bankCode']),
      bankExtraNote: parseString(json['bankExtraNote']),
      flutterWavePayment: parseBool(json['flutterwavePayment']),
      flutterWavePaymentMode: parseString(json['flutterwavePaymentMode']),
      flutterWavePublicKey: parseString(json['flutterwavePublicKey']),
      flutterWaveCurrencyCode: parseString(json['flutterwaveCurrencyCode']),
      xenditPayment: parseBool(json['xenditPayment']),
      xenditPaymentMode: parseString(json['xenditPaymentMode']),
      xenditCurrencyCode: parseString(json['xenditCurrencyCode']),
      mercadoPagoPayment: parseBool(json['mercadoPagoPayment'] ?? json['mercadopagoPayment'] ?? json['mercado_pago_payment'] ?? json['mercadopago_payment']),
      mercadoPagoPaymentMode: parseString(json['mercadoPagoPaymentMode'] ?? json['mercadopagoPaymentMode'] ?? json['mercado_pago_payment_mode'] ?? json['mercadopago_payment_mode']),
      mercadoPagoPublicKey: parseString(json['mercadoPagoPublicKey'] ?? json['mercadopagoPublicKey'] ?? json['mercado_pago_public_key'] ?? json['mercadopago_public_key']),
      mercadoPagoCurrencyCode: parseString(json['mercadoPagoCurrencyCode'] ?? json['mercadopagoCurrencyCode'] ?? json['mercado_pago_currency_code'] ?? json['mercadopago_currency_code']),
      mercadoPagoAccessToken: parseString(json['mercadoPagoAccessToken'] ?? json['mercadopagoAccessToken'] ?? json['mercado_pago_access_token'] ?? json['mercadopago_access_token']),
      walletOptionalNotes: json['walletOptionalNotes'] != null
          ? (json['walletOptionalNotes'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      optionalNote: parseString(json['optional_note']),
    );
  }
}

/// Specific model for 'authentication' settings.
class AuthenticationSettings {
  final bool customSms;
  final String customSmsUrl;
  final String customSmsMethod;
  final String googleRecaptchaSiteKey;
  final bool firebase;
  final String fireBaseApiKey;
  final String fireBaseAuthDomain;
  final String fireBaseDatabaseURL;
  final String fireBaseProjectId;
  final String fireBaseStorageBucket;
  final String fireBaseMessagingSenderId;
  final String fireBaseAppId;
  final String fireBaseMeasurementId;
  final bool googleLogin;
  final String smsGateway;

  AuthenticationSettings(
      {required this.customSms,
      required this.customSmsUrl,
      required this.customSmsMethod,
      required this.googleRecaptchaSiteKey,
      required this.firebase,
      required this.fireBaseApiKey,
      required this.fireBaseAuthDomain,
      required this.fireBaseDatabaseURL,
      required this.fireBaseProjectId,
      required this.fireBaseStorageBucket,
      required this.fireBaseMessagingSenderId,
      required this.fireBaseAppId,
      required this.fireBaseMeasurementId,
      required this.googleLogin,
      required this.smsGateway});

  factory AuthenticationSettings.fromJson(Map<String, dynamic> json) {
    return AuthenticationSettings(
      customSms: parseBool(json['customSms']) as bool,
      customSmsUrl: json['customSmsUrl'] as String,
      customSmsMethod: json['customSmsMethod'] as String,
      googleRecaptchaSiteKey: json['googleRecaptchaSiteKey'] as String,
      firebase: json['firebase'] as bool,
      fireBaseApiKey: json['fireBaseApiKey'] as String,
      fireBaseAuthDomain: json['fireBaseAuthDomain'] as String,
      fireBaseDatabaseURL: json['fireBaseDatabaseURL'] as String,
      fireBaseProjectId: json['fireBaseProjectId'] as String,
      fireBaseStorageBucket: json['fireBaseStorageBucket'] as String,
      fireBaseMessagingSenderId: json['fireBaseMessagingSenderId'] as String,
      fireBaseAppId: json['fireBaseAppId'] as String,
      fireBaseMeasurementId: json['fireBaseMeasurementId'] as String,
      googleLogin: json['googleLogin'] as bool,
      smsGateway: json['smsGateway'] as String,
    );
  }
}

/// Specific model for 'notification' settings.
class NotificationSettings {
  final String firebaseProjectId;
  final String vapIdKey;
  final int notificationUnreadCount;

  NotificationSettings(
      {required this.firebaseProjectId,
      required this.vapIdKey,
      required this.notificationUnreadCount});

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      firebaseProjectId: json['firebaseProjectId'] as String,
      vapIdKey: json['vapIdKey'] as String,
      notificationUnreadCount: json['notification_unread_count'] as int,
    );
  }
}

/// Specific model for 'web' settings.
class WebSettings {
  final String siteName;
  final String customerWebUrl;
  final String siteCopyright;
  final String supportNumber;
  final String supportEmail;
  final String address;
  final String shortDescription;
  final String siteHeaderLogo;
  final String siteFooterLogo;
  final String siteFavicon;
  final String headerScript;
  final String footerScript;
  final String googleMapKey;
  final String mapIframe;
  final bool appDownloadSection;
  final String appSectionTitle;
  final String appSectionTagline;
  final String appSectionPlaystoreLink;
  final String appSectionAppstoreLink;
  final String appSectionShortDescription;
  final String facebookLink;
  final String instagramLink;
  final String xLink;
  final String youtubeLink;
  final String shippingFeatureSection;
  final String shippingFeatureSectionTitle;
  final String shippingFeatureSectionDescription;
  final String returnFeatureSection;
  final String returnFeatureSectionTitle;
  final String returnFeatureSectionDescription;
  final String safetySecurityFeatureSection;
  final String safetySecurityFeatureSectionTitle;
  final String safetySecurityFeatureSectionDescription;
  final String supportFeatureSection;
  final String supportFeatureSectionTitle;
  final String supportFeatureSectionDescription;
  final String metaKeywords;
  final String metaDescription;
  final String defaultLatitude;
  final String defaultLongitude;
  final bool enableCountryValidation;
  final List<String> allowedCountries;
  final String returnRefundPolicy;
  final String shippingPolicy;
  final String privacyPolicy;
  final String termsCondition;
  final String aboutUs;

  WebSettings({
    required this.siteName,
    required this.customerWebUrl,
    required this.siteCopyright,
    required this.supportNumber,
    required this.supportEmail,
    required this.address,
    required this.shortDescription,
    required this.siteHeaderLogo,
    required this.siteFooterLogo,
    required this.siteFavicon,
    required this.headerScript,
    required this.footerScript,
    required this.googleMapKey,
    required this.mapIframe,
    required this.appDownloadSection,
    required this.appSectionTitle,
    required this.appSectionTagline,
    required this.appSectionPlaystoreLink,
    required this.appSectionAppstoreLink,
    required this.appSectionShortDescription,
    required this.facebookLink,
    required this.instagramLink,
    required this.xLink,
    required this.youtubeLink,
    required this.shippingFeatureSection,
    required this.shippingFeatureSectionTitle,
    required this.shippingFeatureSectionDescription,
    required this.returnFeatureSection,
    required this.returnFeatureSectionTitle,
    required this.returnFeatureSectionDescription,
    required this.safetySecurityFeatureSection,
    required this.safetySecurityFeatureSectionTitle,
    required this.safetySecurityFeatureSectionDescription,
    required this.supportFeatureSection,
    required this.supportFeatureSectionTitle,
    required this.supportFeatureSectionDescription,
    required this.metaKeywords,
    required this.metaDescription,
    required this.defaultLatitude,
    required this.defaultLongitude,
    required this.enableCountryValidation,
    required this.allowedCountries,
    required this.returnRefundPolicy,
    required this.shippingPolicy,
    required this.privacyPolicy,
    required this.termsCondition,
    required this.aboutUs,
  });

  factory WebSettings.fromJson(Map<String, dynamic> json) {
    return WebSettings(
      siteName: json['siteName'] as String,
      customerWebUrl: json['customerWebUrl'] as String,
      siteCopyright: json['siteCopyright'] as String,
      supportNumber: json['supportNumber'] as String,
      supportEmail: json['supportEmail'] as String,
      address: json['address'] as String,
      shortDescription: json['shortDescription'] as String,
      siteHeaderLogo: json['siteHeaderLogo'] as String,
      siteFooterLogo: json['siteFooterLogo'] as String,
      siteFavicon: json['siteFavicon'] as String,
      headerScript: json['headerScript'] as String,
      footerScript: json['footerScript'] as String,
      googleMapKey: json['googleMapKey'] as String,
      mapIframe: json['mapIframe'] as String,
      appDownloadSection: json['appDownloadSection'] as bool,
      appSectionTitle: json['appSectionTitle'] as String,
      appSectionTagline: json['appSectionTagline'] as String,
      appSectionPlaystoreLink: json['appSectionPlaystoreLink'] as String,
      appSectionAppstoreLink: json['appSectionAppstoreLink'] as String,
      appSectionShortDescription: json['appSectionShortDescription'] as String,
      facebookLink: json['facebookLink'] as String,
      instagramLink: json['instagramLink'] as String,
      xLink: json['xLink'] as String,
      youtubeLink: json['youtubeLink'] as String,
      shippingFeatureSection: json['shippingFeatureSection'] as String,
      shippingFeatureSectionTitle:
          json['shippingFeatureSectionTitle'] as String,
      shippingFeatureSectionDescription:
          json['shippingFeatureSectionDescription'] as String,
      returnFeatureSection: json['returnFeatureSection'] as String,
      returnFeatureSectionTitle: json['returnFeatureSectionTitle'] as String,
      returnFeatureSectionDescription:
          json['returnFeatureSectionDescription'] as String,
      safetySecurityFeatureSection:
          json['safetySecurityFeatureSection'] as String,
      safetySecurityFeatureSectionTitle:
          json['safetySecurityFeatureSectionTitle'] as String,
      safetySecurityFeatureSectionDescription:
          json['safetySecurityFeatureSectionDescription'] as String,
      supportFeatureSection: json['supportFeatureSection'] as String,
      supportFeatureSectionTitle: json['supportFeatureSectionTitle'] as String,
      supportFeatureSectionDescription:
          json['supportFeatureSectionDescription'] as String,
      metaKeywords: json['metaKeywords'] as String,
      metaDescription: json['metaDescription'] as String,
      defaultLatitude: json['defaultLatitude'] as String,
      defaultLongitude: json['defaultLongitude'] as String,
      enableCountryValidation: json['enableCountryValidation'] as bool,
      allowedCountries:
          (json['allowedCountries'] as List<dynamic>).cast<String>(),
      returnRefundPolicy: json['returnRefundPolicy'] as String,
      shippingPolicy: json['shippingPolicy'] as String,
      privacyPolicy: json['privacyPolicy'] as String,
      termsCondition: json['termsCondition'] as String,
      aboutUs: json['aboutUs'] as String,
    );
  }
}

/// Specific model for 'app' settings.
class AppSettings {
  final String appstoreLink;
  final String playstoreLink;
  final String appScheme;
  final bool? customerViewDeliveryZoneInfo;

  AppSettings({
    required this.appstoreLink,
    required this.playstoreLink,
    required this.appScheme,
    this.customerViewDeliveryZoneInfo,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      appstoreLink: parseString(json['customerAppstoreLink']) ?? '',
      playstoreLink: parseString(json['customerPlaystoreLink']) ?? '',
      appScheme: parseString(json['customerAppScheme']) ?? '',
      customerViewDeliveryZoneInfo: parseBool(json['customerViewDeliveryZoneInfo']),
    );
  }
}

class DeliveryBoySettings {
  final String termsCondition;
  final String privacyPolicy;
  final bool? deliveryBoyReferEarnStatus;
  final String? deliveryBoyReferEarnBonusReferral;
  final String? deliveryBoyReferEarnBonusReferee;
  final bool? cashCollectionLimitStatus;
  final String? cashCollectionLimitAmount;
  final bool? enableRiderTips;
  final int? minTipAmount;
  final int? preset1;
  final int? preset2;
  final int? preset3;
  final int? maxTipAmount;

  DeliveryBoySettings({
    required this.termsCondition,
    required this.privacyPolicy,
    this.deliveryBoyReferEarnStatus,
    this.deliveryBoyReferEarnBonusReferral,
    this.deliveryBoyReferEarnBonusReferee,
    this.cashCollectionLimitStatus,
    this.cashCollectionLimitAmount,
    this.enableRiderTips,
    this.minTipAmount,
    this.preset1,
    this.preset2,
    this.preset3,
    this.maxTipAmount,
  });

  factory DeliveryBoySettings.fromJson(Map<String, dynamic> json) {
    return DeliveryBoySettings(
      termsCondition: json['termsCondition'] as String,
      privacyPolicy: json['privacyPolicy'] as String,
      deliveryBoyReferEarnStatus: parseBool(json['deliveryBoyReferEarnStatus']),
      deliveryBoyReferEarnBonusReferral:
          parseString(json['deliveryBoyReferEarnBonusReferral']),
      deliveryBoyReferEarnBonusReferee:
          parseString(json['deliveryBoyReferEarnBonusReferee']),
      cashCollectionLimitStatus: parseBool(json['cashCollectionLimitStatus']),
      cashCollectionLimitAmount: parseString(json['cashCollectionLimitAmount']),
      enableRiderTips: parseBool(json['enableRiderTips']),
      minTipAmount: parseInt(json['minTipAmount']),
      preset1: parseInt(json['preset1']),
      preset2: parseInt(json['preset2']),
      preset3: parseInt(json['preset3']),
      maxTipAmount: parseInt(json['maxTipAmount']),
    );
  }
}

/// Specific model for 'home_general_settings' settings.
class HomeGeneralSettings {
  final String title;
  final List<String>? searchLabels;
  final String backgroundType;
  final String backgroundColor;
  final String backgroundImage;
  final String? backgroundAnimation;
  final String icon;
  final String activeIcon;
  final String fontColor;

  HomeGeneralSettings({
    required this.title,
    required this.searchLabels,
    required this.backgroundType,
    required this.backgroundColor,
    required this.backgroundImage,
    this.backgroundAnimation,
    required this.icon,
    required this.activeIcon,
    required this.fontColor,
  });

  factory HomeGeneralSettings.fromJson(Map<String, dynamic> json) {
    final bgColApp = parseString(json['backgroundColorApp']);
    final bgImgApp = parseString(json['backgroundImageApp']);
    final bgAnimApp = parseString(json['backgroundAnimationApp']);
    return HomeGeneralSettings(
      title: parseString(json['title']) ?? '',
      searchLabels: json['searchLabels'] != null ? (json['searchLabels'] as List).cast<String>() : null,
      backgroundType: parseString(json['backgroundType']) ?? '',
      backgroundColor: (bgColApp != null && bgColApp.isNotEmpty) ? bgColApp : (parseString(json['backgroundColor']) ?? ''),
      backgroundImage: (bgImgApp != null && bgImgApp.isNotEmpty) ? bgImgApp : (parseString(json['backgroundImage']) ?? ''),
      backgroundAnimation: (bgAnimApp != null && bgAnimApp.isNotEmpty) ? bgAnimApp : parseString(json['backgroundAnimation']),
      icon: parseString(json['icon']) ?? '',
      activeIcon: parseString(json['activeIcon']) ?? '',
      fontColor: parseString(json['fontColor']) ?? '',
    );
  }
}

class AdvertisementSettings {
  final bool? featureEnabled;
  final String? disableBehavior;
  final double? cpcRate;
  final int? walletMinTopup;
  final int? searchSlotCount;
  final int? relatedSlotCount;
  final int? impressionMultiplierMin;
  final int? impressionMultiplierMax;
  final int? adImpressionVisibilityPct;
  final int? adImpressionVisibilityMs;
  final String? broadcastDriver;
  final String? pusherAppId;
  final String? pusherKey;
  final String? pusherSecret;
  final String? pusherCluster;
  final String? reverbAppId;
  final String? reverbKey;
  final String? reverbSecret;
  final String? reverbHost;
  final int? reverbPort;
  final String? reverbScheme;

  AdvertisementSettings({
    required this.featureEnabled,
    required this.disableBehavior,
    required this.cpcRate,
    required this.walletMinTopup,
    required this.searchSlotCount,
    required this.relatedSlotCount,
    required this.impressionMultiplierMin,
    required this.impressionMultiplierMax,
    required this.adImpressionVisibilityPct,
    required this.adImpressionVisibilityMs,
    required this.broadcastDriver,
    required this.pusherAppId,
    required this.pusherKey,
    required this.pusherSecret,
    required this.pusherCluster,
    required this.reverbAppId,
    required this.reverbKey,
    required this.reverbSecret,
    required this.reverbHost,
    required this.reverbPort,
    required this.reverbScheme,
  });

  factory AdvertisementSettings.fromJson(Map<String, dynamic> json) {
    return AdvertisementSettings(
      featureEnabled: parseBool(json['featureEnabled']),
      disableBehavior: parseString(json['disableBehavior']),
      cpcRate: parseDouble(json['cpcRate']),
      walletMinTopup: parseInt(json['walletMinTopup']),
      searchSlotCount: parseInt(json['searchSlotCount']),
      relatedSlotCount: parseInt(json['relatedSlotCount']),
      impressionMultiplierMin: parseInt(json['impressionMultiplierMin']),
      impressionMultiplierMax: parseInt(json['impressionMultiplierMax']),
      adImpressionVisibilityPct: parseInt(json['adImpressionVisibilityPct']),
      adImpressionVisibilityMs: parseInt(json['adImpressionVisibilityMs']),
      broadcastDriver: parseString(json['broadcastDriver']),
      pusherAppId: parseString(json['pusherAppId']),
      pusherKey: parseString(json['pusherKey']),
      pusherSecret: parseString(json['pusherSecret']),
      pusherCluster: parseString(json['pusherCluster']),
      reverbAppId: parseString(json['reverbAppId']),
      reverbKey: parseString(json['reverbKey']),
      reverbSecret: parseString(json['reverbSecret']),
      reverbHost: parseString(json['reverbHost']),
      reverbPort: parseInt(json['reverbPort']),
      reverbScheme: parseString(json['reverbScheme']),
    );
  }
}

class PickupSettings {
  final bool? enabled;

  PickupSettings({required this.enabled});

  factory PickupSettings.fromJson(Map<String, dynamic> json) {
    return PickupSettings(
      enabled: parseBool(json['enabled']),
    );
  }
}

class WatchAndBuySettings {
  final bool? enabled;
  final String? title;
  final int? maxDurationSeconds;
  final int? maxUploadMb;
  final int? maxProductsPerReel;
  final bool? statusesEnabled;
  final int? maxStatusDurationSeconds;
  final int? maxProductsPerStatus;

  WatchAndBuySettings({
    required this.enabled,
    this.title,
    this.maxDurationSeconds,
    this.maxUploadMb,
    this.maxProductsPerReel,
    this.statusesEnabled,
    this.maxStatusDurationSeconds,
    this.maxProductsPerStatus,
  });

  factory WatchAndBuySettings.fromJson(Map<String, dynamic> json) {
    return WatchAndBuySettings(
      enabled: parseBool(json['enabled']),
      title: parseString(json['title']),
      maxDurationSeconds: parseInt(json['maxDurationSeconds']),
      maxUploadMb: parseInt(json['maxUploadMb']),
      maxProductsPerReel: parseInt(json['maxProductsPerReel']),
      statusesEnabled: parseBool(json['statusesEnabled']),
      maxStatusDurationSeconds: parseInt(json['maxStatusDurationSeconds']),
      maxProductsPerStatus: parseInt(json['maxProductsPerStatus']),
    );
  }
}


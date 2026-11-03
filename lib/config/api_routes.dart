import 'dart:core';

import 'package:hyper_local/config/constant.dart';

class ApiRoutes {
  static String loginApi = '${AppConstant.baseUrl}login';
  static String registerApi = '${AppConstant.baseUrl}register';
  static String verifyUserApi = '${AppConstant.baseUrl}verify-user';
  static String forgotPasswordApi = '${AppConstant.baseUrl}forget-password';
  static String googleAuthApi = '${AppConstant.baseUrl}auth/google/callback';
  static String appleAuthApi = '${AppConstant.baseUrl}auth/apple/callback';
  static String mobileOtpAuthApi = '${AppConstant.baseUrl}auth/phone/callback';
  static String logoutApi = '${AppConstant.baseUrl}logout';
  static String categoryApi = '${AppConstant.baseUrl}categories';
  static String filterCategoryApi = '${AppConstant.baseUrl}categories/sidebar';
  static String filterProductApi = '${AppConstant.baseUrl}products/sidebar-filters';
  static String bannerApi = '${AppConstant.baseUrl}banners';
  static String featureSectionProductApi = '${AppConstant.baseUrl}featured-sections';
  static String subCategoryApi = '${AppConstant.baseUrl}categories';
  static String allTabSubCategoryApi = '${AppConstant.baseUrl}categories/sub-categories';
  static String productDetailApi = '${AppConstant.baseUrl}products/';
  static String brandsApi = '${AppConstant.baseUrl}brands';
  static String filterBrandsApi = '${AppConstant.baseUrl}brands/sidebar';
  static String addToCartApi = '${AppConstant.baseUrl}user/cart/add';
  static String categoryProductApi = '${AppConstant.baseUrl}delivery-zone/products';
  static String storeProductApi = '${AppConstant.baseUrl}delivery-zone/products';
  static String getCartApi = '${AppConstant.baseUrl}user/cart';
  static String get shareCartApi => '${AppConstant.baseUrl}user/cart/share';
  static String sharedCartApi(String code) =>
      '${AppConstant.baseUrl}user/cart/shared/${Uri.encodeComponent(code)}';
  static String importSharedCartApi(String code) => '${sharedCartApi(code)}/import';
  static String removeItemFromCartApi = '${AppConstant.baseUrl}user/cart/item/';
  static String clearCartApi = '${AppConstant.baseUrl}user/cart/clear-cart';
  static String getSimilarProductApi = '${AppConstant.baseUrl}delivery-zone/products';
  static String addAddressApi = '${AppConstant.baseUrl}user/addresses';
  static String getAddressesApi = '${AppConstant.baseUrl}user/addresses';
  static String removeAddressesApi = '${AppConstant.baseUrl}user/addresses/';
  static String updateAddressesApi = '${AppConstant.baseUrl}user/addresses/';
  static String checkDeliveryZoneApi = '${AppConstant.baseUrl}delivery-zone/check';
  static String settingsApi = '${AppConstant.baseUrl}settings';
  static String onboardingScreensApi = '${AppConstant.baseUrl}onboarding-screens';
  static String splashConfigApi = '${AppConstant.baseUrl}splash-config';
  static String xenditPostTipApi = '${AppConstant.baseUrl}xendit/post-tip';
  static String flutterwavePostTipApi = '${AppConstant.baseUrl}flutterwave/post-tip';
  static String createOrderApi = '${AppConstant.baseUrl}user/orders';
  static String getMyOrderApi = '${AppConstant.baseUrl}user/orders';
  static String getUserProfileApi = '${AppConstant.baseUrl}user/profile';
  static String updateUserProfileApi = '${AppConstant.baseUrl}user/profile';
  static String deleteUserApi = '${AppConstant.baseUrl}user/delete-account';
  static String getPromoCodeApi = '${AppConstant.baseUrl}user/promos/available';
  static String validatePromoCodeApi = '${AppConstant.baseUrl}user/promos/validate';
  static String orderDetailApi = '${AppConstant.baseUrl}user/orders/';
  static String paymentTransactionStatusApi(String uuid) => '${AppConstant.baseUrl}user/payment-transactions/$uuid/status';
  static String rescheduleOrderApi(int orderId) => '${AppConstant.baseUrl}user/orders/$orderId/recovery/reschedule';
  static String cancelOrderApi(int orderId) => '${AppConstant.baseUrl}user/orders/$orderId/recovery/cancel';
  static String recoverySlotsApi(int orderId, String date) =>
      '${AppConstant.baseUrl}user/orders/$orderId/recovery/slots?date=$date';
  static String addDeliveryBoyFeedbackApi = '${AppConstant.baseUrl}delivery-boy/feedback';
  static String updateDeliveryBoyFeedbackApi = '${AppConstant.baseUrl}delivery-boy/feedback/';
  static String deleteDeliveryBoyFeedbackApi = '${AppConstant.baseUrl}delivery-boy/feedback/';
  static String razorpayApi = '${AppConstant.baseUrl}razorpay/create-order';
  static String stripeCreatePaymentIntentApi = '${AppConstant.baseUrl}stripe/create-order';
  static String paystackCreateOrderApi = '${AppConstant.baseUrl}paystack/create-order';
  static String prepareWalletRechargeApi = '${AppConstant.baseUrl}user/wallet/prepare-wallet-recharge';
  static String userWalletApi = '${AppConstant.baseUrl}user/wallet';
  static String walletTransactionsApi = '${AppConstant.baseUrl}user/wallet/transactions';
  static String addProductFeedbackApi = '${AppConstant.baseUrl}reviews';
  static String updateProductFeedbackApi = '${AppConstant.baseUrl}reviews/';
  static String deleteProductFeedbackApi = '${AppConstant.baseUrl}reviews/';
  static String addSellerFeedbackApi = '${AppConstant.baseUrl}seller-feedback';
  static String updateSellerFeedbackApi = '${AppConstant.baseUrl}seller-feedback/';
  static String deleteSellerFeedbackApi = '${AppConstant.baseUrl}seller-feedback/';
  static String shoppingListApi = '${AppConstant.baseUrl}products/search-by-keywords';
  static String getWishlistApi = '${AppConstant.baseUrl}user/wishlists';
  static String createWishlistApi = '${AppConstant.baseUrl}user/wishlists/create';
  static String addItemInWishlistApi = '${AppConstant.baseUrl}user/wishlists';
  static String updateWishlistApi = '${AppConstant.baseUrl}user/wishlists/';
  static String deleteWishlistApi = '${AppConstant.baseUrl}user/wishlists/';
  static String removeItemFromWishlistApi = '${AppConstant.baseUrl}user/wishlists/items/';
  static String moveItemToAnotherWishlistApi = '${AppConstant.baseUrl}user/wishlists/items/';
  static String searchApi = '${AppConstant.baseUrl}delivery-zone/products';
  static String wishlistProductApi = '${AppConstant.baseUrl}user/wishlists/';
  static String saveForLaterApi = '${AppConstant.baseUrl}user/cart/item/save-for-later';
  static String saveProductApi = '${AppConstant.baseUrl}user/cart/item/save-for-later/';
  static String specificFeatureSectionProductApi = '${AppConstant.baseUrl}featured-sections/';
  static String nearByStores = '${AppConstant.baseUrl}delivery-zone/stores';
  static String returnOrderItemApi = '${AppConstant.baseUrl}user/orders/items/';
  static String cancelReturnRequestApi = '${AppConstant.baseUrl}user/orders/items/';
  static String cancelOrderItemApi = '${AppConstant.baseUrl}user/orders/items/';
  static String storeDetailApi = '${AppConstant.baseUrl}stores/';
  static String storeNotifyMeApi(dynamic storeId) =>
      '${AppConstant.baseUrl}stores/$storeId/notify-me';
  static String scheduledDeliveryDatesApi(int storeId) =>
      '${AppConstant.baseUrl}scheduled-delivery/stores/$storeId/dates';
  static String scheduledDeliverySlotsApi(int storeId, String date) =>
      '${AppConstant.baseUrl}scheduled-delivery/stores/$storeId/slots?date=$date';
  static String cartSyncApi = '${AppConstant.baseUrl}user/cart/sync';
  static String deliveryZonesApi = '${AppConstant.baseUrl}delivery-zone';
  static String deliveryZoneDetailApi = '${AppConstant.baseUrl}delivery-zone/';
  static String findStoresApi = '${AppConstant.baseUrl}stores/map';
  static String notificationsApi = '${AppConstant.baseUrl}user/notifications';
  static String markNotificationAsReadApi(String id) => '${AppConstant.baseUrl}user/notifications/$id/read';
  static String markAllNotificationsAsReadApi = '${AppConstant.baseUrl}user/notifications/mark-all-read';
  static String reOrderApi = '${AppConstant.baseUrl}user/orders/';
  static String sendCustomOtpApi = '${AppConstant.baseUrl}auth/send-otp';
  static String verifyCustomOtpApi = '${AppConstant.baseUrl}auth/verify-otp';
  static String versionCheckApi = '${AppConstant.baseUrl}settings/check-version';
  static String getReferInfoApi = '${AppConstant.baseUrl}user/referral';
  static String orderTransactionsApi = '${AppConstant.baseUrl}user/order-transactions';
  static String sendEmailVerificationLinkApi = '${AppConstant.baseUrl}user/update-email';
  static String resendEmailVerificationLinkApi = '${AppConstant.baseUrl}user/email/verification-notification';
  static String adBulkImpressionsApi = '${AppConstant.baseUrl}ads/bulk-impressions';
  static String adBulkClicksApi = '${AppConstant.baseUrl}ads/bulk-clicks';
  static String syncDeviceApi = '${AppConstant.baseUrl}devices/sync';
  static String applyReferralApi = '${AppConstant.baseUrl}user/referral/submit';

  static String homeLayoutApi = '${AppConstant.baseUrl}home-layout';
  // Full paginated items for one home-layout section. Append the section id.
  static String homeLayoutSectionApi = '${AppConstant.baseUrl}home-layout/sections/';
  static String tipApi = '${AppConstant.baseUrl}user/cart/tip';
  static String loyaltyPointsApi = '${AppConstant.baseUrl}user/cart/loyalty-points';
  static String loyaltyPointsTransactionsApi = '${AppConstant.baseUrl}user/loyalty-points/transactions';

  // Discover (Watch and Buy) APIs
  static String watchAndBuyStatusesApi = '${AppConstant.baseUrl}watch-and-buy/statuses';
  static String watchAndBuyStatusesSeenApi = '${AppConstant.baseUrl}watch-and-buy/statuses/seen';
  static String watchAndBuyReelsApi = '${AppConstant.baseUrl}watch-and-buy/reels';
  static String watchAndBuyReelsLikesApi = '${AppConstant.baseUrl}watch-and-buy/reels/likes';
  static String watchAndBuyProfileStatusesApi(String username) =>
      '${AppConstant.baseUrl}watch-and-buy/profiles/$username/statuses';

  // Support Chat APIs
  static String supportThreadApi = '${AppConstant.baseUrl}user/support/thread';

  static String supportThreadMessagesApi = '${AppConstant.baseUrl}user/support/thread/messages';

  static String supportTopicsApi = '${AppConstant.baseUrl}user/support/topics';
  static String supportSessionsApi = '${AppConstant.baseUrl}user/support/sessions';
  static String supportSessionMessagesApi(String slug) => '${AppConstant.baseUrl}user/support/sessions/$slug/messages';
  static String supportSessionTypingApi(String slug) => '${AppConstant.baseUrl}user/support/sessions/$slug/typing';
  static String supportSessionReadApi(String slug) => '${AppConstant.baseUrl}user/support/sessions/$slug/read';
  static String supportSessionCallbacksApi(String slug) =>
      '${AppConstant.baseUrl}user/support/sessions/$slug/callbacks';
  static String supportSessionResolveApi(String slug) => '${AppConstant.baseUrl}user/support/sessions/$slug/resolve';
  static String supportSessionRatingApi(String slug) => '${AppConstant.baseUrl}user/support/sessions/$slug/rating';

  // Languages
  static String fetchLanguages = '${AppConstant.baseUrl}languages';
  static String languageLabels = '${AppConstant.baseUrl}language-labels';
}


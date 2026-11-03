import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:hyper_local/screens/address_list_page/bloc/check_delivery_zone_bloc/check_delivery_zone_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/add_to_cart/add_to_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/attachment/attachment_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/clear_cart/clear_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/promo_code/promo_code_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/update_item_quantity/update_item_quantity_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/validate_promo_code/validate_promo_code_bloc.dart';
import 'package:hyper_local/screens/email_verification/bloc/send_email_verification_bloc/send_email_verification_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/create_order/create_order_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/delivery_boy_feedback/delivery_boy_feedback_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/delivery_tracking/delivery_tracking_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/download_invoice/download_invoice_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/get_my_order/get_my_order_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/order_detail/order_detail_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/re_order/re_order_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/return_order_item/return_order_item_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/store_detail/store_detail_bloc.dart';
import 'package:hyper_local/screens/order__transaction/bloc/order_transactions/order_transactions_bloc.dart';
import 'package:hyper_local/screens/payment_options/bloc/payment_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_detail_bloc/product_detail_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_faq_bloc/product_faq_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_feedback/product_feedback_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_review_bloc/product_review_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/filter/filter_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/filter_category/filter_category_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/filter_product/filter_product_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/nested_category/nested_category_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/product_listing/product_listing_bloc.dart';
import 'package:hyper_local/screens/refer_and_earn/bloc/refer_and_earn/refer_and_earn_bloc.dart';
import 'package:hyper_local/screens/save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import 'package:hyper_local/screens/seller_page/bloc/seller_feedback/seller_feedback_bloc.dart';
import 'package:hyper_local/screens/shopping_list_page/bloc/shopping_list_bloc/shopping_list_bloc.dart';
import 'package:hyper_local/screens/wallet_page/bloc/prepare_wallet_recharge/prepare_recharge_bloc.dart';
import 'package:hyper_local/screens/wallet_page/bloc/user_wallet/user_wallet_bloc.dart';
import 'package:hyper_local/screens/wallet_page/bloc/wallect_transactions/wallet_transactions_bloc.dart';
import 'package:hyper_local/screens/wishlist_page/bloc/wishlist_product_bloc/wishlist_product_bloc.dart';
import 'package:hyper_local/bloc/cart_state_bloc/cart_state_bloc.dart';
import 'package:hyper_local/bloc/device_sync_bloc/device_sync_bloc.dart';
import 'package:hyper_local/bloc/language_bloc/language_bloc.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/bloc/onboarding/onboarding_cubit.dart';
import 'package:hyper_local/bloc/theme_bloc/theme_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/bloc/user_details_bloc/user_details_bloc.dart';
import 'package:hyper_local/screens/ad_campaign/bloc/ad_click_bloc/ad_click_bloc.dart';
import 'package:hyper_local/screens/ad_campaign/bloc/ad_impression_bloc/ad_impression_bloc.dart';
import 'package:hyper_local/screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/cart_ui_bloc/cart_ui_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_local/screens/category_list_page/bloc/all_category_bloc/all_category_bloc.dart';
import 'package:hyper_local/screens/delivery_zone_list/bloc/delivery_zone/delivery_zone_bloc.dart';
import 'package:hyper_local/screens/delivery_zone_list/bloc/delivery_zone_detail/delivery_zone_detail_bloc.dart';

import 'package:hyper_local/screens/home_page/bloc/category/category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_bloc.dart';

import 'package:hyper_local/screens/discover_page/bloc/discover_bloc/discover_bloc.dart';

import 'package:hyper_local/screens/home_page/home_layout/bloc/home_layout_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/find_stores/find_stores_bloc.dart';
import 'package:hyper_local/screens/notification_page/bloc/notification_bloc.dart';
import 'package:hyper_local/screens/payment_options/repo/payment_repository.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/utils/app_update/bloc/app_update_bloc.dart';

import '../screens/auth/bloc/forgot_password/forgot_password_bloc.dart';
import '../screens/auth/bloc/user_verification/user_verification_bloc.dart';
import '../screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import 'dependency_injection_container.dart';

/*
List<SingleChildWidget> globalBlocProviders() {
  return [
    BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
    BlocProvider<UserDataBloc>.value(value: getIt<UserDataBloc>()),
    BlocProvider<CartBloc>.value(value: getIt<CartBloc>()),
    BlocProvider<ThemeBloc>.value(value: getIt<ThemeBloc>()),
    BlocProvider<LanguageBloc>.value(value: getIt<LanguageBloc>()),
    BlocProvider<SettingsBloc>.value(value: getIt<SettingsBloc>()),
    BlocProvider<CartStateBloc>.value(value: getIt<CartStateBloc>()),
    BlocProvider<DeviceSyncBloc>.value(value: getIt<DeviceSyncBloc>()),
    BlocProvider<CartUIBloc>.value(value: getIt<CartUIBloc>()),
    BlocProvider<GetUserCartBloc>.value(value: getIt<GetUserCartBloc>()),
    BlocProvider<UserProfileBloc>.value(value: getIt<UserProfileBloc>()),
    BlocProvider<GetAddressListBloc>.value(value: getIt<GetAddressListBloc>()),
    BlocProvider<CategoryBloc>.value(value: getIt<CategoryBloc>()),
    BlocProvider<BannerBloc>.value(value: getIt<BannerBloc>()),

    BlocProvider<SubCategoryBloc>.value(value: getIt<SubCategoryBloc>()),
    BlocProvider<BrandsBloc>.value(value: getIt<BrandsBloc>()),
    BlocProvider<AllCategoriesBloc>.value(value: getIt<AllCategoriesBloc>()),
    BlocProvider<DeliveryZoneBloc>.value(value: getIt<DeliveryZoneBloc>()),
    BlocProvider<DeliveryZoneDetailBloc>.value(
        value: getIt<DeliveryZoneDetailBloc>()),
    BlocProvider<FindStoresBloc>.value(value: getIt<FindStoresBloc>()),
    BlocProvider<NotificationBloc>.value(value: getIt<NotificationBloc>()),
    BlocProvider<AppUpdateBloc>.value(value: getIt<AppUpdateBloc>()),
    BlocProvider<AdImpressionBloc>.value(value: getIt<AdImpressionBloc>()),
    BlocProvider<AdClickBloc>.value(value: getIt<AdClickBloc>()),
    BlocProvider<UserWishlistBloc>.value(value: getIt<UserWishlistBloc>()),

    // ✅ Newly added global blocs
    BlocProvider<DeliveryTrackingBloc>.value(
        value: getIt<DeliveryTrackingBloc>()),
    BlocProvider<WalletTransactionsBloc>.value(
        value: getIt<WalletTransactionsBloc>()),
    BlocProvider<ReferAndEarnBloc>.value(
        value: getIt<ReferAndEarnBloc>()),
    BlocProvider<OrderTransactionsBloc>.value(
        value: getIt<OrderTransactionsBloc>()),

    RepositoryProvider<PaymentRepository>.value(
        value: getIt<PaymentRepository>()),
  ];
}*/

List<SingleChildWidget> globalBlocProviders() {
  return [
    // ── Core ──
    BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()),
    BlocProvider<UserDataBloc>(create: (_) => getIt<UserDataBloc>()),
    BlocProvider<CartBloc>(create: (_) => getIt<CartBloc>()),
    BlocProvider<ThemeBloc>(create: (_) => getIt<ThemeBloc>()),
    BlocProvider<LanguageBloc>(create: (_) => getIt<LanguageBloc>()),
    BlocProvider<LanguageListBloc>(create: (_) => getIt<LanguageListBloc>()),
    BlocProvider<SettingsBloc>(create: (_) => getIt<SettingsBloc>()),
    BlocProvider<OnboardingCubit>(create: (_) => OnboardingCubit()),
    BlocProvider<CartStateBloc>(create: (_) => getIt<CartStateBloc>()),
    BlocProvider<DeviceSyncBloc>(create: (_) => getIt<DeviceSyncBloc>()),
    BlocProvider<CartUIBloc>(create: (_) => getIt<CartUIBloc>()),
    BlocProvider<GetUserCartBloc>(create: (_) => getIt<GetUserCartBloc>()),
    BlocProvider<UserProfileBloc>(create: (_) => getIt<UserProfileBloc>()),
    BlocProvider<GetAddressListBloc>(create: (_) => getIt<GetAddressListBloc>()),

    // ── Home ──
    BlocProvider<CategoryBloc>(create: (_) => getIt<CategoryBloc>()),
    BlocProvider<SubCategoryBloc>(create: (_) => getIt<SubCategoryBloc>()),
    BlocProvider<AllCategoriesBloc>(create: (_) => getIt<AllCategoriesBloc>()),
    BlocProvider<HomeLayoutBloc>(create: (_) => getIt<HomeLayoutBloc>()),

    // ── Features ──
    BlocProvider<DeliveryZoneBloc>(create: (_) => getIt<DeliveryZoneBloc>()),
    BlocProvider<DeliveryZoneDetailBloc>(create: (_) => getIt<DeliveryZoneDetailBloc>()),
    BlocProvider<FindStoresBloc>(create: (_) => getIt<FindStoresBloc>()),
    BlocProvider<NotificationBloc>(create: (_) => getIt<NotificationBloc>()),
    BlocProvider<AppUpdateBloc>(create: (_) => getIt<AppUpdateBloc>()),
    BlocProvider<UserWishlistBloc>(create: (_) => getIt<UserWishlistBloc>()),
    BlocProvider<AdImpressionBloc>(create: (_) => getIt<AdImpressionBloc>()),
    BlocProvider<AdClickBloc>(create: (_) => getIt<AdClickBloc>()),

    // ── Extra Globals ──
    BlocProvider<DeliveryTrackingBloc>(create: (_) => getIt<DeliveryTrackingBloc>()),
    BlocProvider<WalletTransactionsBloc>(create: (_) => getIt<WalletTransactionsBloc>()),
    BlocProvider<ReferAndEarnBloc>(create: (_) => getIt<ReferAndEarnBloc>()),
    BlocProvider<OrderTransactionsBloc>(create: (_) => getIt<OrderTransactionsBloc>()),

    // ── Product / Filters ──
    BlocProvider(create: (_) => getIt<FilterCategoryBloc>()),
    BlocProvider(create: (_) => getIt<FilterProductBloc>()),
    BlocProvider(create: (_) => getIt<ProductListingBloc>()),
    BlocProvider(create: (_) => getIt<ProductDetailBloc>()),
    BlocProvider(create: (_) => getIt<SimilarProductBloc>()),
    BlocProvider(create: (_) => getIt<ProductFAQBloc>()),
    BlocProvider(create: (_) => getIt<ProductReviewBloc>()),

    // ── Cart ──
    BlocProvider(create: (_) => getIt<AddToCartBloc>()),
    BlocProvider(create: (_) => getIt<RemoveItemFromCartBloc>()),
    BlocProvider(create: (_) => getIt<ClearCartBloc>()),
    BlocProvider(create: (_) => getIt<UpdateItemQuantityBloc>()),
    BlocProvider(create: (_) => getIt<CartUIBloc>()),

    // ── Promo ──
    BlocProvider(create: (_) => getIt<PromoCodeBloc>()),
    BlocProvider(create: (_) => getIt<ValidatePromoCodeBloc>()),

    // ── Orders ──
    BlocProvider(create: (_) => getIt<CreateOrderBloc>()),
    BlocProvider(create: (_) => getIt<OrderDetailBloc>()),
    BlocProvider(create: (_) => getIt<GetMyOrderBloc>()),
    BlocProvider(create: (_) => getIt<ReOrderBloc>()),
    BlocProvider(create: (_) => getIt<DownloadInvoiceBloc>()),
    BlocProvider(create: (_) => getIt<ReturnOrderItemBloc>()),

    // ── Misc ──
    BlocProvider(create: (_) => getIt<AttachmentBloc>()),
    BlocProvider(create: (_) => getIt<FilterBloc>()),
    BlocProvider(create: (_) => getIt<DeliveryBoyFeedbackBloc>()),
    BlocProvider(create: (_) => getIt<ProductFeedbackBloc>()),
    BlocProvider(create: (_) => getIt<WishlistProductBloc>()),
    BlocProvider(create: (_) => getIt<NestedCategoryBloc>()),
    BlocProvider(create: (_) => getIt<SaveForLaterBloc>()),
    BlocProvider(create: (_) => getIt<ShoppingListBloc>()),
    BlocProvider(create: (_) => getIt<UserWalletBloc>()),
    BlocProvider(create: (_) => getIt<PrepareRechargeBloc>()),
    BlocProvider(create: (_) => getIt<SellerFeedbackBloc>()),
    BlocProvider(create: (_) => getIt<NearByStoreBloc>()),
    BlocProvider(create: (_) => getIt<StoreDetailBloc>()),
    BlocProvider(create: (_) => getIt<CheckDeliveryZoneBloc>()),
    BlocProvider(create: (_) => getIt<SendEmailVerificationBloc>()),
    BlocProvider(create: (_) => getIt<UserVerificationBloc>()),
    BlocProvider(create: (_) => getIt<ForgotPasswordBloc>()),
    
    // ── Discover ──
    BlocProvider(create: (_) => getIt<DiscoverBloc>()),

    // ── Payment ──
    BlocProvider(create: (_) => getIt<PaymentBloc>()),

    RepositoryProvider<PaymentRepository>.value(
      value: getIt<PaymentRepository>(),
    ),
  ];
}

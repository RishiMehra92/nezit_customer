import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hyper_local/config/global_keys.dart';
import 'package:hyper_local/screens/auth/bloc/apply_referral/apply_referral_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local/screens/auth/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:hyper_local/screens/auth/view/forgot_password.dart';
import 'package:hyper_local/screens/auth/view/login_page.dart';
import 'package:hyper_local/screens/auth/view/otp_verification_page.dart';
import 'package:hyper_local/screens/auth/view/referral_code_entry_page.dart';
import 'package:hyper_local/screens/auth/view/register_page.dart';
import 'package:hyper_local/screens/cart_page/view/cart_page.dart';
import 'package:hyper_local/screens/cart_page/view/promo_code_page.dart';
import 'package:hyper_local/screens/category_list_page/view/category_list_page.dart';
import 'package:hyper_local/screens/home_page/view/home_page.dart';
import 'package:hyper_local/screens/introduction_pages/view/introduction_page.dart';
import 'package:hyper_local/screens/my_orders/view/order_detail_page.dart';
import 'package:hyper_local/screens/my_orders/view/rate_your_exp_comments.dart';
import 'package:hyper_local/screens/my_orders/view/rate_your_exp_page.dart';
import 'package:hyper_local/screens/my_orders/widgets/order_delivered_page.dart';
import 'package:hyper_local/screens/near_by_stores/view/nearby_store_details.dart';
import 'package:hyper_local/screens/near_by_stores/view/nearyby_stores_page.dart';
import 'package:hyper_local/screens/order__transaction/view/order_transaction_page.dart';
import 'package:hyper_local/screens/product_detail_page/view/faq_list_page/faq_list_page.dart';
import 'package:hyper_local/screens/product_detail_page/view/review_rating_list_page/review_rating_list_page.dart';
import 'package:hyper_local/screens/shopping_list_page/view/shopping_list_result_page.dart';
import 'package:hyper_local/screens/splash_screen/splash_screen.dart';
import 'package:hyper_local/screens/sub_category_page/view/sub_category_page.dart';
import 'package:hyper_local/screens/support_page/view/support_page.dart';
import 'package:hyper_local/screens/coins_page/view/coins_page.dart';
import 'package:hyper_local/screens/coins_page/bloc/coins_bloc.dart';
import 'package:hyper_local/screens/email_verification/view/email_verification_page.dart';
import 'package:hyper_local/screens/mobile_verification/view/mobile_verification_page.dart';
import 'package:hyper_local/screens/user_profile/view/user_profile_page.dart';
import 'package:hyper_local/screens/wallet_page/bloc/wallect_transactions/wallet_transactions_bloc.dart';
import 'package:hyper_local/screens/wallet_page/view/transaction_page.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/utils/widgets/no_internet_connection.dart';
import '../config/constant.dart';
import '../config/map_code.dart';
import '../screens/account_page/view/account_page.dart';
import '../screens/auth/view/mobile_otp_login.dart';
import '../screens/dashboard/view/dashboard.dart';
import '../screens/delivery_zone_list/view/delivery_zone_detail_page.dart';
import '../screens/delivery_zone_list/view/delivery_zone_listing_page.dart';
import '../screens/my_orders/view/delivery_tracking_page.dart';
import '../screens/my_orders/view/my_orders_page.dart';
import '../screens/my_orders/view/order_success_page.dart';
import '../screens/my_orders/view/ready_for_pickup_page.dart';
import '../screens/policies/view/app_policies_page.dart';
import '../screens/product_detail_page/view/product_detail_page.dart';
import '../screens/address_list_page/view/address_list_page.dart';
import '../screens/payment_options/view/payment_options_page.dart';
import '../screens/product_listing_page/model/product_listing_type.dart';
import '../screens/product_listing_page/view/product_listing_page.dart';
import '../screens/refer_and_earn/view/refer_and_earn_page.dart';
import '../screens/save_for_later_page/view/save_for_later_page.dart';
import '../screens/search_page/view/search_page.dart';
import '../screens/shopping_list_page/view/shopping_list_page.dart';
import '../screens/wallet_page/view/add_money_page.dart';
import '../screens/wallet_page/view/wallet_page.dart';
import '../screens/notification_page/view/notification_page.dart';
import '../screens/wishlist_page/view/wishlist_page.dart';
import '../screens/wishlist_page/view/wishlist_product_listing_page.dart';
import '../screens/discover_page/view/discover_page.dart';
import '../screens/discover_page/view/discover_reels_page.dart';
import '../screens/discover_page/view/discover_story_page.dart';
import '../utils/widgets/page_animation.dart';
import 'package:hyper_local/screens/section_see_all/view/section_see_all_page.dart';
import 'package:hyper_local/screens/product_section_see_all/view/product_section_see_all_page.dart';

Page platformPage(Widget child, {BuildContext? context, GoRouterState? state}) {
  if (Platform.isIOS) {
    // iOS: Keep native Cupertino transition (or wrap with CustomTransitionPage if you want same animation on both platforms)
    return CupertinoPage(child: child);
  } else {
    // Android & others: Use custom animation
    if (context != null && state != null) {
      return buildAnimatedPage(context, state, child);
    }
    return MaterialPage(child: child);
  }
}

class AppRoutes {
  static const String splashScreen = '/';
  static const String introSlider = '/intro-slider';
  static const String login = '/login';
  static const String register = '/register';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';
  static const String orderAgain = '/order-again';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String locationPicker = '/location-picker';
  static const String account = '/account';
  static const String productListing = '/product-listing';
  static const String productDetailPage = '/product-detail';
  static const String reviewRatingPage = '/review-rating';
  static const String faqPage = '/faq';
  static const String addressList = '/address-list';
  static const String paymentOptions = '/payment-options';
  static const String orderSuccess = '/order-success';
  static const String userProfile = '/user-profile';
  static const String promoCode = '/promo-code';
  static const String myOrders = '/my-orders';
  static const String orderDetail = '/order-detail';
  static const String shoppingList = '/shopping-list';
  static const String wallet = '/wallet';
  static const String addMoney = '/add-money';
  static const String transactions = '/transactions';
  static const String deliveryTracking = '/delivery-tracking';
  static const String shoppingListResult = '/shopping-list-result';
  static const String wishlistPage = '/wishlist';
  static const String discover = '/discover';
  static const String noInternet = '/no-internet';
  static const String search = '/search';
  static const String wishlistProduct = '/wishlist-product';
  static const String saveForLater = '/save-for-later';
  static const String policyPage = '/policy-page';
  static const String supportPage = '/support-page';
  static const String coinsPage = '/coins-page';
  static const String nearbyStores = '/near-by-store';
  static const String nearbyStoreDetails = '/near-by-store-details';
  static const String rateYourExp = '/rate-your-exp';
  static const String rateYourExpComments = '/rate-your-exp-comments';
  static const String forgotPassword = '/forgot-password';
  static const String maintenancePage = '/maintenance-page';
  static const String mobileOtpLoginPage = '/mobile-otp-login-page';
  static const String orderDelivered = '/order-delivered';
  static const String deliveryZoneList = '/delivery-zones';
  static const String deliveryZoneDetail = '/delivery-zone-detail';
  static const String notifications = '/notifications';
  static const String forceUpdateWaitingScreen = '/force-update-waiting-screen';
  static const String referAndEarnPage = '/refer-and-earn-page';
  static const String readyForPickup = '/ready-for-pickup';
  static const String subCategoryListPage = '/sub-category-list-page';
  static const String orderTransactionsPage = '/order-transaction-page';
  static const String emailVerification = '/email-verification';
  static const String mobileVerification = '/mobile-verification';
  static const String referralCodeEntry = '/referral-code-entry';
  static const String sectionSeeAll = '/section-see-all';
  static const String productSectionSeeAll = '/product-section-see-all';
  static const String discoverReels = '/discover-reels';
  static const String discoverStory = '/discover-story';
}

class MyAppRoute {
  static GoRouter router = GoRouter(
      navigatorKey: GlobalKeys.navigatorKey,
      initialLocation: AppRoutes.splashScreen,
      observers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      onException: (context, state, router) {
        // Ignore Firebase Auth redirects (reCAPTCHA flow) so we stay on the current page
        if (state.uri.toString().contains('firebaseauth/link')) {
          return;
        }
        // For any other routing errors, go to home or show a simple error
        debugPrint('Routing error: ${state.error}');
        router.go(AppRoutes.splashScreen);
      },
      redirect: (context, state) {
        if (!AppConstant.hasValidBaseUrl) {
          final loc = state.matchedLocation;
          if (loc != AppRoutes.splashScreen) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final ctx = GlobalKeys.navigatorKey.currentContext;
              if (ctx != null) {
                ToastManager.show(
                  context: ctx,
                  message: 'user not found',
                  type: ToastType.error,
                );
              }
            });
            return AppRoutes.splashScreen;
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          name: '/',
          path: AppRoutes.splashScreen,
          pageBuilder: (context, state) => platformPage(const SplashScreen()),
        ),
        GoRoute(
          name: '/intro-slider',
          path: AppRoutes.introSlider,
          pageBuilder: (context, state) => platformPage(const IntroductionPage()),
        ),
        GoRoute(
          name: AppRoutes.discoverReels,
          path: AppRoutes.discoverReels,
          pageBuilder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return CustomTransitionPage(
              opaque: false,
              barrierColor: Colors.transparent,
              child: DiscoverReelsPage(
                initialIndex: args?['initialIndex'] ?? 0,
                reels: args?['reels'] ?? [],
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
        ),
        GoRoute(
          name: AppRoutes.discoverStory,
          path: AppRoutes.discoverStory,
          pageBuilder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return CustomTransitionPage(
              opaque: false,
              barrierColor: Colors.transparent,
              child: DiscoverStoryPage(
                users: args?['users'] ?? [],
                initialUserIndex: args?['initialUserIndex'] ?? 0,
                onPageChanged: args?['onPageChanged'] as void Function(int)?,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
        ),
        GoRoute(
          path: '/link',
          name: 'firebase-link',
          redirect: (context, state) {
            final authBloc = BlocProvider.of<AuthBloc>(GlobalKeys.navigatorKey.currentContext!);
            final authState = authBloc.state;

            // If we have pending login or registration data → stay on /link temporarily
            if (authState is LoginPhoneCodeSentState) {
              final pendingData = authBloc.getPendingRegistrationData();
              if (authState.isLogin || pendingData != null) {
                // Don't redirect here — let the pageBuilder push to OTP
                return null; // stay on /link temporarily
              } else {
                // No pending data & not login → redirect to register
                return AppRoutes.register;
              }
            }

            // If auth failed → go to register or login depending on flow
            if (authState is AuthFailed) {
              final pendingData = authBloc.getPendingRegistrationData();
              if (pendingData != null) {
                return AppRoutes.register;
              } else {
                return AppRoutes.mobileOtpLoginPage;
              }
            }

            // Otherwise stay on /link to show loading
            return null;
          },
          pageBuilder: (context, state) {
            return platformPage(
              BlocListener<AuthBloc, AuthState>(
                listener: (context, authState) async {
                  if (authState is LoginPhoneCodeSentState) {
                    final bloc = context.read<AuthBloc>();
                    final pendingData = bloc.getPendingRegistrationData();
                    final isLogin = authState.isLogin;

                    if (context.mounted) {
                      if (isLogin) {
                        final completeNumber =
                            (bloc.getPendingCountryCode() ?? '') + (bloc.getPendingPhoneNumber() ?? '');
                        context.pushReplacement(
                          AppRoutes.otpVerification,
                          extra: {
                            'phoneNumber': completeNumber,
                            'registrationData': <String, dynamic>{},
                            'verificationId': authState.verificationId,
                            'userNumber': bloc.getPendingPhoneNumber(),
                            'countryCode': bloc.getPendingCountryCode(),
                            'isoCode': bloc.getPendingIsoCode(),
                            'isLogin': true,
                            'userName': bloc.getPendingUserName() ?? '',
                            'referralCode': bloc.getPendingReferralCode() ?? '',
                            'isUpdate': bloc.getPendingIsUpdate(),
                          },
                        );
                      } else if (pendingData != null) {
                        final completeNumber = pendingData['completePhoneNumber'] ??
                            ((bloc.getPendingCountryCode() ?? '') + (bloc.getPendingPhoneNumber() ?? ''));
                        context.pushReplacement(
                          AppRoutes.otpVerification,
                          extra: {
                            'phoneNumber': completeNumber,
                            'registrationData': pendingData,
                            'verificationId': authState.verificationId,
                            'userNumber': bloc.getPendingPhoneNumber(),
                            'countryCode': bloc.getPendingCountryCode(),
                            'isoCode': bloc.getPendingIsoCode(),
                            'isLogin': false,
                            'userName': bloc.getPendingUserName() ?? '',
                            'referralCode': bloc.getPendingReferralCode() ?? '',
                            'isUpdate': false,
                          },
                        );
                      }
                    }
                  }

                  if (authState is AuthFailed && context.mounted) {
                    ToastManager.show(
                      context: context,
                      message: authState.error,
                      type: ToastType.error,
                    );

                    final bloc = context.read<AuthBloc>();
                    if (bloc.getPendingRegistrationData() != null) {
                      context.go(AppRoutes.register);
                    } else {
                      context.go(AppRoutes.mobileOtpLoginPage);
                    }
                  }
                },
                child: const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomCircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        GoRoute(
            name: 'otp-verification',
            path: AppRoutes.otpVerification,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return platformPage(OTPVerificationPage(
                phoneNumber: extra['phoneNumber'] ?? '',
                registrationData: extra['registrationData'] ?? {},
                verificationId: extra['verificationId'] ?? '',
                number: extra['userNumber'] ?? '',
                countryCode: extra['countryCode'] ?? '',
                isoCode: extra['isoCode'] ?? '',
                isLogin: extra['isLogin'] ?? false,
                userName: extra['userName'] ?? '',
                referralCode: extra['referralCode'] ?? '',
                isUpdate: extra['isUpdate'] ?? false,
                popOnSuccess: extra['popOnSuccess'] ?? false,
              ));
            }),
        GoRoute(
          name: 'login',
          path: AppRoutes.login,
          pageBuilder: (context, state) => platformPage(const LoginPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'forgot-password',
          path: AppRoutes.forgotPassword,
          pageBuilder: (context, state) => platformPage(
              BlocProvider(
                create: (_) => ForgotPasswordBloc(),
                child: const ForgotPassword(),
              ),
              context: context,
              state: state),
        ),
        GoRoute(
          name: 'referral-code-entry',
          path: AppRoutes.referralCodeEntry,
          pageBuilder: (context, state) => platformPage(
            BlocProvider(
              create: (_) => ApplyReferralBloc(),
              child: const ReferralCodeEntryPage(),
            ),
            context: context,
            state: state,
          ),
        ),
        GoRoute(
          name: 'no-internet',
          path: AppRoutes.noInternet,
          pageBuilder: (context, state) => platformPage(const NoInternetConnection(), context: context, state: state),
        ),
        GoRoute(
          name: 'register',
          path: AppRoutes.register,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
              RegisterPage(
                userName: extra['name'] ?? '',
                userEmail: extra['email'] ?? '',
              ),
            );
          },
        ),
        StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return Dashboard(
                index: navigationShell.currentIndex,
                navigationShell: navigationShell,
              );
            },
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'home',
                  path: AppRoutes.home,
                  pageBuilder: (context, state) => platformPage(
                    const HomePage(),
                  ),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'category-list-page',
                  path: AppRoutes.categories,
                  pageBuilder: (context, state) => platformPage(
                    const CategoryListPage(),
                  ),
                ),
              ]),

              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'near-by-store',
                  path: AppRoutes.nearbyStores,
                  pageBuilder: (context, state) =>
                      platformPage(const NearbyStoresPage(), context: context, state: state),
                ),
              ]),

              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'account',
                  path: AppRoutes.account,
                  pageBuilder: (context, state) => platformPage(const AccountPage(), context: context, state: state),
                ),
              ]),

              // if(AppHelpers.systemVendorTypeIsSingle == true)
              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'my-orders',
                  path: AppRoutes.myOrders,
                  pageBuilder: (context, state) => platformPage(const MyOrdersPage(), context: context, state: state),
                ),
              ]),

              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'discover',
                  path: AppRoutes.discover,
                  pageBuilder: (context, state) => platformPage(const DiscoverPage(), context: context, state: state),
                ),
              ])
            ]),
        GoRoute(
          name: 'cart',
          path: AppRoutes.cart,
          pageBuilder: (context, state) => platformPage(const CartPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'location-picker',
          path: AppRoutes.locationPicker,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return LocationPickerWidget(
              initialLatitude: args?['lat'],
              initialLongitude: args?['lng'],
              initialAddress: args?['address'],
              isFromAddressPage: args?['isFromAddressPage'],
              isEdit: args?['isEdit'],
              addressId: args?['addressId'],
              addressType: args?['addressType'],
              isFromCartPage: args?['isFromCartPage'],
              deliveryZoneId: args?['deliveryZoneId'],
            );
          },
        ),
        GoRoute(
          name: 'product-listing',
          path: AppRoutes.productListing,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final isTheirMoreCategory = extra['isTheirMoreCategory'] as bool? ?? false; // Default to false if null
            final dynamic rawType = extra['type'];
            final ProductListingType listingType = rawType is ProductListingType
                ? rawType
                : rawType is String
                    ? ProductListingType.values.firstWhere(
                        (e) => e.name == rawType,
                        orElse: () => ProductListingType.category,
                      )
                    : ProductListingType.category;
            final String identifier = (extra['identifier']?.toString() ??
                extra['categorySlug']?.toString() ??
                state.uri.queryParameters['identifier'] ??
                state.uri.queryParameters['category-slug'] ??
                '');
            return platformPage(
              ProductListingPage(
                key: ValueKey('product-listing-$identifier-${state.pageKey}'),
                isTheirMoreCategory: isTheirMoreCategory,
                title: extra['title']?.toString() ?? '',
                logo: extra['logo']?.toString() ?? '',
                totalProduct: extra['totalProduct']?.toString() ?? '',
                type: listingType,
                identifier: identifier,
              ),
            );
          },
        ),
        GoRoute(
            name: 'product-detail',
            path: AppRoutes.productDetailPage,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final productSlug = extra['productSlug']?.toString() ?? state.uri.queryParameters['productSlug'] ?? '';
              final title = extra['title']?.toString() ?? '';
              final mainImage = extra['mainImage']?.toString() ?? '';

              return platformPage(
                ProductDetailPage(
                  key: ValueKey('product-detail-$productSlug'),
                  productSlug: productSlug,
                  initialData: ProductInitialData(title: title, mainImage: mainImage),
                ),
              );
            }),
        GoRoute(
            name: 'review-rating',
            path: AppRoutes.reviewRatingPage,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, String>;
              return platformPage(
                  ReviewRatingListPage(
                    productSlug: extra['productSlug']!,
                  ),
                  context: context,
                  state: state);
            }),
        GoRoute(
            name: 'faq',
            path: AppRoutes.faqPage,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, String>;
              return platformPage(
                  FaqListPage(
                    productSlug: extra['productSlug']!,
                  ),
                  context: context,
                  state: state);
            }),
        GoRoute(
          name: 'address-list',
          path: AppRoutes.addressList,
          pageBuilder: (context, state) => platformPage(const AddressListPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'payment-options',
          path: AppRoutes.paymentOptions,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                PaymentOptionsPage(
                  totalAmount: extra['totalAmount']?.toDouble() ?? 0.0,
                  isFromAddMoney: extra['isFromAddMoney'] as bool? ?? false,
                  deliveryType: extra['deliveryType'] as String?,
                  isPickupCodEnabled: extra['isPickupCodEnabled'] as bool?,
                  nonCodPickupStores: (extra['nonCodPickupStores'] as List?)?.cast<String>(),
                  hasTip: extra['hasTip'] as bool? ?? false,
                  codCharges: extra['codCharges']?.toDouble(),
                  currencyCode: extra['currencyCode'] as String?,
                  availablePaymentMethods: extra['availablePaymentMethods'] as List<dynamic>?,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
            name: 'order-success',
            path: AppRoutes.orderSuccess,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return platformPage(
                  OrderSuccessPage(
                    address: extra['address']?.toString() ?? '',
                    addressType: extra['addressType']?.toString() ?? '',
                    orderSlug: extra['orderSlug']?.toString() ?? '',
                    isPickup: extra['isPickup'] as bool? ?? false,
                  ),
                  context: context,
                  state: state);
            }),
        GoRoute(
          name: 'user-profile',
          path: AppRoutes.userProfile,
          pageBuilder: (context, state) => platformPage(const UserProfilePage(), context: context, state: state),
        ),
        GoRoute(
          name: 'email-verification',
          path: AppRoutes.emailVerification,
          pageBuilder: (context, state) => platformPage(
            const EmailVerificationPage(),
            context: context,
            state: state,
          ),
        ),
        GoRoute(
          name: 'mobile-verification',
          path: AppRoutes.mobileVerification,
          pageBuilder: (context, state) => platformPage(
            const MobileVerificationPage(),
            context: context,
            state: state,
          ),
        ),
        GoRoute(
          name: 'promo-code',
          path: AppRoutes.promoCode,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                PromoCodePage(
                  cartAmount: extra['cartAmount']?.toDouble(),
                  deliveryCharges: extra['deliveryCharges']?.toDouble(),
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'order-detail',
          path: AppRoutes.orderDetail,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final orderSlug =
                extra['order-slug']?.toString() ?? state.uri.queryParameters['order-slug']?.toString() ?? '';
            final allowRedirect = extra['allowRedirect'] as bool? ??
                (state.uri.queryParameters['allowRedirect'] != null
                    ? state.uri.queryParameters['allowRedirect'] == 'true'
                    : true);
            return platformPage(
                OrderDetailPage(
                  orderSlug: orderSlug,
                  allowRedirect: allowRedirect,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'shopping-list',
          path: AppRoutes.shoppingList,
          pageBuilder: (context, state) => platformPage(const ShoppingListPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'wallet',
          path: AppRoutes.wallet,
          pageBuilder: (context, state) => platformPage(const WalletPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'add-money',
          path: AppRoutes.addMoney,
          pageBuilder: (context, state) => platformPage(const AddMoneyPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'transactions',
          path: AppRoutes.transactions,
          pageBuilder: (context, state) => platformPage(
              BlocProvider(
                create: (_) => WalletTransactionsBloc(),
                child: const TransactionPage(),
              ),
              context: context,
              state: state),
        ),
        GoRoute(
          name: 'delivery-tracking',
          path: AppRoutes.deliveryTracking,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final orderSlug =
                extra['order-slug']?.toString() ?? state.uri.queryParameters['order-slug']?.toString() ?? '';
            return platformPage(
                DeliveryTrackingPage(
                  orderSlug: orderSlug,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'ready-for-pickup',
          path: AppRoutes.readyForPickup,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                ReadyForPickupPage(
                  orderSlug: extra['order-slug']?.toString() ?? '',
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'shopping-list-result',
          path: AppRoutes.shoppingListResult,
          pageBuilder: (context, state) => platformPage(const ShoppingListResultPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'wishlist',
          path: AppRoutes.wishlistPage,
          pageBuilder: (context, state) => platformPage(const WishlistPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'search',
          path: AppRoutes.search,
          pageBuilder: (context, state) => platformPage(const SearchPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'wishlist-product',
          path: AppRoutes.wishlistProduct,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final wishlistId = extra['wishlist-id'] ?? state.uri.queryParameters['wishlist-id'];
            return platformPage(
                WishlistProductListingPage(
                  wishlistId: wishlistId,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'save-for-later',
          path: AppRoutes.saveForLater,
          pageBuilder: (context, state) => platformPage(const SaveForLaterPage(), context: context, state: state),
        ),
        GoRoute(
            name: 'policy-page',
            path: AppRoutes.policyPage,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return platformPage(
                  PolicyPage(
                    policyType: extra['policy-type'] ?? PolicyType.aboutUs,
                  ),
                  context: context,
                  state: state);
            }),
        GoRoute(
          name: 'support-page',
          path: AppRoutes.supportPage,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            final rawOrderId =
                extra['order-id'] ?? state.uri.queryParameters['order-id'];
            final orderId = rawOrderId is int
                ? rawOrderId
                : int.tryParse(rawOrderId?.toString() ?? '');
            final ticketSlug = extra['ticket-slug']?.toString() ??
                state.uri.queryParameters['ticket-slug'];
            return platformPage(
              SupportPage(
                initialOrderId: orderId,
                ticketSlug: ticketSlug,
              ),
              context: context,
              state: state,
            );
          },
        ),
        GoRoute(
          name: 'coins-page',
          path: AppRoutes.coinsPage,
          pageBuilder: (context, state) => platformPage(
              BlocProvider(
                create: (_) => CoinsBloc()..add(FetchCoinsSummary()),
                child: const CoinsPage(),
              ),
              context: context,
              state: state),
        ),
        GoRoute(
          name: 'near-by-store-details',
          path: AppRoutes.nearbyStoreDetails,
          pageBuilder: (context, state) {
            final map = state.extra as Map<String, dynamic>? ?? {};
            final storeSlug = map['store-slug'] ?? state.uri.queryParameters['store-slug'] ?? '';
            final storeName = map['store-name'] ?? '';
            return platformPage(
                NearbyStoreDetails(
                  storeSlug: storeSlug,
                  storeName: storeName,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'rate-your-exp',
          path: AppRoutes.rateYourExp,
          pageBuilder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            final orderSlug = map["orderSlug"];
            final orderId = map["orderId"];
            return platformPage(
                RateYourExpPage(
                  orderSlug: orderSlug,
                  orderId: orderId,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'rate-your-exp-comments',
          path: AppRoutes.rateYourExpComments,
          pageBuilder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            final orderSlug = map["orderSlug"];
            final items = map["items"];
            return platformPage(RateYourExpComments(orderSlug: orderSlug, items: items),
                context: context, state: state);
          },
        ),
        GoRoute(
          name: 'maintenance-page',
          path: AppRoutes.maintenancePage,
          pageBuilder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            final message = map["message"];
            return platformPage(MaintenancePage(description: message), context: context, state: state);
          },
        ),

        GoRoute(
          name: 'mobile-otp-login-page',
          path: AppRoutes.mobileOtpLoginPage,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                MobileOtpLoginPage(
                  isDirectLogin: extra['isDirectLogin'],
                  isUpdate: extra['isUpdate'] ?? false,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
            name: 'order-delivered',
            path: AppRoutes.orderDelivered,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return platformPage(
                  OrderDeliveredPage(
                    address: extra['address'].toString(),
                    addressType: extra['addressType'].toString(),
                    orderSlug: extra['orderSlug'].toString(),
                  ),
                  context: context,
                  state: state);
            }),
        GoRoute(
          name: 'delivery-zone',
          path: AppRoutes.deliveryZoneList,
          pageBuilder: (context, state) =>
              platformPage(const DeliveryZoneListingPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'delivery-zone-detail',
          path: AppRoutes.deliveryZoneDetail,
          pageBuilder: (context, state) {
            final map = state.extra as Map<String, dynamic>? ?? {};
            final zoneId = map["zoneId"] ?? int.tryParse(state.uri.queryParameters['zoneId'] ?? '');
            return platformPage(
                DeliveryZoneDetailPage(
                  zoneId: zoneId,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'notifications',
          path: AppRoutes.notifications,
          pageBuilder: (context, state) => platformPage(const NotificationPage(), context: context, state: state),
        ),
        GoRoute(
          name: 'refer-and-earn-page',
          path: AppRoutes.referAndEarnPage,
          pageBuilder: (context, state) {
            return platformPage(const ReferAndEarnPage(), context: context, state: state);
          },
        ),
        GoRoute(
          name: 'sub-category-list-page',
          path: AppRoutes.subCategoryListPage,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                SubCategoryListPage(
                  slug: extra['slug'] ?? '',
                  isForAllCategory: extra['isForAllCategory'] as bool?,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'order-transactions-page',
          path: AppRoutes.orderTransactionsPage,
          pageBuilder: (context, state) {
            return platformPage(const OrderTransactionPage(), context: context, state: state);
          },
        ),
        GoRoute(
          name: 'section-see-all',
          path: AppRoutes.sectionSeeAll,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
              SectionSeeAllPage(
                sectionId: extra['section-id'] ?? 0,
                type: extra['type'] ?? '',
                title: extra['title'] ?? '',
              ),
              context: context,
              state: state,
            );
          },
        ),
        GoRoute(
          name: 'product-section-see-all',
          path: AppRoutes.productSectionSeeAll,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
              ProductSectionSeeAllPage(
                sectionId: extra['section-id'] ?? 0,
                title: extra['title'] ?? '',
              ),
              context: context,
              state: state,
            );
          },
        ),
      ]);
}

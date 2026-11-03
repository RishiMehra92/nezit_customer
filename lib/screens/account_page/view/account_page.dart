import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/account_page/widgets/account_page_app_bar.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_local/screens/policies/view/app_policies_page.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/services/auth_guard.dart';
import 'package:hyper_local/services/recent_product/recent_product_service.dart';
import 'package:hyper_local/services/shopping_list_hive.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../bloc/language_bloc/language_bloc.dart';
import '../../../config/helper.dart';
import '../../../config/theme.dart';
import '../../../config/global.dart';
import '../../../model/selected_address/selected_address_model.dart';
import '../../../services/address/selected_address_hive.dart';
import '../../../services/location/location_service.dart';
import '../../../utils/widgets/animated_button.dart';
import '../../../utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../../../utils/widgets/language_bottom_sheet.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../auth/bloc/auth/auth_event.dart';
import '../widgets/icon_box_widget.dart';
import '../widgets/quick_action_widget.dart';
import '../widgets/section_card_widget.dart';
import '../widgets/appearance_bottom_sheet.dart';
import '../widgets/settings_tile_widget.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? userLocation;
  SelectedAddress? selectedAddress;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    initiateLocation();
    loadSelectedAddress();
    context.read<UserProfileBloc>().add(FetchUserProfile());
  }

  Future<void> initiateLocation() async {
    final location = LocationService.getStoredLocation();
    userLocation = location!.fullAddress;
  }

  void loadSelectedAddress() {
    final address = HiveSelectedAddressHelper.getSelectedAddress();
    setState(() {
      selectedAddress = address;
    });
  }

  Future<bool> checkUserLoggedIn() async {
    isLoggedIn = await AuthGuard.ensureLoggedIn(context);

    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {

    return MultiBlocListener(
      listeners: [
        BlocListener<UserProfileBloc, UserProfileState>(listener: (context, state) {}),
        BlocListener<AuthBloc, AuthState>(listener: (context, state) {
          if (state is LogoutUser) {
            Global.clearUserData();
            ShoppingListHiveHelper.clearLastList();
            RecentlyViewedService.clear();
            context.read<GetUserCartBloc>().add(FetchUserCart());
            // CartService.triggerCartAnimation(context);
            GoRouter.of(context).pushReplacement(AppRoutes.login);
          }
          if (state is DeleteUserSuccess) {
            Global.clearUserData();
            ShoppingListHiveHelper.clearLastList();
            RecentlyViewedService.clear();
            context.read<GetUserCartBloc>().add(FetchUserCart());
            // CartService.triggerCartAnimation(context);
            GoRouter.of(context).pushReplacement(AppRoutes.login);
          }
          if (state is AuthFailed) {
            ToastManager.show(
              context: context,
              message: state.error,
              type: ToastType.error,
            );
          }
        }),
      ],
      child: CustomScaffold(
        showViewCart: false,
        onConnectivityRestored: (_) async {
          context.read<UserProfileBloc>().add(FetchUserProfile());
        },
        appBar: const AccountPageAppBar(),
        body: SingleChildScrollView(
          child: StaggeredListAnimator(
            type: StaggeredListType.column,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.3),
                      boxShadow: [
                        BoxShadow(
                            color: isDarkMode(context)
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: AnimatedButton(
                            animationType: TapAnimationType.scale,
                            onTap: () {
                              if (Global.userData == null) {
                                GoRouter.of(context).push(AppRoutes.login);
                              } else {
                                if (AppHelpers.systemVendorTypeIsSingle) {
                                  final navigationShell = StatefulNavigationShell.of(context);
                                  navigationShell.goBranch(4);
                                } else {
                                  GoRouter.of(context).push(AppRoutes.myOrders);
                                }
                              }
                            },
                            child: QuickAction(
                                label: context.tr('myOrders', fallback: 'My Orders'), icon: TablerIcons.shopping_cart_filled)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: VerticalDivider(width: 0.8, color: Theme.of(context).colorScheme.outline),
                      ),
                      Expanded(
                        child: AnimatedButton(
                          animationType: TapAnimationType.scale,
                          onTap: () {
                            if (Global.userData == null) {
                              GoRouter.of(context).push(AppRoutes.login);
                            } else {
                              GoRouter.of(context).push(AppRoutes.coinsPage);
                            }
                          },
                          child: QuickAction(label: context.tr('coins', fallback: "Coins"), icon: Icons.copyright),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: VerticalDivider(width: 0.8, color: Theme.of(context).colorScheme.outline),
                      ),
                      Expanded(
                        child: AnimatedButton(
                            animationType: TapAnimationType.scale,
                            onTap: () {
                              if (Global.userData == null) {
                                GoRouter.of(context).push(AppRoutes.login);
                              } else {
                                GoRouter.of(context).push(AppRoutes.wallet);
                              }
                            },
                            child: QuickAction(label: context.tr('wallet', fallback: "Wallet"), icon: HeroiconsSolid.wallet)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (Global.userData != null) ...[
                ValueListenableBuilder(
                  // Listen only to the specific key — super efficient!
                  valueListenable: Hive.box<SelectedAddress>(AppHelpers.selectedAddressHiveBoxName)
                      .listenable(keys: [AppHelpers.selectedAddressHiveBoxKey]),

                  builder: (context, Box<SelectedAddress> box, _) {
                    final selectedAddressData = box.get(AppHelpers.selectedAddressHiveBoxKey);

                    return GestureDetector(
                      onTap: () async {
                        await GoRouter.of(context).push(AppRoutes.addressList);
                        // No need to call loadSelectedAddress() → Hive listener does it instantly!
                      },
                      child: SectionCard(
                        title: context.tr('yourDeliveryAddress', fallback: 'Your Delivery Address'),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          leading: iconBox(
                            TablerIcons.map_pin_filled,
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                          ),
                          title: Text(
                            selectedAddressData?.addressLine1?.isNotEmpty == true
                                ? selectedAddressData!.addressLine1!
                                : context.tr('pleaseAddYourDeliveryAddress', fallback: 'Please add your delivery address'),
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: const Icon(TablerIcons.edit, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
              // Settings Sections Grouped
              ValueListenableBuilder<String?>(
                valueListenable: Global.tokenNotifier,
                builder: (context, token, _) {
                  return Column(
                    children: [
                      SectionCard(
                        title: context.tr('activity', fallback: 'Activity'),
                        child: Column(
                          children: [
                            SettingsTile(
                              title: context.tr('shoppingList', fallback: "Shopping List"),
                              icon: TablerIcons.pencil,
                              onTap: () {
                                GoRouter.of(context).push(AppRoutes.shoppingList);
                              },
                            ),
                            customDivider(),
                            SettingsTile(
                              title: context.tr('wishlist', fallback: "Wishlist"),
                              icon: AppHelpers.notWishListedIcon,
                              isLast: token == null,
                              onTap: () {
                                if (Global.userData == null) {
                                  GoRouter.of(context).push(AppRoutes.login);
                                } else {
                                  GoRouter.of(context).push(AppRoutes.wishlistPage);
                                }
                              },
                            ),
                            if (token != null) ...[
                              customDivider(),
                              SettingsTile(
                                title: context.tr('savedForLater', fallback: "Save for later"),
                                icon: TablerIcons.archive,
                                onTap: () => GoRouter.of(context).push(AppRoutes.saveForLater),
                              ),
                              if (SettingsData.instance.system?.referEarnStatus == true) ...[
                                customDivider(),
                                SettingsTile(
                                  title: context.tr('referAndEarn', fallback: 'Refer and Earn'),
                                  icon: TablerIcons.moneybag,
                                  onTap: () => GoRouter.of(context).push(AppRoutes.referAndEarnPage),
                                ),
                              ],
                              customDivider(),
                              SettingsTile(
                                title: context.tr('orderTransaction', fallback: 'Order Transaction'),
                                icon: TablerIcons.transfer_in,
                                isLast: true,
                                onTap: () => GoRouter.of(context).push(AppRoutes.orderTransactionsPage),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Preferences ---
                      SectionCard(
                        title: context.tr('preferences', fallback: 'Preferences'),
                        child: Column(
                          children: [
                            BlocBuilder<ThemeBloc, ThemeMode>(
                              builder: (context, themeMode) {
                                final subtitle = themeMode == ThemeMode.dark
                                    ? context.tr('darkMode')
                                    : themeMode == ThemeMode.system
                                        ? context.tr('systemMode')
                                        : context.tr('lightMode');
                                return SettingsTile(
                                  title: context.tr('appearance', fallback: 'Appearance'),
                                  icon: TablerIcons.palette,
                                  subtitle: subtitle,
                                  onTap: () => AppearanceBottomSheet.show(context),
                                );
                              },
                            ),
                            customDivider(),
                            BlocBuilder<LanguageBloc, LanguageState>(
                              builder: (context, state) {
                                String currentLanguage = 'English';
                                if (state is LanguageLoaded) {
                                  final language = Global.supportedLanguages.firstWhere(
                                    (lang) => lang['code'] == state.languageCode,
                                    orElse: () => {'nativeName': 'English'},
                                  );
                                  currentLanguage = language['nativeName']!;
                                }
                                return SettingsTile(
                                  title: context.tr('language', fallback: "Language"),
                                  icon: TablerIcons.language,
                                  subtitle: "${context.tr('currentLanguage', fallback: 'Current')}: $currentLanguage",
                                  onTap: () => LanguageBottomSheet.show(context),
                                  onLongPress: () async {
                                    HapticFeedback.heavyImpact();
                                    final isEnabled = await Global.toggleHttpInspector();
                                    if (context.mounted) {
                                      ToastManager.show(
                                        context: context,
                                        message: isEnabled
                                            ? "Secret HTTP Inspector Enabled"
                                            : "Secret HTTP Inspector Disabled",
                                        type: isEnabled ? ToastType.success : ToastType.warning,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                            if (SettingsData.instance.app?.customerViewDeliveryZoneInfo == true) ...[
                              customDivider(),
                              SettingsTile(
                                title: context.tr('deliveryZones', fallback: 'Delivery Zones'),
                                icon: TablerIcons.map_search,
                                isLast: true,
                                onTap: () => GoRouter.of(context).push(AppRoutes.deliveryZoneList),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Support & Legal ---
                      SectionCard(
                        title: context.tr('supportAndLegal', fallback: 'Support & Legal'),
                        child: Column(
                          children: [
                            SettingsTile(
                                title: context.tr('support', fallback: "Support"),
                                icon: TablerIcons.headphones,
                                onTap: () {
                                  if (Global.userData == null) {
                                    GoRouter.of(context).push(AppRoutes.login);
                                  } else {
                                    GoRouter.of(context).push(AppRoutes.supportPage);
                                  }
                                }),
                            customDivider(),
                            SettingsTile(
                              title: context.tr('termsCondition', fallback: "Terms & Condition"),
                              icon: TablerIcons.info_circle,
                              onTap: () => GoRouter.of(context)
                                  .push(AppRoutes.policyPage, extra: {'policy-type': PolicyType.termsAndConditions}),
                            ),
                            customDivider(),
                            SettingsTile(
                              title: context.tr('privacyPolicy', fallback: "Privacy Policy"),
                              icon: TablerIcons.lock,
                              onTap: () => GoRouter.of(context)
                                  .push(AppRoutes.policyPage, extra: {'policy-type': PolicyType.privacyPolicy}),
                            ),
                            customDivider(),
                            SettingsTile(
                              title: context.tr('refundPolicy', fallback: "Refund Policy"),
                              icon: TablerIcons.rotate,
                              onTap: () => GoRouter.of(context)
                                  .push(AppRoutes.policyPage, extra: {'policy-type': PolicyType.refundPolicy}),
                            ),
                            customDivider(),
                            SettingsTile(
                              title: context.tr('shippingPolicy', fallback: "Shipping Policy"),
                              icon: HeroiconsOutline.truck,
                              onTap: () => GoRouter.of(context)
                                  .push(AppRoutes.policyPage, extra: {'policy-type': PolicyType.shippingPolicy}),
                            ),
                            customDivider(),
                            SettingsTile(
                              title: context.tr('aboutUs', fallback: "About us"),
                              icon: TablerIcons.info_circle,
                              isLast: true,
                              onTap: () => GoRouter.of(context)
                                  .push(AppRoutes.policyPage, extra: {'policy-type': PolicyType.aboutUs}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Account Actions ---
                      SectionCard(
                        title: context.tr('account', fallback: 'Account'),
                        child: Column(
                          children: [
                            if (token != null) ...[
                              SettingsTile(
                                title: context.tr('logout', fallback: "Logout"),
                                icon: TablerIcons.logout,
                                isLast: false,
                                onTap: () => _showLogoutConfirmationDialog(context),
                              ),
                              customDivider(),
                              SettingsTile(
                                title: context.tr('deleteAccount', fallback: "Delete Account"),
                                icon: TablerIcons.trash,
                                isLast: true,
                                onTap: () => _showDeleteAccountConfirmationDialog(context),
                              ),
                            ] else
                              SettingsTile(
                                title: context.tr('signIn', fallback: "Sign In"),
                                icon: TablerIcons.login,
                                isLast: true,
                                onTap: () => GoRouter.of(context).push(AppRoutes.login),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget customDivider() {
    return Divider(
        height: 0.5,
        color: isDarkMode(context) ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.outline);
  }

  void _showLogoutConfirmationDialog(BuildContext context) {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(TablerIcons.logout, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Text(context.tr('logout', fallback: "Logout")),
                ],
              ),
              content: Text(context.tr('logoutConfirmation', fallback: "Are you sure you want to log out?")),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    context.tr('cancel', fallback: "Cancel"),
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: isLoading
                      ? null // Disable button while loading
                      : () async {
                          setState(() => isLoading = true);

                          // Trigger logout
                          context.read<AuthBloc>().add(LogoutUserRequest());
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(context.tr('logout', fallback: 'Logout')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountConfirmationDialog(BuildContext context) {
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is DeleteUserSuccess || state is AuthFailed) {
              if (Navigator.of(dialogCtx, rootNavigator: true).canPop()) {
                Navigator.of(dialogCtx, rootNavigator: true).pop();
              }
            }
          },
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    Icon(TablerIcons.trash, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Text(
                      context.tr('deleteAccount', fallback: "Delete Account"),
                    ),
                  ],
                ),
                content: Text(
                  "${context.tr('thisActionIsPermanent')}\n${context.tr('allYourDataWillBeLostForever')}\n",
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
                    child: Text(context.tr('cancel', fallback: "Cancel")),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() => isLoading = true);

                            // Trigger delete account
                            context.read<AuthBloc>().add(DeleteUserAccount());
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(context.tr('delete'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

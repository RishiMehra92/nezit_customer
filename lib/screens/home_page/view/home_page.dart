import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:hyper_local/screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_event.dart';
import 'package:hyper_local/screens/home_page/home_layout/bloc/home_layout_bloc.dart';
import 'package:hyper_local/screens/home_page/home_layout/bloc/home_layout_event.dart';
import 'package:hyper_local/screens/home_page/home_layout/bloc/home_layout_state.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/global.dart';
import '../../../config/helper.dart';
import '../../../config/notification_service.dart';
import '../../../utils/widgets/custom_scaffold/custom_scaffold.dart';

import '../model/category_model.dart';
import '../widgets/animated_text_field.dart';
import '../bloc/category/category_state.dart';
import '../widgets/home_helpers.dart';
import '../../notification_page/bloc/notification_bloc.dart';
import '../widgets/sections/home_app_bar_section.dart';
import '../widgets/sections/home_top_address_section.dart';
import '../widgets/home_notification_action.dart';
import '../widgets/home_tab_content.dart';
import '../widgets/scroll_to_top_button.dart';
import '../widgets/home_flexible_space_background.dart';
import '../widgets/home_tab_bar.dart';
import '../widgets/home_tab_view_body.dart';
import '../widgets/home_referral_overlay.dart';
import '../widgets/tab_change_listener.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController nestedScrollController = ScrollController();
  final ValueNotifier<String> _backgroundImageNotifier =
      ValueNotifier<String>('');
  final ValueNotifier<String?> _backgroundColorNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<Color?> _textColorNotifier = ValueNotifier<Color?>(null);
  List<CategoryData> _categories = [];
  final ValueNotifier<bool> _isFlexibleSpaceHiddenNotifier =
      ValueNotifier<bool>(false);

  Color? _originalTextColor;
  String? _lastLocationIdentifier;
  String _tabBarViewKey = 'initial';
  int _previousCategoryLength = 0;
  double _appBarOpacity = 1.0;
  final ValueNotifier<bool> _isRetryNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<String>?> _searchHintNotifier =
      ValueNotifier<List<String>?>([]);
  final ValueNotifier<bool> _showViewCartNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _showBackToTopNotifier = ValueNotifier<bool>(false);
  int _lastApiCallTabIndex = 0;

  bool get _hasDeliveryLocation {
    try {
      final box = Hive.box<dynamic>('userLocationBox');
      return box.get('user_location') != null;
    } catch (_) {
      return false;
    }
  }

  bool get _isInitialLoading {
    if (!mounted) return false;
    final categoryState = context.read<CategoryBloc>().state;
    return categoryState is CategoryInitial || categoryState is CategoryLoading;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        NotificationService.handleNotificationNavigation(message.data);
      }
    });

    final cachedSettings = SettingsData.instance.homeGeneralSettings;
    if (cachedSettings != null && isValidHomeGeneralSettings(cachedSettings)) {
      final bgType = cachedSettings.backgroundType.toLowerCase();
      if (bgType == 'animation') {
        _backgroundImageNotifier.value =
            cachedSettings.backgroundAnimation ?? '';
      } else if (bgType == 'image') {
        _backgroundImageNotifier.value =
            cachedSettings.backgroundImage.isNotEmpty
                ? cachedSettings.backgroundImage
                : '';
      } else {
        _backgroundImageNotifier.value = '';
      }
      _backgroundColorNotifier.value = cachedSettings.backgroundColor.isNotEmpty
          ? cachedSettings.backgroundColor
          : null;
    }

    final categoryState = context.read<CategoryBloc>().state;
    if (categoryState is CategoryLoaded) {
      _categories = categoryState.categoryData;
      _previousCategoryLength = _categories.length;
    }

    nestedScrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyHomeGeneralSettingsToAppBar();
        context.read<UserProfileBloc>().add(FetchUserProfile());

        final box = Hive.box<dynamic>('userLocationBox');
        final storedLocation = box.get('user_location');
        if (storedLocation != null) {
          _lastLocationIdentifier =
              '${storedLocation.latitude}_${storedLocation.longitude}_${storedLocation.fullAddress}_${storedLocation.area}_${storedLocation.city}_${storedLocation.pincode}';
          
          // Always fetch home layout (which includes the 'All' static section)
          // regardless of whether the category API succeeds or fails.
          apiCalls('');
        } else {
          context.read<CategoryBloc>().add(FetchCategory(context: context));
          apiCalls('');
        }
      }
    });
    _searchHintNotifier.value = removeUnderscoresFromStringList(
        SettingsData.instance.homeGeneralSettings?.searchLabels ?? []);
  }

  void updateAppBarBackground(
      {String? image,
      String? bgColor,
      Color? fontColor,
      List<String>? searchHintTextList}) {
    _backgroundImageNotifier.value = image ?? '';
    _backgroundColorNotifier.value = bgColor;
    _originalTextColor = fontColor;
    _searchHintNotifier.value = searchHintTextList;
    _textColorNotifier.value = _originalTextColor;
  }

  void _onTabChanged(int index) {
    if (_lastApiCallTabIndex == index) return;
    _lastApiCallTabIndex = index;

    if (index == 0) {
      apiCalls('', fetchSupportData: false);
      _applyHomeGeneralSettingsToAppBar();
    } else if (index > 0 && index - 1 < _categories.length) {
      final category = _categories[index - 1];
      apiCalls(category.slug ?? '', fetchSupportData: false);
      _applyCategoryAppBar(category);
    }
    scrollToTop();
  }

  void apiCalls(String slug,
      {bool isRefresh = false, Completer<void>? completer, bool fetchSupportData = true}) async {
    final updatedSlug = (_lastApiCallTabIndex != 0) ? slug : '';

    // Consolidated Home API call via HomeLayoutBloc
    context.read<HomeLayoutBloc>().add(FetchHomeLayout(
          categorySlug: updatedSlug,
          isRefresh: isRefresh,
          completer: completer,
        ));

    if (fetchSupportData) {
      // Other support calls
      context.read<GetUserCartBloc>().add(FetchUserCart());
      context.read<GetAddressListBloc>().add(FetchUserAddressList());
      context.read<NotificationBloc>().add(FetchNotifications());

      await Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.read<SettingsBloc>().add(FetchSettingsData(context: context));
        }
      });
    }
  }

  void _refreshDataForCurrentTab() {
    if (_lastApiCallTabIndex == 0) {
      apiCalls('');
    } else if (_categories.isNotEmpty &&
        (_lastApiCallTabIndex - 1) < _categories.length) {
      final selectedCategory = _categories[_lastApiCallTabIndex - 1];
      apiCalls(selectedCategory.slug ?? '');
    } else {
      apiCalls('');
    }
  }

  void _refreshApiOnLocationChange() {
    context.read<CategoryBloc>().add(FetchCategory(context: context));
    if (!AppHelpers.systemVendorTypeIsSingle) {
      context
          .read<NearByStoreBloc>()
          .add(const FetchNearByStores(perPage: 15, searchQuery: ''));
    }
  }

  void _scrollListener() {
    double expandedHeight = 100.0.h;
    const double toolbarHeight = kToolbarHeight;
    final double flexibleSpaceHeight = expandedHeight - toolbarHeight;
    final double currentOffset = nestedScrollController.offset;
    final bool isHidden = currentOffset >= (flexibleSpaceHeight - 10);
    _appBarOpacity = (1 - (currentOffset / expandedHeight)).clamp(0.0, 1.0);
    if (_isFlexibleSpaceHiddenNotifier.value != isHidden) {
      _isFlexibleSpaceHiddenNotifier.value = isHidden;
    }
  }

  @override
  void dispose() {
    nestedScrollController.removeListener(_scrollListener);
    nestedScrollController.dispose();
    _showBackToTopNotifier.dispose();
    _backgroundImageNotifier.dispose();
    _backgroundColorNotifier.dispose();
    _searchHintNotifier.dispose();
    _textColorNotifier.dispose();
    _isFlexibleSpaceHiddenNotifier.dispose();
    _isRetryNotifier.dispose();
    _showViewCartNotifier.dispose();
    super.dispose();
  }

  void _applyHomeGeneralSettingsToAppBar() {
    final settings = SettingsData.instance.homeGeneralSettings;
    final bgType = (settings?.backgroundType ?? 'color').toLowerCase();
    // Always recompute home search labels from the latest settings so the
    // hint refreshes when switching back from a category tab to "All".
    final List<String> homeSearchLabels = removeUnderscoresFromStringList(
      settings?.searchLabels ?? [],
    );

    if (settings == null || !isValidHomeGeneralSettings(settings)) {
      updateAppBarBackground(
        image: '',
        bgColor: null,
        fontColor: null,
        searchHintTextList: homeSearchLabels,
      );
      return;
    }

    final String image = bgType == 'animation'
        ? (settings.backgroundAnimation ?? '')
        : (settings.backgroundImage.isNotEmpty ? settings.backgroundImage : '');
    final String? bgColor =
        settings.backgroundColor.isNotEmpty ? settings.backgroundColor : null;
    final Color? fontColor = settings.fontColor.isNotEmpty
        ? hexStringToColor(settings.fontColor)
        : null;

    updateAppBarBackground(
      image: bgType == 'animation' || bgType == 'image' ? image : null,
      bgColor: bgColor,
      fontColor: fontColor,
      searchHintTextList: homeSearchLabels,
    );
  }

  void _handleLocationChange(String? locationIdentifier) {
    if (_lastLocationIdentifier == locationIdentifier) return;
    _lastLocationIdentifier = locationIdentifier;
    _refreshApiOnLocationChange();
    _refreshDataForCurrentTab();
  }

  void _applyCategoryAppBar(CategoryData category) {
    final bgType = (category.backgroundType ?? 'color').toLowerCase();
    final String? image = bgType == 'animation'
        ? category.backgroundAnimation
        : (bgType == 'image'
            ? (category.backgroundImage ?? category.banner)
            : null);
    updateAppBarBackground(
      image: image,
      bgColor: category.backgroundColor,
      fontColor: hexStringToColor(category.fontColor),
      // Mirror the home tab's transformation so category labels render
      // without underscores.
      searchHintTextList:
          removeUnderscoresFromStringList(category.searchLabels ?? []),
    );
  }

  Widget _buildHomeTabContent({required String categorySlug}) {
    return HomeTabContent(
      categorySlug: categorySlug,
      onRefresh: () async {
        final completer = Completer<void>();
        apiCalls(categorySlug, isRefresh: true, completer: completer);
        if (categorySlug.isEmpty) {
          _applyHomeGeneralSettingsToAppBar();
        } else {
          final category = _categories.firstWhere(
            (item) => item.slug == categorySlug,
            orElse: () => CategoryData(),
          );
          _applyCategoryAppBar(category);
        }
        context.read<CategoryBloc>().add(FetchCategory(context: context));
        await completer.future;
      },
      onRetry: () {
        apiCalls(categorySlug);
      },
    );
  }

  Widget _buildNotificationAction(Color? currentTextColor) {
    return HomeNotificationAction(textColor: currentTextColor);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<CategoryBloc, CategoryState>(
          listener: (context, state) => _handleCategoryUpdate(state),
        ),
        BlocListener<GetUserCartBloc, GetUserCartState>(
          listener: (context, state) {},
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsLoaded && mounted) {
              if (_lastApiCallTabIndex == 0) {
                _applyHomeGeneralSettingsToAppBar();
              }
            }
          },
        ),
      ],
      child: CustomScaffold(
        showViewCartNotifier: _showViewCartNotifier,
        onConnectivityRestored: (context) async {
          context.read<CartBloc>().add(SyncLocalCart(context: context));
          _refreshDataForCurrentTab();
        },
        body: Stack(
          children: [
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (BuildContext context, CategoryState state) {
                final activeCategories =
                    state is CategoryLoaded ? state.categoryData : _categories;
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis == Axis.vertical) {
                      final totalScroll = notification.metrics.pixels +
                          nestedScrollController.offset;

                      if (totalScroll <= 400) {
                        _showBackToTopNotifier.value = false;
                      } else if (notification is UserScrollNotification) {
                        if (notification.direction == ScrollDirection.reverse) {
                          _showBackToTopNotifier.value = false;
                        } else if (notification.direction ==
                            ScrollDirection.forward) {
                          _showBackToTopNotifier.value = true;
                        }
                      }
                    }

                    return false;
                  },
                  child: DefaultTabController(
                    length: activeCategories.length + 1,
                    child: TabChangeListener(
                      onTabChanged: _onTabChanged,
                      child: NestedScrollViewPlus(
                        overscrollBehavior: OverscrollBehavior.inner,
                        controller: nestedScrollController,
                        headerSliverBuilder:
                            (BuildContext context, bool innerBoxIsScrolled) {
                          return [
                            ValueListenableBuilder<bool>(
                              valueListenable: _isFlexibleSpaceHiddenNotifier,
                              builder: (context, isHidden, _) {
                                return ValueListenableBuilder<Color?>(
                                  valueListenable: _textColorNotifier,
                                  builder: (context, currentTextColor, _) {
                                    return ValueListenableBuilder<String>(
                                      valueListenable: _backgroundImageNotifier,
                                      builder: (context, bgImagePath, _) {
                                        return ValueListenableBuilder<String?>(
                                          valueListenable:
                                              _backgroundColorNotifier,
                                          builder: (context, bgColor, _) {
                                            return ValueListenableBuilder<
                                                List<String>?>(
                                              valueListenable:
                                                  _searchHintNotifier,
                                              builder:
                                                  (context, searchHints, _) {
                                                return HomeAppBarSection(
                                                  canUseTabController: true,
                                                  appBarOpacity: _appBarOpacity,
                                                  textColor: currentTextColor,
                                                  title: AnimatedOpacity(
                                                    opacity:
                                                        isHidden ? 0.0 : 1.0,
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    child:
                                                        HomeTopAddressSection(
                                                      textColor:
                                                          currentTextColor,
                                                      onLocationChanged:
                                                          _handleLocationChange,
                                                    ),
                                                  ),
                                                  flexibleSpaceBackground:
                                                      HomeFlexibleSpaceBackground(
                                                    isImageEmpty:
                                                        bgImagePath.isEmpty,
                                                    backgroundImagePath:
                                                        bgImagePath,
                                                    backgroundColor: bgColor,
                                                  ),
                                                  searchField:
                                                      CustomAnimatedTextField(
                                                    key: ValueKey(
                                                      searchHints?.join('|') ??
                                                          '',
                                                    ),
                                                    searchHintTextList:
                                                        searchHints,
                                                    isCollapsed: isHidden,
                                                  ),
                                                  tabBar: HomeTabBar(
                                                    categories:
                                                        activeCategories,
                                                    textColor: currentTextColor,
                                                  ),
                                                  notificationsAction: Global
                                                              .userData !=
                                                          null
                                                      ? _buildNotificationAction(
                                                          currentTextColor)
                                                      : null,
                                                  isDarkMode:
                                                      isDarkMode(context),
                                                  darkBackgroundColor: AppTheme
                                                      .darkProductCardColor,
                                                  appBarColor:
                                                      hexStringToColor(bgColor),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: _isRetryNotifier,
                              builder: (context, retry, _) {
                                return retry
                                    ? const SliverToBoxAdapter()
                                    : const SliverToBoxAdapter(
                                        child: SizedBox.shrink());
                              },
                            )
                          ];
                        },
                        body: ValueListenableBuilder<bool>(
                            valueListenable: _isRetryNotifier,
                            builder: (context, retry, _) {
                              return HomeTabViewBody(
                                isInitialLoading: _isInitialLoading,
                                isRecreatingTabController: false,
                                hasDeliveryLocation: _hasDeliveryLocation,
                                categories: activeCategories,
                                tabContentBuilder: (categorySlug) =>
                                    _buildHomeTabContent(
                                        categorySlug: categorySlug),
                                tabBarViewKey: _tabBarViewKey,
                                isRetry: retry,
                                onLoadMore: () => _loadMoreForCurrentTab(
                                    _lastApiCallTabIndex),
                                onRetryLocation: () =>
                                    showHomeLocationBottomSheet(context),
                              );
                            }),
                      ),
                    ),
                  ),
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isRetryNotifier,
              builder: (context, retry, _) {
                if (retry) {
                  return const Positioned.fill(
                    child: ColoredBox(color: Colors.white),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            HomeReferralOverlay(
              onVisibilityChanged: (isVisible) {
                if (mounted && _showViewCartNotifier.value == isVisible) {
                  _showViewCartNotifier.value = !isVisible;
                }
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showBackToTopNotifier,
              builder: (context, showBackToTop, child) {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: showBackToTop
                      ? (isTablet(context) ? 100 : 165).h
                      : (isTablet(context) ? 90 : 150).h,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: showBackToTop ? 1.0 : 0.0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: IgnorePointer(
                        ignoring: !showBackToTop,
                        child: ScrollToTopButton(
                          onScrollToTop: scrollToTop,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _loadMoreForCurrentTab(int tabIndex) {
    final state = context.read<HomeLayoutBloc>().state;
    if (state is HomeLayoutLoaded &&
        !state.hasReachedMax &&
        !state.isLoadingMore) {
      context.read<HomeLayoutBloc>().add(const FetchMoreHomeLayout());
    }
  }

  void scrollToTop() {
    _showBackToTopNotifier.value = false;
    if (nestedScrollController.hasClients) {
      nestedScrollController.animateTo(0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic);
    }
  }

  void _handleCategoryUpdate(CategoryState state) {
    if (state is CategoryLoaded) {
      for (final category in state.categoryData) {
        final banner = category.banner ?? '';
        if (banner.startsWith('http')) {
          precacheImage(NetworkImage(banner), context);
        }
      }

      if (_isRetryNotifier.value) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _isRetryNotifier.value = false;
        });
      }

      final newCategories = state.categoryData;

      if (_previousCategoryLength != newCategories.length) {
        setState(() {
          _tabBarViewKey = 'recreated_${DateTime.now().millisecondsSinceEpoch}';
        });
      }

      _previousCategoryLength = newCategories.length;
      _categories = newCategories;
    } else if (state is CategoryFailed && _isRetryNotifier.value) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _isRetryNotifier.value = false;
      });
    }
  }
}

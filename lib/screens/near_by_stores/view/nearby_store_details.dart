import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import '../bloc/store_reels/store_reels_bloc.dart';
import '../bloc/store_reels/store_reels_event.dart';
import '../bloc/store_reels/store_reels_state.dart';
import '../bloc/store_stories/store_stories_bloc.dart';
import '../bloc/store_stories/store_stories_event.dart';
import '../repo/near_by_store_repo.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/screens/discover_page/widgets/discover_grid_card.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../widgets/store_header_widget.dart';
import '../widgets/store_notify_button.dart';
import '../widgets/store_status_helper.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/model/sorting_model/sorting_model.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/store_detail/store_detail_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/filter/filter_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/filter/filter_event.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/product_listing/product_listing_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/model/product_listing_type.dart';
import 'package:hyper_local/screens/product_listing_page/widgets/custom_filter_sort_btn_widget.dart';
import 'package:hyper_local/utils/widgets/bottom_variant_selector_with_addons.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_product_card.dart';

import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations_plus/flutter_staggered_animations_plus.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/custom_sorting_bottom_sheet.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/helper.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../utils/widgets/custom_filter_bottom_sheet.dart';
import '../../ad_campaign/bloc/ad_click_bloc/ad_click_bloc.dart';
import '../../ad_campaign/widgets/ad_visibility_observer.dart';

class NearbyStoreDetails extends StatelessWidget {
  final String storeSlug;
  final String storeName;

  const NearbyStoreDetails({
    super.key,
    required this.storeSlug,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => StoreDetailBloc()..add(FetchStoreDetail(storeSlug: storeSlug)),
        ),
        BlocProvider(
          create: (_) => ProductListingBloc()
            ..add(
              FetchListingProducts(
                type: ProductListingType.store,
                storeSlug: storeSlug,
                identifier: storeSlug,
              ),
            ),
        ),
        BlocProvider(
          create: (_) => StoreReelsBloc(repository: NearByStoreRepo())..add(FetchStoreReels(storeSlug: storeSlug)),
        ),
        BlocProvider(
          create: (_) => StoreStoriesBloc(repository: NearByStoreRepo())..add(FetchStoreStories(storeSlug: storeSlug)),
        ),
      ],
      child: _NearbyStoreDetailsView(
        storeSlug: storeSlug,
        storeName: storeName,
      ),
    );
  }
}

class _NearbyStoreDetailsView extends StatefulWidget {
  final String storeSlug;
  final String storeName;

  const _NearbyStoreDetailsView({
    required this.storeSlug,
    required this.storeName,
  });

  @override
  State<_NearbyStoreDetailsView> createState() => _NearbyStoreDetailsState();
}

class _NearbyStoreDetailsState extends State<_NearbyStoreDetailsView> {
  final TextEditingController _searchController = TextEditingController();

  bool isSearchInStore = false;
  bool isSubmitted = false;

  @override
  void initState() {
    super.initState();

    context.read<FilterBloc>().add(ClearAllFilters());
  }

  void _showFilterBottomSheet({required List<int> categoryIds, required List<int> brandsIds}) {
    CustomFilterBottomSheet.show(
      context: context,
      listingType: ProductListingType.store,
      categoryIds: categoryIds,
      brandsIds: brandsIds,
      value: widget.storeSlug,
      onApplyFilters: (category, brands, attribute) {
        final categorySlugs = category.map((e) => e.slug ?? '').toList();
        final brandSlugs = brands.map((e) => e.slug ?? '').toList();
        final attributeIds = attribute.map((e) => e.id!).toList();
        context.read<ProductListingBloc>().add(FetchFilteredListingProducts(
              type: ProductListingType.store,
              identifier: widget.storeSlug,
              categorySlugs: categorySlugs,
              brandSlugs: brandSlugs,
              attributeIds: attributeIds,
            ));
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySorting(SortOption sortOption) {
    context.read<ProductListingBloc>().add(
          FetchSortedListingProducts(
            type: ProductListingType.store,
            storeSlug: widget.storeSlug,
            identifier: _searchController.text.trim(),
            sortType: sortOption.apiValue,
            isSearchInStore: isSearchInStore,
          ),
        );
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    isSearchInStore = query.isNotEmpty;

    context.read<ProductListingBloc>().add(
          FetchListingProducts(
            type: ProductListingType.store,
            storeSlug: widget.storeSlug,
            identifier: query,
            isSearchInStore: isSearchInStore,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        elevation: 0,
        title: _buildSearchBar(),
        titleSpacing: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: isDarkMode(context) ? Colors.grey.shade800 : Colors.grey.shade300, height: 1),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      margin: const EdgeInsetsGeometry.directional(end: 12),
      child: CustomTextFormField(
        controller: _searchController,
        hintText: context.tr('searchInStore', positionalArgs: [widget.storeName], fallback: 'Search in ${widget.storeName}'),
        suffixIcon: _searchController.text.isNotEmpty ? Icons.close : Icons.search,
        onSuffixIconTap: () {
          setState(() {
            if (isSubmitted) {
              isSubmitted = false;
              isSearchInStore = false;
              _searchController.clear();
              _performSearch();
            } else if (_searchController.text.isNotEmpty) {
              isSearchInStore = true;
              isSubmitted = true;
              _performSearch();
            }
          });
          FocusScope.of(context).unfocus();
        },
        onFieldSubmitted: (_) {
          setState(() {
            isSearchInStore = _searchController.text.trim().isNotEmpty;
            isSubmitted = true;
          });
          _performSearch();
        },
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<StoreDetailBloc, StoreDetailState>(
      listener: (context, state) {},
      builder: (context, storeState) {
        if (storeState is StoreDetailLoading) {
          return const CustomCircularProgressIndicator();
        }
        if (storeState is StoreDetailFailed) {
          return NoProductPage(onRetry: _performSearch);
        }
        if (storeState is StoreDetailLoaded) {
          return _buildScrollableContent(storeState.storeData);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildScrollableContent(StoreData store) {
    return DefaultTabController(
      length: 2,
      child: BlocBuilder<ProductListingBloc, ProductListingState>(
        builder: (context, productState) {
          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.axis == Axis.vertical &&
                  scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                final state = context.read<ProductListingBloc>().state;
                if (state is ProductListingLoaded && !state.hasReachedMax) {
                  context.read<ProductListingBloc>().add(
                        FetchMoreListingProducts(
                          type: ProductListingType.store,
                          storeSlug: widget.storeSlug,
                          identifier: _searchController.text.trim(),
                          isSearchInStore: isSearchInStore,
                        ),
                      );
                }

                final reelsState = context.read<StoreReelsBloc>().state;
                if (reelsState.status == ApiStatus.success && !reelsState.hasReachedMax) {
                  context.read<StoreReelsBloc>().add(
                        FetchStoreReels(
                          storeSlug: widget.storeSlug,
                          isLoadMore: true,
                        ),
                      );
                }
              }
              return false;
            },
            child: NestedScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildAnimatedSliverAdapter(
                      0,
                      StoreHeaderWidget(
                        store: store,
                        distance: store.distance ?? 0.0,
                        rating: store.avgStoreRating ?? '0.0',
                        totalStoreFeedback: store.totalStoreFeedback ?? 0,
                      )),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)), // Give a small natural padding
                  _buildAnimatedSliverAdapter(1, _buildStoreInfo(store, store.distance ?? 0.0)),
                  SliverToBoxAdapter(
                    child: Container(
                      height: 5,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        indicator: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        splashBorderRadius: BorderRadius.circular(25),
                        tabs: [
                          Tab(text: context.tr('products', fallback: "Products")),
                          Tab(text: context.tr('reels', fallback: "Reels")),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  AnimationLimiter(
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 10)),
                        ..._buildProductsSlivers(productState),
                      ],
                    ),
                  ),
                  _buildReelsTab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReelsTab() {
    return BlocBuilder<StoreReelsBloc, StoreReelsState>(
      builder: (context, state) {
        if (state.status == ApiStatus.initial || state.status == ApiStatus.loading) {
          return const CustomCircularProgressIndicator();
        } else if (state.status == ApiStatus.failure) {
          return Center(
            child: Text(state.errorMessage ?? 'Failed to load reels', style: const TextStyle(color: Colors.red)),
          );
        }

        final reelsItems = state.items;
        if (reelsItems.isEmpty) {
          return NoReelPage(
            onRetry: () {
              context.read<StoreReelsBloc>().add(FetchStoreReels(
                    storeSlug: widget.storeSlug,
                    isRefresh: true,
                  ));
            },
          );
        }

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: StaggeredListAnimator.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: reelsItems.length,
                type: StaggeredListType.masonryGridView,
                padding: const EdgeInsets.only(top: 8, left: 8, bottom: 40, right: 8),
                duration: const Duration(milliseconds: 375),
                verticalOffset: 50.0,
                spacing: 7,
                itemBuilder: (context, index) {
                  final item = reelsItems[index];
                  return DiscoverGridCard(
                    item: item,
                    index: index,
                    reelsItems: reelsItems,
                    onLikeToggled: () {
                      // Not implemented yet
                    },
                  );
                },
              ),
            ),
            if (state.isLoadMoreLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: CustomCircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedSliverAdapter(int index, Widget child) {
    return SliverToBoxAdapter(
      child: AnimationConfiguration.staggeredList(
        position: index,
        duration: const Duration(milliseconds: 300),
        child: SlideAnimation(
          verticalOffset: 40.0,
          curve: Curves.easeOutCubic,
          child: FadeInAnimation(child: child),
        ),
      ),
    );
  }

  Widget _buildStoreInfo(StoreData store, double distance) {
    final bool isClosed = StoreStatusHelper.isClosed(store, context);
    final String statusText = StoreStatusHelper.getStatusText(store, context);
    final Color statusColor = StoreStatusHelper.getStatusColor(statusText, context);
    final bool isDark = isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  store.name ?? "Unknown Store",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Only show notify me button if store is closed
              if (store.id != null && isClosed) ...[
                const SizedBox(width: 8),
                StoreNotifyButton(store: store),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(store.address ?? "No address",
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey[600]))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.shade900.withValues(alpha: 0.35)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: isDark
                      ? Border.all(
                          color: Colors.green.shade700.withValues(alpha: 0.3),
                          width: 0.8,
                        )
                      : null,
                ),
                child: Text('${distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.green.shade300 : Colors.green.shade700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (store.contactNumber?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse('tel:${store.contactNumber}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    store.contactNumber!,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
          if (store.contactEmail?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse('mailto:${store.contactEmail}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      store.contactEmail!,
                      style:
                          TextStyle(fontSize: 13, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              if (store.operatingHours != null)
                GestureDetector(
                  onTap: () => _showStoreHoursBottomSheet(store.operatingHours!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.tr('storeHours', fallback: 'Store Hours'),
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStoreHoursBottomSheet(OperatingHours hours) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('storeOperationalHours', fallback: 'Store Operational Hours'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDayHourRow(context.tr('monday', fallback: 'Monday'), hours.monday),
              _buildDayHourRow(context.tr('tuesday', fallback: 'Tuesday'), hours.tuesday),
              _buildDayHourRow(context.tr('wednesday', fallback: 'Wednesday'), hours.wednesday),
              _buildDayHourRow(context.tr('thursday', fallback: 'Thursday'), hours.thursday),
              _buildDayHourRow(context.tr('friday', fallback: 'Friday'), hours.friday),
              _buildDayHourRow(context.tr('saturday', fallback: 'Saturday'), hours.saturday),
              _buildDayHourRow(context.tr('sunday', fallback: 'Sunday'), hours.sunday),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayHourRow(String day, DayOperatingHours? dayHours) {
    String timing = context.tr('closedText');
    if (dayHours != null && dayHours.isOpen == true) {
      if (dayHours.openTime != null && dayHours.closeTime != null) {
        try {
          final timeFormat = DateFormat("HH:mm");
          final openTime = timeFormat.parse(dayHours.openTime!);
          final closeTime = timeFormat.parse(dayHours.closeTime!);
          final outFormat = DateFormat.jm();
          final now = DateTime.now();
          final oDate = DateTime(now.year, now.month, now.day, openTime.hour, openTime.minute);
          final cDate = DateTime(now.year, now.month, now.day, closeTime.hour, closeTime.minute);

          timing = '${outFormat.format(oDate)} - ${outFormat.format(cDate)}';

          if (dayHours.hasBreak == true && dayHours.breakStartTime != null && dayHours.breakEndTime != null) {
            final breakStart = timeFormat.parse(dayHours.breakStartTime!);
            final breakEnd = timeFormat.parse(dayHours.breakEndTime!);
            final bsDate = DateTime(now.year, now.month, now.day, breakStart.hour, breakStart.minute);
            final beDate = DateTime(now.year, now.month, now.day, breakEnd.hour, breakEnd.minute);
            timing += '\nBreak: ${outFormat.format(bsDate)} - ${outFormat.format(beDate)}';
          }
        } catch (e) {
          timing = '${dayHours.openTime} - ${dayHours.closeTime}';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(timing,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14, color: timing == context.tr('closedText') ? Colors.red : null)),
        ],
      ),
    );
  }

  List<Widget> _buildProductsSlivers(ProductListingState state) {
    if (state is ProductListingFailed) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(height: isTablet(context) ? 1000 : 500, child: const Center(child: NoProductPage())),
        )
      ];
    }

    List<Widget> slivers = [];

    if (state is ProductListingLoaded) {
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 10, bottom: 10),
            child: Row(
              children: [
                CustomFilterSortBtnWidget(
                  onTap: () =>
                      _showFilterBottomSheet(categoryIds: state.categoryIds ?? [], brandsIds: state.brandIds ?? []),
                  buttonName: context.tr('filter', fallback: 'Filter'),
                  iconData: RemixIcons.equalizer_3_line,
                ),
                const SizedBox(width: 10),
                CustomFilterSortBtnWidget(
                  onTap: _showSortBottomSheet,
                  buttonName: context.tr('sort', fallback: 'Sort'),
                  iconData: HeroiconsOutline.arrowsUpDown,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is ProductListingLoading || (state is ProductListingLoaded && state.isFilterLoading)) {
      slivers.add(
        SliverToBoxAdapter(
          child: SizedBox(
              height: isTablet(context) ? 1000 : 500, child: const Center(child: CustomCircularProgressIndicator())),
        ),
      );
    } else if (state is ProductListingLoaded) {
      if (state.productList.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: NoProductPage(onRetry: _performSearch),
          ),
        );
      } else {
        slivers.add(_buildProductSliverGrid(state.productList, state.hasReachedMax));
      }
    }

    return slivers;
  }

  Widget _buildProductSliverGrid(List<ProductData> productData, bool hasReachedMax) {
    final totalCount = hasReachedMax ? productData.length : productData.length + 3;
    return SliverPadding(
      padding: EdgeInsets.only(left: 14.w, right: 7.w, top: 8.h, bottom: 8.h),
      sliver: SliverAlignedGrid.count(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        itemCount: totalCount,
        itemBuilder: (context, index) {
          final child = _buildGridItem(productData, index, hasReachedMax);
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 300),
            columnCount: 3,
            child: SlideAnimation(
              verticalOffset: 40.0,
              curve: Curves.easeOutCubic,
              child: FadeInAnimation(child: child),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridItem(List<ProductData> productData, int index, bool hasReachedMax) {
    if (index >= productData.length) return productShimmer();
    final product = productData[index];
    final variant = product.variants.isNotEmpty ? product.variants.first : ProductVariants();

    final card = CustomProductCard(
      productId: product.id,
      productImage: product.mainImage,
      productImages: [
        product.mainImage,
        ...product.additionalImages,
        ...product.variants.map((v) => v.image),
      ].where((img) => img.isNotEmpty).toSet().toList(),
      productName: product.title,
      productSlug: product.slug,
      relatedProductSlugs: productData.map((e) => e.slug).toList(),
      initialIndex: index,
      productPrice: variant.price.toString(),
      specialPrice: variant.specialPrice.toString(),
      productTags: const [],
      estimatedDeliveryTime: product.estimatedDeliveryTime,
      ratings: product.ratings.toDouble(),
      ratingCount: product.ratingCount,
      isSponsored: product.isSponsored,
      onCardTap: product.isSponsored
          ? () => context.read<AdClickBloc>().add(RecordClick(
                campaignId: product.campaignId,
                visitorKey: product.visitorKey,
              ))
          : null,
      onAddToCart: () {
        if (product.variants.length > 1 || product.variants.any((v) => v.addonGroups.isNotEmpty == true)) {
          showVariantBottomSheetWithAddons(
            variantsList: product.variants,
            productData: product,
            productImage: product.mainImage,
            quantityStepSize: product.quantityStepSize,
            context: context,
          );
        } else {
          final item = UserCart(
              productId: product.id.toString(),
              variantId: product.variants.firstWhere((variant) => variant.isDefault).id.toString(),
              variantName: product.variants.firstWhere((variant) => variant.isDefault).title.toString(),
              vendorId: product.variants.firstWhere((variant) => variant.isDefault).storeId.toString(),
              name: product.title,
              image: product.mainImage,
              price: product.variants.firstWhere((variant) => variant.isDefault).specialPrice.toDouble(),
              originalPrice: product.variants.firstWhere((variant) => variant.isDefault).price.toDouble(),
              quantity: product.quantityStepSize,
              serverCartItemId: null,
              syncAction: CartSyncAction.add,
              updatedAt: DateTime.now(),
              minQty: product.minimumOrderQuantity,
              maxQty: product.totalAllowedQuantity,
              isOutOfStock: product.variants.firstWhere((variant) => variant.isDefault).stock <= 0,
              isSynced: false,
              currencyCode: product.variants.firstWhere((variant) => variant.isDefault).currencyCode,
          );
          context.read<CartBloc>().add(AddToCart(item: item, context: context));
        }
      },
      variantCount: product.variants.length,
      onVariantSelectorRequested: product.variants.length > 1
          ? () => showVariantBottomSheetWithAddons(
                variantsList: product.variants,
                productData: product,
                productImage: product.mainImage,
                quantityStepSize: product.quantityStepSize,
                context: context,
              )
          : null,
      isStoreOpen: product.storeStatus?.isOpen ?? true,
      isWishListed: product.favorite.isNotEmpty,
      productVariantId: variant.id,
      storeId: variant.storeId,
      wishlistItemId: product.favorite.isNotEmpty ? product.favorite.first.id ?? 0 : 0,
      totalStocks: variant.stock,
      imageFit: product.imageFit,
      quantityStepSize: product.quantityStepSize,
      minQty: product.minimumOrderQuantity,
      totalAllowedQuantity: product.totalAllowedQuantity,
      badge: product.badge,
    );

    if (product.isSponsored && product.campaignId > 0) {
      return AdVisibilityObserver(
        campaignId: product.campaignId,
        visitorKey: product.visitorKey,
        child: card,
      );
    }

    return card;
  }

  Widget productShimmer() {
    return Column(
      children: [
        ShimmerWidget.rectangular(
          height: 130,
          width: 130,
          borderRadius: 15,
          isBorder: true,
        ),
        const SizedBox(height: 10),
        ShimmerWidget.rectangular(isBorder: false, height: 15, width: 130, borderRadius: 15),
      ],
    );
  }

  void _showSortBottomSheet() {
    final currentState = context.read<ProductListingBloc>().state;
    final currentSortType = currentState is ProductListingLoaded ? currentState.currentSortType : SortType.relevance;

    CustomSortBottomSheet.show(
        context: context, currentSortType: currentSortType, onSortSelected: _applySorting, isFromStore: true);
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  double get minExtent => tabBar.preferredSize.height + 16;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

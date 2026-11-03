import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations_plus/flutter_staggered_animations_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/ad_campaign/bloc/ad_click_bloc/ad_click_bloc.dart';
import 'package:hyper_local/screens/ad_campaign/widgets/ad_visibility_observer.dart';
import 'package:hyper_local/utils/widgets/bottom_variant_selector_with_addons.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_product_card.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:remixicon/remixicon.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../model/sorting_model/sorting_model.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_circular_progress_indicator.dart';
import '../../../utils/widgets/custom_filter_bottom_sheet.dart';
import '../../../utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../../../utils/widgets/custom_sorting_bottom_sheet.dart';
import '../../home_page/bloc/sub_category/sub_category_bloc.dart';
import '../../home_page/bloc/sub_category/sub_category_state.dart';
import '../../home_page/model/category_model.dart';
import '../../product_detail_page/model/product_detail_model.dart';
import '../bloc/filter/filter_bloc.dart';
import '../bloc/filter/filter_event.dart';
import '../bloc/nested_category/nested_category_bloc.dart';
import '../bloc/product_listing/product_listing_bloc.dart';
import '../model/product_listing_type.dart';
import '../widgets/custom_filter_sort_btn_widget.dart';

class ProductListingPage extends StatefulWidget {
  final bool isTheirMoreCategory;
  final String title;
  final String totalProduct;
  final String logo;

  // New generic listing inputs
  final ProductListingType type;
  final String identifier;
  const ProductListingPage({
    super.key,
    required this.isTheirMoreCategory,
    required this.title,
    required this.totalProduct,
    required this.logo,
    this.type = ProductListingType.category,
    required this.identifier,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProductListingBloc(),
        ),
        BlocProvider(
          create: (context) => NestedCategoryBloc(),
        ),
        BlocProvider(
          create: (context) => FilterBloc(),
        ),
        BlocProvider(
          create: (context) => SubCategoryBloc(),
        ),
      ],
      child: _ProductListingView(
        isTheirMoreCategory: widget.isTheirMoreCategory,
        title: widget.title,
        totalProduct: widget.totalProduct,
        logo: widget.logo,
        type: widget.type,
        identifier: widget.identifier,
      ),
    );
  }
}

class _ProductListingView extends StatefulWidget {
  final bool isTheirMoreCategory;
  final String title;
  final String totalProduct;
  final String logo;

  // New generic listing inputs
  final ProductListingType type;
  final String identifier;
  const _ProductListingView({
    required this.isTheirMoreCategory,
    required this.title,
    required this.totalProduct,
    required this.logo,
    this.type = ProductListingType.category,
    required this.identifier,
  });

  @override
  State<_ProductListingView> createState() => _ProductListingViewState();
}

class _ProductListingViewState extends State<_ProductListingView> {
  bool isDataFirstTime = false;
  CategoryData selectedSubcategory = CategoryData();
  Map<String, bool> selectedFilters = {};
  int selectedCategoryIndex = 0;
  int _currentSelectedIndex = 0;
  int totalProductsCount = 0;
  int? parentCategoryTotalCount;
  final ScrollController _sidebarScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  final ValueNotifier<List<String>> _productSlugsNotifier =
      ValueNotifier<List<String>>([]);

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    _mainScrollController.dispose();
    _productSlugsNotifier.dispose();
    super.dispose();
  }

  void _resetGridScroll() {
    if (_mainScrollController.hasClients) {
      _mainScrollController.jumpTo(0.0);
    }
  }

  void _scrollToIndex(int index) {
    if (!_sidebarScrollController.hasClients) return;
    const double itemHeight = 110.0;
    final screenHeight = MediaQuery.of(context).size.height;
    double targetOffset =
        (index * itemHeight) - (screenHeight / 2) + (itemHeight / 2);

    final maxScroll = _sidebarScrollController.position.maxScrollExtent;
    targetOffset = targetOffset.clamp(0.0, maxScroll > 0 ? maxScroll : 0.0);

    _sidebarScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool get _hasSubcategories {
    final nestedState = context.read<NestedCategoryBloc>().state;
    return nestedState is NestedCategoryLoaded &&
        nestedState.subCategoryData.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    isDataFirstTime = false;

    final currentState = context.read<ProductListingBloc>().state;
    // Always fetch if state is initial OR if type is not search
    if (currentState is ProductListingInitial ||
        widget.type != ProductListingType.search) {
      context.read<ProductListingBloc>().add(
            FetchListingProducts(
                type: widget.type,
                identifier: widget.identifier,
                sortType: 'default'),
          );
    }

    if (widget.type == ProductListingType.category) {
      context
          .read<NestedCategoryBloc>()
          .add(FetchNestedCategory(slug: widget.identifier));
    }
    _currentSelectedIndex = 0;

    context.read<FilterBloc>().add(ClearAllFilters());
  }

  int get selectedFilterCount {
    return selectedFilters.values.where((selected) => selected).length;
  }

  void _showSortBottomSheet() {
    final currentState = context.read<ProductListingBloc>().state;
    final currentSortType = currentState is ProductListingLoaded
        ? currentState.currentSortType
        : SortType.relevance;

    CustomSortBottomSheet.show(
      context: context,
      currentSortType: currentSortType,
      onSortSelected: (SortOption selectedSort) {
        _applySorting(selectedSort);
      },
    );
  }

  String _getCurrentIdentifier() {
    if (_currentSelectedIndex > 0 &&
        selectedSubcategory.slug != null &&
        selectedSubcategory.slug!.isNotEmpty) {
      return selectedSubcategory.slug!;
    }
    return widget.identifier;
  }

  void _applySorting(SortOption sortOption) {
    context.read<ProductListingBloc>().add(
          FetchSortedListingProducts(
            type: widget.type,
            identifier: _getCurrentIdentifier(),
            sortType: sortOption.apiValue,
          ),
        );
  }

  void _showFilterBottomSheet(
      {required List<int> categoryIds, required List<int> brandsIds}) {
    String filterValue = _getCurrentIdentifier();

    CustomFilterBottomSheet.show(
      context: context,
      listingType: widget.type,
      categoryIds: categoryIds,
      brandsIds: brandsIds,
      value: filterValue,
      onApplyFilters: (category, brands, attribute) {
        final categorySlugs = category.map((e) => e.slug ?? '').toList();
        final brandSlugs = brands.map((e) => e.slug ?? '').toList();
        final attributeIds = attribute.map((e) => e.id!).toList();
        context.read<ProductListingBloc>().add(FetchFilteredListingProducts(
              type: widget.type,
              identifier: filterValue,
              categorySlugs: categorySlugs,
              brandSlugs: brandSlugs,
              attributeIds: attributeIds,
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: false,
        title: BlocListener<SubCategoryBloc, SubCategoryState>(
          listener: (BuildContext context, SubCategoryState state) {
            if (state is SubCategoryLoaded) {
              selectedSubcategory = state.subCategoryData.first;
            }
          },
          child: BlocBuilder<ProductListingBloc, ProductListingState>(
            builder: (BuildContext context, ProductListingState state) {
              if (state is ProductListingLoaded) {
                final currentIdentifier =
                    _hasSubcategories && selectedSubcategory.slug != null
                        ? selectedSubcategory.slug
                        : widget.identifier;

                if (currentIdentifier == widget.identifier &&
                    parentCategoryTotalCount == null) {
                  parentCategoryTotalCount = state.totalProducts;
                }

                totalProductsCount = totalProductsCount != state.totalProducts
                    ? state.totalProducts
                    : totalProductsCount;
                return Row(
                  children: [
                    if (widget.type != ProductListingType.store &&
                        widget.type != ProductListingType.search &&
                        widget.type != ProductListingType.featuredSection)
                      Container(
                        height: 45,
                        width: 45,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: CustomImageContainer(
                          imagePath: widget.logo,
                          height: 35,
                          fit: BoxFit.contain,
                        ),
                      ),
                    if (widget.type != ProductListingType.store &&
                        widget.type != ProductListingType.search)
                      const SizedBox(
                        width: 10,
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                              fontSize: isTablet(context) ? 18 : 14.sp,
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$totalProductsCount items',
                          style: TextStyle(
                            fontSize: isTablet(context) ? 14 : 10.sp,
                            color: Colors.grey,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        )
                      ],
                    ),
                  ],
                );
              } else if (state is ProductListingFailed) {
                if (widget.type == ProductListingType.search) {
                  return Row(
                    children: [
                      if (widget.type != ProductListingType.store &&
                          widget.type != ProductListingType.search)
                        Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: CachedNetworkImage(
                            imageUrl: widget.logo,
                            height: 35,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (widget.type != ProductListingType.store &&
                          widget.type != ProductListingType.search)
                        const SizedBox(
                          width: 10,
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                                fontSize: 20.sp,
                                fontFamily: AppTheme.fontFamily),
                          ),
                          Text(
                            '${widget.totalProduct} items',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          )
                        ],
                      ),
                    ],
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        titleSpacing: 0,
        actions: [
          if (widget.type != ProductListingType.search)
            IconButton(
              icon: const Icon(HeroiconsOutline.magnifyingGlass),
              onPressed: () {
                GoRouter.of(context).push(AppRoutes.search);
              },
            ),
        ],
      ),
      body: BlocConsumer<ProductListingBloc, ProductListingState>(
        listener: (BuildContext context, ProductListingState state) {
          if (state is ProductListingLoading) {
            setState(() {
              isDataFirstTime = true;
            });
          } else if (state is ProductListingLoaded) {
            _productSlugsNotifier.value =
                state.productList.map((p) => p.slug).toList();
          }
        },
        builder: (BuildContext context, ProductListingState state) {
          if (state is ProductListingLoaded) {
            return BlocBuilder<NestedCategoryBloc, NestedCategoryState>(
              builder: (context, nestedState) {
                final bool showSubcategorySidebar =
                    nestedState is NestedCategoryLoaded &&
                        nestedState.subCategoryData.isNotEmpty;

                return CustomRefreshIndicator(
                  onRefresh: () async {
                    context.read<ProductListingBloc>().add(
                          FetchListingProducts(
                              type: widget.type,
                              identifier: _getCurrentIdentifier(),
                              sortType: 'default'),
                        );
                  },
                  child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo is ScrollUpdateNotification &&
                            scrollInfo.metrics.pixels > 0 &&
                            scrollInfo.metrics.maxScrollExtent > 0 &&
                            !state.hasReachedMax &&
                            !state.isFilterLoading &&
                            !state.isLoading &&
                            scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent - 200) {
                          context.read<ProductListingBloc>().add(
                                FetchMoreListingProducts(
                                  type: widget.type,
                                  identifier: _getCurrentIdentifier(),
                                ),
                              );
                        }
                        return false;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 2.5.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT: Subcategory Sidebar (Conditional)
                            if (showSubcategorySidebar) ...[
                              categoryList(),
                              SizedBox(width: 3.w),
                            ],

                            // RIGHT: Product Grid (Always present)
                            Expanded(
                              child: Container(
                                color: Theme.of(context).colorScheme.surface,
                                child: Column(
                                  children: [
                                    SizedBox(height: 10.h),

                                    // Sort Button
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth:
                                            MediaQuery.of(context).size.width,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            CustomFilterSortBtnWidget(
                                              onTap: () =>
                                                  _showFilterBottomSheet(
                                                      categoryIds:
                                                          state.categoryIds ??
                                                              [],
                                                      brandsIds:
                                                          state.brandIds ?? []),
                                              buttonName: context.tr('filter', fallback: 'Filter'),
                                              iconData:
                                                  RemixIcons.equalizer_3_line,
                                            ),
                                            const SizedBox(width: 10),
                                            CustomFilterSortBtnWidget(
                                              onTap: _showSortBottomSheet,
                                              buttonName: context.tr('sort', fallback: 'Sort'),
                                              iconData:
                                                  HeroiconsOutline.arrowsUpDown,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 10.h),
                                    const Divider(height: 1, thickness: 1),

                                    // Product List with dynamic grid columns
                                    productList(
                                      productData: state.productList,
                                      isFilterLoading: state.isFilterLoading,
                                      hasReachedMax: state.hasReachedMax,
                                      isLoading: state.isLoading,
                                      crossAxisCount: showSubcategorySidebar
                                          ? (isTablet(context) ? 3 : 2)
                                          : (isTablet(context)
                                              ? 4
                                              : 3), // Smart switch
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                );
              },
            );
          }
          if (state is ProductListingLoading) {
            return const CustomCircularProgressIndicator();
          } else if (state is ProductListingFailed) {
            if (widget.type == ProductListingType.search) {
              return const NoSearchPage();
            } else {
              return NoProductPage(
                onRetry: () {},
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget productList({
    required List<ProductData> productData,
    required bool isFilterLoading,
    required bool hasReachedMax,
    required bool isLoading,
    required int crossAxisCount,
  }) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(
            productData, isFilterLoading, hasReachedMax, crossAxisCount),
      ),
    );
  }

  Widget _buildContent(
    List<ProductData> productData,
    bool isFilterLoading,
    bool hasReachedMax,
    int crossAxisCount,
  ) {
    if (isFilterLoading) {
      return productListShimmer(
        crossAxisCount,
        key: const ValueKey('shimmer'),
      );
    }

    if (productData.isEmpty) {
      return const NoProductPage(
        key: ValueKey('no_product'),
      );
    }

    return _buildProductGrid(
      productData,
      hasReachedMax,
      crossAxisCount,
      key: widget.type == ProductListingType.search
          ? const ValueKey('product_grid_search')
          : const ValueKey('product_grid_normal'),
    );
  }

  Widget _buildProductGrid(
    List<ProductData> productData,
    bool hasReachedMax,
    int crossAxisCount, {
    Key? key,
  }) {
    return Column(
      key: key,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsetsGeometry.directional(
              start: 14.w,
              end: 6.w,
              top: 8.h,
              bottom: 8.h,
            ),
            child: AnimationLimiter(
              child: AlignedGridView.count(
                key: ValueKey('grid_${_getCurrentIdentifier()}'),
                controller: _mainScrollController,
                shrinkWrap: false,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 70),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 8.w,
                itemCount:
                    hasReachedMax ? productData.length : productData.length + 3,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 300),
                    columnCount: crossAxisCount,
                    child: SlideAnimation(
                      verticalOffset: 40.0,
                      curve: Curves.easeOutCubic,
                      child: FadeInAnimation(
                        child:
                            _buildGridItem(productData, index, crossAxisCount),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(
    List<ProductData> productData,
    int index,
    int crossAxisCount,
  ) {
    if (index >= productData.length) {
      return productShimmer();
    }

    final product = productData[index];
    final allSlugs = productData.map((p) => p.slug).toList();

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
      relatedProductSlugs: allSlugs,
      relatedSlugsNotifier: _productSlugsNotifier,
      onReachEnd: () {
        final bloc = context.read<ProductListingBloc>();
        final currentState = bloc.state;
        if (currentState is ProductListingLoaded &&
            !currentState.hasReachedMax &&
            !currentState.isFilterLoading &&
            !currentState.isLoading &&
            !bloc.isLoadingMore) {
          bloc.add(
            FetchMoreListingProducts(
              type: widget.type,
              identifier: _getCurrentIdentifier(),
            ),
          );
        }
      },
      initialIndex: index,
      productPrice: product.variants.first.price.toString(),
      formattedProductPrice: product.variants.first.formattedPrice,
      specialPrice: product.variants.first.specialPrice.toString(),
      formattedSpecialPrice: product.variants.first.formattedSpecialPrice,
      currencyCode: product.variants.first.currencyCode,
      estimatedDeliveryTime: product.estimatedDeliveryTime.toString(),
      assetImage: '',
      productTags: product.tags,
      ratings: double.parse(product.ratings.toString()),
      ratingCount: product.ratingCount,
      isSponsored: product.isSponsored,
      badge: product.badge,
      onCardTap: product.isSponsored
          ? () => context.read<AdClickBloc>().add(RecordClick(
                campaignId: product.campaignId,
                visitorKey: product.visitorKey,
              ))
          : null,
      onAddToCart: () {
        if (product.variants.length > 1 ||
            product.variants.any((v) => v.addonGroups.isNotEmpty == true)) {
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
              variantId: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .id
                  .toString(),
              variantName: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .title
                  .toString(),
              vendorId: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .storeId
                  .toString(),
              name: product.title,
              image: product.mainImage,
              price: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .specialPrice
                  .toDouble(),
              originalPrice: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .price
                  .toDouble(),
              quantity: product.quantityStepSize,
              serverCartItemId: null,
              syncAction: CartSyncAction.add,
              updatedAt: DateTime.now(),
              minQty: product.minimumOrderQuantity,
              maxQty: product.totalAllowedQuantity,
              isOutOfStock: product.variants
                      .firstWhere((variant) => variant.isDefault)
                      .stock <=
                  0,
              isSynced: false,
              currencyCode: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .currencyCode,
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
      productVariantId:
          product.variants.firstWhere((variant) => variant.isDefault).id,
      storeId:
          product.variants.firstWhere((variant) => variant.isDefault).storeId,
      wishlistItemId:
          product.favorite.isNotEmpty ? product.favorite.first.id ?? 0 : 0,
      totalStocks:
          product.variants.firstWhere((variant) => variant.isDefault).stock,
      imageFit: product.imageFit,
      quantityStepSize: product.quantityStepSize,
      minQty: product.minimumOrderQuantity,
      totalAllowedQuantity: product.totalAllowedQuantity,
      indicator: product.indicator,
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

  Widget productListShimmer(int crossAxisCount, {Key? key}) {
    return Padding(
      key: key,
      padding: EdgeInsetsGeometry.directional(
        start: 14.w,
        end: 8.w,
        top: 8.h,
        bottom: 8.h,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 70),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 6.h,
          // +22.h to keep the shimmer skeleton in step with the real cards
          // (which now reserve room for the "Recommended" chip).
          mainAxisExtent: crossAxisCount == 2 ? 202.h : 222.h,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 130,
                width: 130,
                borderRadius: 15,
              ),
              const SizedBox(height: 10.0),
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 15,
                width: 130,
                borderRadius: 15,
              ),
              const SizedBox(height: 2.0),
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 15,
                width: 130,
                borderRadius: 15,
              ),
              const SizedBox(height: 2.0),
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 15,
                width: 80,
                borderRadius: 15,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget productShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 130,
          width: 130,
          borderRadius: 15,
        ),
        const SizedBox(height: 10.0),
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 15,
          width: 130,
          borderRadius: 15,
        ),
        const SizedBox(height: 2.0),
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 15,
          width: 130,
          borderRadius: 15,
        ),
        const SizedBox(height: 2.0),
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 15,
          width: 80,
          borderRadius: 15,
        ),
      ],
    );
  }

  Widget categoryList() {
    return BlocBuilder<NestedCategoryBloc, NestedCategoryState>(
      builder: (context, state) {
        if (state is NestedCategoryLoaded) {
          final subcategories = state.subCategoryData;
          // Ensure we have a selected category
          if (state.subCategoryData.isNotEmpty) {
            if (selectedSubcategory.id == null) {
              selectedSubcategory = state.subCategoryData.first;
              _currentSelectedIndex = 0;
            }

            final int totalItems = subcategories.length + 1;
            const double itemHeight =
                110.0; // Fixed height for smooth animation calculation

            return Container(
              width: 75.h,
              height: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              child: SingleChildScrollView(
                controller: _sidebarScrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Stack(
                    children: [
                      // The items
                      Column(
                        children: List.generate(totalItems, (index) {
                          if (index == 0) {
                            return SizedBox(
                              height: itemHeight,
                              child: _buildAllCategoryItem(
                                  _currentSelectedIndex == 0),
                            );
                          }
                          final subcategory = subcategories[index - 1];
                          return SizedBox(
                            height: itemHeight,
                            child: _buildSubcategoryItem(
                              subcategory: subcategory,
                              isSelected: _currentSelectedIndex == index,
                              index: index,
                            ),
                          );
                        }),
                      ),

                      // The sliding animated indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        top: _currentSelectedIndex * itemHeight,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Container(
                            width: 3.w,
                            height: itemHeight -
                                24.0, // height minus vertical padding
                            decoration: BoxDecoration(
                              borderRadius: BorderRadiusGeometry.directional(
                                topStart: Radius.circular(8.r),
                                bottomStart: Radius.circular(8.r),
                              ),
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAllCategoryItem(bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSelectedIndex = 0;
        });
        _scrollToIndex(0);
        _resetGridScroll();

        // Fetch products for the main category (not a sub-slug)
        context.read<ProductListingBloc>().add(
              FetchSortedListingProducts(
                type: ProductListingType.category,
                identifier: widget.identifier, // Original parent slug
                sortType: 'default',
              ),
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 8.0,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 50,
              decoration: const BoxDecoration(
                  color: Colors.transparent, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: CustomImageContainer(
                imagePath: 'assets/images/icons/shopping-basket.png',
                height: isSelected ? 45 : 40,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              context.tr('all', fallback: "All"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet(context) ? 14 : 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryItem({
    required CategoryData subcategory,
    required bool isSelected,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        if (subcategory.subcategoryCount! > 0) {
          GoRouter.of(context).push(AppRoutes.productListing, extra: {
            'isTheirMoreCategory': true,
            'title': subcategory.title,
            'logo': subcategory.image,
            'totalProduct': subcategory.productCount,
            'type': ProductListingType.category,
            'identifier': subcategory.slug,
          });
        } else {
          setState(() {
            selectedSubcategory = subcategory;
            _currentSelectedIndex = index;
          });
          _scrollToIndex(index);
          _resetGridScroll();

          context.read<ProductListingBloc>().add(
                FetchSortedListingProducts(
                  type: ProductListingType.category,
                  identifier: subcategory.slug ?? '',
                  sortType: 'default',
                ),
              );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 8.0,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 50,
              decoration: const BoxDecoration(
                  color: Colors.transparent, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: CustomImageContainer(
                imagePath: subcategory.image!,
                height: isSelected ? 45 : 40,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subcategory.title ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isTablet(context) ? 14 : 10.sp,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterCategory {
  final String title;
  final List<String> options;

  FilterCategory({
    required this.title,
    required this.options,
  });
}

import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_state.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/model/recent_product_model/recent_product_model.dart';
import 'package:hyper_local/screens/cart_page/bloc/add_to_cart/add_to_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/add_to_cart/add_to_cart_state.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_detail_bloc/product_detail_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_detail_bloc/product_detail_event.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_detail_bloc/product_detail_state.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_faq_bloc/product_faq_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_review_bloc/product_review_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/app_bar_widget.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/custom_product_feature_section_widget.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_bottom_cart_bar.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_description_section.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_detail_shimmer.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_faq_section.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_reviews_section.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_title_header.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_variant_selector.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/seller_store_name_card.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/similar_product_widget.dart';
import 'package:hyper_local/services/recent_product/recent_product_service.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../model/product_initial_data.dart';
export 'package:hyper_local/screens/product_detail_page/model/product_initial_data.dart';
export 'package:hyper_local/screens/product_detail_page/widgets/rating_bar_widget.dart';

class ProductDetailPage extends StatefulWidget {
  final String productSlug;
  final ProductInitialData? initialData;
  final VoidCallback? closeContainer;
  final ScrollController? externalScrollController;
  final bool disableImageHero;
  final bool isActiveProduct;

  const ProductDetailPage({
    super.key,
    required this.productSlug,
    this.initialData,
    this.closeContainer,
    this.externalScrollController,
    this.disableImageHero = false,
    this.isActiveProduct = true,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  Map<String, SwatchValues> selectedVariants = {};
  bool _showTitle = false;
  bool _hasLoggedView = false;

  ProductVariants? _currentVariant;

  ProductVariants _getActiveVariant(ProductData product) {
    if (selectedVariants.isEmpty) {
      return product.variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => product.variants.first,
      );
    }

    return product.variants.firstWhere(
      (v) {
        // Match ALL selected attributes using their slugs
        for (var attr in product.attributes) {
          final selected = selectedVariants[attr.name];
          if (selected != null) {
            final variantValue = v.attributes[attr.slug];
            if (variantValue?.toString().toLowerCase().trim() != selected.value.toString().toLowerCase().trim()) {
              return false;
            }
          }
        }
        return true;
      },
      orElse: () => product.variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => product.variants.first,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.externalScrollController != null) {
      widget.externalScrollController!.addListener(_onScroll);
    } else {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use PrimaryScrollController safely if external and local are not passed to NestedScrollView
    // However, we will pass them to NestedScrollView.
  }

  void _onScroll() {
    final controller = widget.externalScrollController ?? _scrollController;
    if (!controller.hasClients) return;
    final offset = controller.offset;
    final show = offset > 200;
    if (_showTitle != show) {
      setState(() => _showTitle = show);
    }
  }

  @override
  void dispose() {
    if (widget.externalScrollController != null) {
      widget.externalScrollController!.removeListener(_onScroll);
    } else {
      _scrollController.removeListener(_onScroll);
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onProductViewed(
    String id,
    String name,
    String imageUrl,
    String slug,
  ) async {
    final product = RecentProduct(
      id: id,
      name: name,
      imageUrl: imageUrl,
      productSlug: slug,
    );
    await RecentlyViewedService.addProduct(product);
  }

  void _hydrateSelectedVariantsIfEmpty(ProductData product) {
    if (selectedVariants.isNotEmpty || _currentVariant == null) return;
    for (var attr in product.attributes) {
      final variantAttrValue = _currentVariant!.attributes[attr.slug];
      if (variantAttrValue == null) continue;
      try {
        final sw = attr.swatchValues.firstWhere(
          (s) => s.value.toString().toLowerCase().trim() == variantAttrValue.toString().toLowerCase().trim(),
        );
        selectedVariants[attr.name] = sw;
      } catch (_) {
        selectedVariants[attr.name] = SwatchValues(value: variantAttrValue.toString(), swatch: '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AddToCartBloc()),
        BlocProvider(
          create: (_) => ProductDetailBloc()..add(FetchProductDetail(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) => ProductReviewBloc()..add(FetchProductReview(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) => ProductFAQBloc()..add(FetchProductFAQ(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) => SimilarProductBloc()
            ..add(FetchSimilarProduct(
              excludeProductSlug: [widget.productSlug],
            )),
        ),
      ],
      child: CustomScaffold(
        showViewCart: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: MultiBlocListener(
          listeners: [
            // Pre-existing (kept as a no-op slot — some downstream code
            BlocListener<AddToCartBloc, AddToCartState>(
              listener: (_, __) {},
            ),
            // Catches server-side cart errors (e.g.
            BlocListener<CartBloc, CartState>(
              listenWhen: (prev, next) => next is CartLoaded && next.errorMessage != null,
              listener: (context, state) {
                if (state is CartLoaded && state.errorMessage != null) {
                  ToastManager.show(
                    context: context,
                    message: state.errorMessage!,
                    type: ToastType.error,
                  );
                }
              },
            ),
            BlocListener<ProductDetailBloc, ProductDetailState>(
              listenWhen: (prev, next) {
                if (next is ProductDetailLoaded) {
                  final prevLoaded = prev is ProductDetailLoaded ? prev : null;
                  final prevNotifying = prevLoaded?.isNotifying ?? false;
                  final nextNotifying = next.isNotifying;
                  final hasError = next.errorMessage != null && (prevLoaded?.errorMessage == null);
                  return (prevNotifying && !nextNotifying) || hasError;
                }
                return false;
              },
              listener: (context, state) {
                if (state is ProductDetailLoaded) {
                  if (state.errorMessage != null) {
                    ToastManager.show(
                      context: context,
                      message: state.errorMessage!,
                      type: ToastType.error,
                    );
                    context.read<ProductDetailBloc>().add(ClearProductDetailError());
                  } else {
                    final product = state.productData[0];
                    final isNotify = product.notificationSet ?? false;
                    ToastManager.show(
                      context: context,
                      message: isNotify ? context.tr('notifyMeSuccess') : context.tr('notificationCancelledSuccess'),
                      type: ToastType.success,
                    );
                  }
                }
              },
            ),
          ],
          child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
            builder: (BuildContext context, ProductDetailState state) {
              if (state is ProductDetailLoading) {
                return NestedScrollView(
                  controller: widget.externalScrollController ?? _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      AppBarWidget(
                        productSlug: widget.productSlug,
                        loadedProduct: null,
                        initialData: widget.initialData,
                        disableImageHero: widget.disableImageHero,
                        externalScrollController: widget.externalScrollController,
                        isActiveProduct: widget.isActiveProduct,
                      ),
                    ];
                  },
                  body: const ProductDetailShimmer(),
                );
              } else if (state is ProductDetailLoaded) {
                final product = state.productData[0];

                _currentVariant ??= product.variants.firstWhere(
                  (v) => v.isDefault,
                  orElse: () => product.variants.first,
                );

                _hydrateSelectedVariantsIfEmpty(product);

                final activeVariant = _getActiveVariant(product);

                if (!_hasLoggedView) {
                  _hasLoggedView = true;
                  _onProductViewed(
                    product.id.toString(),
                    product.title,
                    product.mainImage,
                    product.slug,
                  );
                }

                final surfaceColor = Theme.of(context).colorScheme.surface;

                return NestedScrollView(
                  controller: widget.externalScrollController ?? _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      AppBarWidget(
                        showTitle: _showTitle,
                        productSlug: widget.productSlug,
                        initialData: widget.initialData,
                        loadedProduct: product,
                        selectedVariant: activeVariant,
                        disableImageHero: widget.disableImageHero,
                        externalScrollController: widget.externalScrollController,
                        isActiveProduct: widget.isActiveProduct,
                      ),
                    ];
                  },
                  body: CustomScrollView(
                    clipBehavior: Clip.antiAlias,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: StaggeredListAnimator(
                          type: StaggeredListType.column,
                          children: [
                            // Card 1 — Title + rating + pricing
                            Container(
                              width: double.infinity,
                              color: surfaceColor,
                              padding: EdgeInsets.fromLTRB(
                                12.w,
                                15.h,
                                12.w,
                                12.h,
                              ),
                              child: ProductTitleHeader(
                                product: product,
                                activeVariant: activeVariant,
                                currentVariant: _currentVariant!,
                              ),
                            ),

                            // Card 2 — Variant selector
                            if (product.attributes.isNotEmpty) ...[
                              SizedBox(height: 10.h),
                              Container(
                                width: double.infinity,
                                color: surfaceColor,
                                padding: EdgeInsets.fromLTRB(
                                  12.w,
                                  12.h,
                                  12.w,
                                  12.h,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: product.attributes.length,
                                  itemBuilder: (context, index) {
                                    final attribute = product.attributes[index];
                                    return ProductVariantSelector(
                                      label: attribute.name,
                                      attributeSlug: attribute.slug,
                                      variantType: attribute.swatcheType,
                                      selectedValue: selectedVariants[attribute.name],
                                      onSelected: (SwatchValues value) {
                                        setState(() {
                                          selectedVariants[attribute.name] = value;
                                        });
                                      },
                                      productAttributes: attribute.swatchValues,
                                      variants: product.variants,
                                    );
                                  },
                                ),
                              ),
                            ],

                            // Card 4 — Product description / details
                            SizedBox(height: 10.h),
                            Container(
                              width: double.infinity,
                              color: surfaceColor,
                              padding: EdgeInsets.fromLTRB(
                                12.w,
                                0.h,
                                12.w,
                                0.h,
                              ),
                              child: ProductDescriptionSection(product: product),
                            ),

                            SizedBox(height: 10.h),
                            // Store Name
                            if (!AppHelpers.systemVendorTypeIsSingle) ...[
                              SellerStoreNameCard(
                                storeName: product.variants.first.storeName,
                                storeSlug: product.variants.first.storeSlug,
                                sellerName: product.seller,
                              ),
                              SizedBox(height: 10.h),
                            ],
                            if (product.customProductFeaturedSections.isNotEmpty) ...[
                              CustomProductFeatureSectionWidget(
                                sections: product.customProductFeaturedSections,
                              ),
                            ],
                            ProductReviewsSection(product: product),
                            ProductFaqSection(product: product),
                            BlocBuilder<SimilarProductBloc, SimilarProductState>(
                              builder: (context, state) {
                                if (state is SimilarProductLoaded) {
                                  return SimilarProductWidget(
                                    product: state.similarProduct,
                                    disableHero: widget.disableImageHero,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                            const SizedBox(
                              height: 20,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (state is ProductDetailFailed) {
                return const NoProductPage();
              }
              return const CustomCircularProgressIndicator();
            },
          ),
        ),
        bottomNavigationBar: ProductBottomCartBar(
          selectedVariants: selectedVariants,
        ),
      ),
    );
  }
}

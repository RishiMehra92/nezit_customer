import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/dependency_injection_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';

import '../../../router/app_routes.dart';
import '../../home_page/model/brands_model.dart';
import '../../home_page/model/category_model.dart';
import 'package:flutter_staggered_animations_plus/flutter_staggered_animations_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import '../../product_listing_page/model/product_listing_type.dart';
import '../bloc/section_see_all_bloc.dart';
import '../bloc/section_see_all_event.dart';
import '../bloc/section_see_all_state.dart';

/// "See all" page for a single home-layout section. Fetches the full paginated
/// item list (GET /api/home-layout/sections/{id}) and renders the matching
/// card grid for the section [type] ('categories' / 'brands').
class SectionSeeAllPage extends StatefulWidget {
  final int sectionId;
  final String type;
  final String title;

  const SectionSeeAllPage({
    super.key,
    required this.sectionId,
    required this.type,
    this.title = '',
  });

  @override
  State<SectionSeeAllPage> createState() => _SectionSeeAllPageState();
}

class _SectionSeeAllPageState extends State<SectionSeeAllPage> {
  final ScrollController _scrollController = ScrollController();
  late final SectionSeeAllBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<SectionSeeAllBloc>()
      ..add(FetchSectionItems(sectionId: widget.sectionId, type: widget.type));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _bloc.add(const FetchMoreSectionItems());
    }
  }

  void _openListing({
    required ProductListingType type,
    required String? slug,
    String? title,
    String? logo,
  }) {
    if (slug == null || slug.isEmpty) return;
    GoRouter.of(context).push(AppRoutes.productListing, extra: {
      'type': type,
      'identifier': slug,
      'title': title ?? '',
      'logo': logo ?? '',
    });
  }

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: GridView.builder(
        itemCount: 15, // Fill the screen
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.0,
        ),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return ShimmerWidget.rectangular(
            isBorder: true,
            borderRadius: 12.r,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: CustomScaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: BlocBuilder<SectionSeeAllBloc, SectionSeeAllState>(
          builder: (context, state) {
            log('Section See All State $state');
            if (state is SectionSeeAllLoading ||
                state is SectionSeeAllInitial) {
              return _buildShimmer(context);
            }
            if (state is SectionSeeAllFailed) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(state.error, textAlign: TextAlign.center),
                ),
              );
            }
            if (state is SectionSeeAllLoaded) {
              if (state.items.isEmpty) {
                return Center(
                  child: Text(
                    context.tr('noData', fallback: 'No data'),
                  ),
                );
              }
              return CustomRefreshIndicator(
                onRefresh: () async {
                  context.read<SectionSeeAllBloc>().add(FetchSectionItems(sectionId: widget.sectionId, type: widget.type));
                },
                child: AnimationLimiter(
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
                        sliver: _buildSliverGrid(state, context),
                      ),
                      if (state.isLoadingMore)
                        SliverPadding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          sliver: const SliverToBoxAdapter(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSliverGrid(SectionSeeAllLoaded state, BuildContext context) {
    if (state.type == 'categories') {
      final categories = state.items.whereType<CategoryData>().toList();
      return SliverAlignedGrid.count(
        crossAxisCount: 4,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final c = categories[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 300),
            columnCount: 4,
            child: SlideAnimation(
              verticalOffset: 40.0,
              horizontalOffset: 0.0,
              curve: Curves.easeOutCubic,
              child: FadeInAnimation(
                child: GestureDetector(
                  onTap: () => _openListing(
                    type: ProductListingType.category,
                    slug: c.slug,
                    title: c.title,
                    logo: c.image,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth;
                      final cardHeight = cardWidth / 0.7; // maintain aspect ratio
                      final borderRadius = cardWidth * 0.12;
                      return SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(2.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(borderRadius),
                                ),
                                child: SizedBox.expand(
                                  child: CustomImageContainer(
                                    imagePath: c.image ?? '',
                                    fit: BoxFit.contain,
                                    borderRadius: BorderRadius.circular(borderRadius),
                                    errorWidget: Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.05),
                              child: Text(
                                c.title ?? '',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else if (state.type == 'brands') {
      final brands = state.items.whereType<BrandData>().toList();
      return SliverAlignedGrid.count(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final b = brands[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 300),
            columnCount: 3,
            child: SlideAnimation(
              verticalOffset: 40.0,
              horizontalOffset: 0.0,
              curve: Curves.easeOutCubic,
              child: FadeInAnimation(
                child: GestureDetector(
                  onTap: () => _openListing(
                    type: ProductListingType.brand,
                    slug: b.slug,
                    title: b.title,
                    logo: b.logo,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth;
                      final cardHeight = cardWidth / 0.9;
                      return SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                padding: const EdgeInsets.all(10.0),
                                child: CustomImageContainer(
                                  imagePath: b.logo ?? '',
                                  fit: BoxFit.contain,
                                  errorWidget: Icon(Icons.storefront_rounded, color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              b.title ?? '',
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}

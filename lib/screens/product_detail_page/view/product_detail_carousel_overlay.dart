import 'dart:ui';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local/screens/product_detail_page/view/product_detail_page.dart';

class ProductDetailCarouselOverlay extends StatefulWidget {
  final List<String> productSlugs;
  final ValueNotifier<List<String>>? relatedSlugsNotifier;
  final VoidCallback? onReachEnd;
  final int initialIndex;
  final bool isSubProduct;
  final String heroTagPrefix;

  const ProductDetailCarouselOverlay({
    super.key,
    required this.productSlugs,
    this.relatedSlugsNotifier,
    this.onReachEnd,
    required this.initialIndex,
    this.isSubProduct = false,
    this.heroTagPrefix = '',
  });

  @override
  State<ProductDetailCarouselOverlay> createState() => _ProductDetailCarouselOverlayState();
}

class _ProductDetailCarouselOverlayState extends State<ProductDetailCarouselOverlay> {
  static const double _kViewportFraction = 0.93;
  static const double _kMaxExpansionOffset = 150.0;
  static const double _kMaxCornerRadius = 16.0;
  static const double _kMaxHorizontalMargin = 6.0;

  late PageController _pageController;
  final Map<int, ScrollController> _scrollControllers = {};
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: _kViewportFraction,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ScrollController _getScrollController(int index) {
    if (!_scrollControllers.containsKey(index)) {
      _scrollControllers[index] = ScrollController();
    }
    return _scrollControllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _getScrollController(_currentIndex),
            builder: (context, child) {
              final scrollController = _getScrollController(_currentIndex);
              final offset = scrollController.hasClients ? scrollController.offset : 0.0;
              final expandProgress = (offset / _kMaxExpansionOffset).clamp(0.0, 1.0);

              final screenWidth = MediaQuery.of(context).size.width;
              final pageViewWidth = lerpDouble(screenWidth, screenWidth / _kViewportFraction, expandProgress)!;

              return SizedBox(
                width: screenWidth,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  child: SizedBox(
                    width: pageViewWidth,
                    child: child,
                  ),
                ),
              );
            },
            child: widget.relatedSlugsNotifier != null
                ? ValueListenableBuilder<List<String>>(
                    valueListenable: widget.relatedSlugsNotifier!,
                    builder: (context, slugs, _) {
                      return _buildPageView(slugs);
                    },
                  )
                : _buildPageView(widget.productSlugs),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(List<String> slugs) {
    return PageView.builder(
      controller: _pageController,
      itemCount: slugs.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
        if (index >= slugs.length - 2) {
          widget.onReachEnd?.call();
        }
      },
      itemBuilder: (context, index) {
        final scrollController = _getScrollController(index);
        final slug = slugs[index];

        return AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            final offset = scrollController.hasClients ? scrollController.offset : 0.0;
            final expandProgress = (offset / _kMaxExpansionOffset).clamp(0.0, 1.0);

            final currentMargin = lerpDouble(_kMaxHorizontalMargin, 0.0, expandProgress)!;
            final currentRadius = lerpDouble(_kMaxCornerRadius, 0.0, expandProgress)!;

            final topPadding = MediaQuery.of(context).padding.top;
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            final currentTopMargin = (currentMargin * 3) + lerpDouble(topPadding, 0.0, expandProgress)!;
            final currentBottomMargin = (currentMargin * 3) + lerpDouble(bottomPadding, 0.0, expandProgress)!;

            final overlayTopPadding = lerpDouble(10.0, topPadding, expandProgress)!;

            return DismissiblePage(
              onDismissed: () => Navigator.of(context).pop(),
              direction: DismissiblePageDismissDirection.down,
              isFullScreen: true,
              backgroundColor: Colors.transparent,
              child: Container(
                margin: EdgeInsets.only(
                  top: currentTopMargin,
                  bottom: currentBottomMargin,
                  left: currentMargin,
                  right: currentMargin,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(currentRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(currentRadius),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: MediaQuery.of(context).padding.copyWith(
                            top: overlayTopPadding,
                          ),
                    ),
                    child: ProductDetailPage(
                      productSlug: slug,
                      externalScrollController: scrollController,
                      closeContainer: () => Navigator.of(context).pop(),
                      disableImageHero: true,
                      isActiveProduct: _currentIndex == index,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

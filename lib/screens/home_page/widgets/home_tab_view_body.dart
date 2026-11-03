import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/screens/home_page/widgets/home_loading_shimmer.dart';
import '../model/category_model.dart';

class HomeTabViewBody extends StatefulWidget {
  final bool isInitialLoading;
  final bool isRecreatingTabController;
  final bool hasDeliveryLocation;
  final List<CategoryData> categories;
  final Widget Function(String categorySlug) tabContentBuilder;
  final String tabBarViewKey;
  final bool isRetry;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryLocation;

  const HomeTabViewBody({
    super.key,
    required this.isInitialLoading,
    required this.isRecreatingTabController,
    required this.hasDeliveryLocation,
    required this.categories,
    required this.tabContentBuilder,
    required this.tabBarViewKey,
    required this.isRetry,
    required this.onLoadMore,
    required this.onRetryLocation,
  });

  @override
  State<HomeTabViewBody> createState() => _HomeTabViewBodyState();
}

class _HomeTabViewBodyState extends State<HomeTabViewBody> {
  late List<Widget> _tabBarViewChildren;

  @override
  void initState() {
    super.initState();
    _buildTabBarViewChildren();
  }

  @override
  void didUpdateWidget(covariant HomeTabViewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories || oldWidget.tabContentBuilder != widget.tabContentBuilder) {
      _buildTabBarViewChildren();
    }
  }

  void _buildTabBarViewChildren() {
    List<Widget> children = [
      widget.tabContentBuilder(''),
    ];
    children.addAll(widget.categories.map((category) {
      return widget.tabContentBuilder(category.slug ?? '');
    }).toList());
    _tabBarViewChildren = children;
  }

  @override
  Widget build(BuildContext context) {
    // ALWAYS prioritize showing the Shimmer if we are loading or rebuilding tabs
    if (widget.isInitialLoading || widget.isRecreatingTabController) {
      return const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HomeLoadingShimmer(),
          ),
        ],
      );
    }

    // Only AFTER initial loading is done, check if we have a location
    if (!widget.hasDeliveryLocation && !widget.isRetry) {
      return NoDeliveryLocationPage(
        onRetry: widget.onRetryLocation,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          if (metrics.axis == Axis.vertical && metrics.pixels >= metrics.maxScrollExtent * 0.85) {
            widget.onLoadMore();
          }
        }
        return false;
      },
      child: TabBarView(
        key: ValueKey(widget.tabBarViewKey),
        physics: const NeverScrollableScrollPhysics(),
        children: _tabBarViewChildren,
      ),
    );
  }
}

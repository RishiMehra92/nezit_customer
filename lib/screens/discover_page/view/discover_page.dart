import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/home_page/widgets/scroll_to_top_button.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../bloc/discover_bloc/discover_bloc.dart';
import '../bloc/discover_bloc/discover_event.dart';
import '../bloc/discover_bloc/discover_state.dart';
import '../widgets/discover_stories_header.dart';
import '../widgets/discover_grid_card.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showBackToTopNotifier = ValueNotifier<bool>(false);
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<DiscoverBloc>().add(const FetchDiscoverStatuses(isRefresh: true));
    context.read<DiscoverBloc>().add(const FetchDiscoverReels(isRefresh: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showBackToTopNotifier.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<DiscoverBloc>().add(const FetchDiscoverStatuses(isRefresh: true));
    context.read<DiscoverBloc>().add(const FetchDiscoverReels(isRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _onScroll() {
    final double offset = _scrollController.offset;
    double progress;
    if (offset < 0.0) {
      // Pulling down (overscroll) - expand stories header up to a factor of -0.6
      progress = (offset / 120.0).clamp(-0.6, 0.0);
    } else {
      // Scrolling down - collapse stories header up to a factor of 1.0
      progress = (offset / 60.0).clamp(0.0, 1.0);
    }
    if (progress != _scrollProgress) {
      setState(() {
        _scrollProgress = progress;
      });
    }

    // Scroll to Top visibility check
    if (offset <= 400.0) {
      _showBackToTopNotifier.value = false;
    } else {
      final direction = _scrollController.position.userScrollDirection;
      if (direction == ScrollDirection.reverse) {
        _showBackToTopNotifier.value = false; // scrolling down
      } else if (direction == ScrollDirection.forward) {
        _showBackToTopNotifier.value = true; // scrolling up
      }
    }
  }

  void _scrollToTop() {
    _showBackToTopNotifier.value = false;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Stories Header: Covered by its own BlocBuilder for loading shimmer
            DiscoverStoriesHeader(scrollProgress: _scrollProgress),

            // 2. Reels Grid with pull-to-refresh
            Expanded(
              child: CustomRefreshIndicator(
                onRefresh: _onRefresh,
                child: Stack(
                  alignment: AlignmentGeometry.topCenter,
                  children: [
                    BlocBuilder<DiscoverBloc, DiscoverState>(
                      builder: (context, state) {
                        if ((state.reelsStatus == ApiStatus.initial || state.reelsStatus == ApiStatus.loading) && state.reels.isEmpty) {
                          return _buildReelsShimmerLoading(context);
                        }

                        if (state.reelsStatus == ApiStatus.failure && state.reels.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 100.0),
                              child: Text(state.reelsErrorMessage ?? 'Failed to load reels'),
                            ),
                          );
                        }

                        final reelsItems = state.reels;

                        if (reelsItems.isEmpty) {
                          return SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.65,
                              child: Center(
                                child: NoReelPage(
                                  onRetry: () {
                                    context.read<DiscoverBloc>().add(const FetchDiscoverReels(isRefresh: true));
                                  },
                                ),
                              ),
                            ),
                          );
                        }

                        return StaggeredListAnimator.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
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
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _showBackToTopNotifier,
                      builder: (context, showBackToTop, child) {
                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          top: showBackToTop ? (isTablet(context) ? 20 : 30).h : (isTablet(context) ? 10 : 15).h,
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
                                  onScrollToTop: _scrollToTop,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelsShimmerLoading(BuildContext context) {
    return StaggeredListAnimator.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      type: StaggeredListType.masonryGridView,
      padding: const EdgeInsets.only(top: 8, left: 8, bottom: 40, right: 8),
      duration: const Duration(milliseconds: 375),
      verticalOffset: 50.0,
      spacing: 7,
      itemBuilder: (context, index) {
        final double cardHeight = (index % 4 == 0) ? 300.0 : ((index % 4 == 2) ? 230.0 : 280.0);
        return ShimmerWidget.rectangular(
          height: cardHeight,
          borderRadius: 16,
          isBorder: true,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/discover_page/bloc/discover_bloc/discover_event.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/utils/widgets/story_avatar_widget.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../bloc/discover_bloc/discover_bloc.dart';
import '../bloc/discover_bloc/discover_state.dart';

class DiscoverStoriesHeader extends StatefulWidget {
  final double scrollProgress;

  const DiscoverStoriesHeader({
    super.key,
    required this.scrollProgress,
  });

  @override
  State<DiscoverStoriesHeader> createState() => _DiscoverStoriesHeaderState();
}

class _DiscoverStoriesHeaderState extends State<DiscoverStoriesHeader> {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _seenStoryIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<DiscoverBloc>().state;
      if (!state.hasReachedMax &&
          state.status != ApiStatus.loading &&
          !state.isLoadMoreLoading &&
          state.nextCursor != null &&
          state.nextCursor!.isNotEmpty) {
        context.read<DiscoverBloc>().add(const FetchDiscoverStatuses(isLoadMore: true));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double currentAvatarSize = 80 - (35 * widget.scrollProgress); // 80 to 45
    final double textOpacity = 1.0 - (widget.scrollProgress * 2).clamp(0.0, 1.0);
    final double paddingVertical = 12 - (6 * widget.scrollProgress); // 12 to 6
    final double height = currentAvatarSize + (paddingVertical * 2) + (25 * textOpacity);

    return BlocBuilder<DiscoverBloc, DiscoverState>(
      builder: (context, state) {
        // 1. Shimmer Loading State for Stories/Status only
        if (state.status == ApiStatus.initial || (state.status == ApiStatus.loading && state.items.isEmpty)) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: height,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: EdgeInsets.symmetric(vertical: paddingVertical),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerWidget.circular(
                        width: currentAvatarSize,
                        height: currentAvatarSize,
                        isBorder: false,
                      ),
                      if (textOpacity > 0.0) ...[
                        const SizedBox(height: 6),
                        ShimmerWidget.rectangular(
                          width: currentAvatarSize * 0.7,
                          height: 10,
                          borderRadius: 4,
                          isBorder: true,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        }

        final stories = state.items;
        if (stories.isEmpty) {
          return const SizedBox.shrink();
        }

        // 2. Success state with live user stories
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: height,
          width: double.infinity,
          alignment: Alignment.centerLeft,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.symmetric(vertical: paddingVertical),
          child: StaggeredListAnimator.builder(
            controller: _scrollController,
            itemCount: stories.length,
            type: StaggeredListType.listView,
            scrollDirection: Axis.horizontal,
            shrinkWrap: false,
            duration: const Duration(milliseconds: 375),
            horizontalOffset: 50.0,
            verticalOffset: 0.0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final item = stories[index];
              final profileId = item.profile?.id;
              final username = item.profile?.username ?? 'User';
              final photoUrl = item.profile?.photoUrl ?? '';
              
              // Locally override unseen status if we've seen it during this session
              final bool hasUnseen = (item.profile?.hasUnseenStatus ?? false) 
                  && (profileId == null || !_seenStoryIds.contains(profileId));

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: StoryAvatarWidget(
                    avatarSize: currentAvatarSize,
                    imageUrl: photoUrl,
                    username: username,
                    hasUnseen: hasUnseen,
                    textOpacity: textOpacity,
                    onTap: () {
                      if (profileId != null) {
                        setState(() {
                          _seenStoryIds.add(profileId);
                        });
                      }
                      context.push(
                        AppRoutes.discoverStory,
                        extra: {
                          'users': stories,
                          'initialUserIndex': index,
                          'onPageChanged': (int newIndex) {
                            final viewedItem = stories[newIndex];
                            if (viewedItem.profile?.id != null) {
                              setState(() {
                                _seenStoryIds.add(viewedItem.profile!.id!);
                              });
                            }
                            if (_scrollController.hasClients) {
                              double screenWidth = MediaQuery.of(context).size.width;
                              double itemWidth = currentAvatarSize + 8.0;
                              double targetOffset = (newIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
                              targetOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

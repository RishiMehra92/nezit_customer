import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/store_stories/store_stories_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/store_stories/store_stories_state.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/recommend_badge.dart';
import 'package:hyper_local/utils/widgets/story_avatar_widget.dart';

class StoreHeaderWidget extends StatefulWidget {
  final StoreData store;
  final double distance;
  final String rating;
  final int totalStoreFeedback;

  const StoreHeaderWidget({
    Key? key,
    required this.store,
    required this.distance,
    required this.rating,
    required this.totalStoreFeedback,
  }) : super(key: key);

  @override
  State<StoreHeaderWidget> createState() => _StoreHeaderWidgetState();
}

class _StoreHeaderWidgetState extends State<StoreHeaderWidget> {
  final Set<int> _seenStoryIds = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreStoriesBloc, StoreStoriesState>(
      builder: (context, state) {
        final hasStories = state.items.isNotEmpty;
        final storyItem = hasStories ? state.items.first : null;
        final profileId = storyItem?.profile?.id;

        final bool hasUnseen =
            (storyItem?.profile?.hasUnseenStatus ?? false) && (profileId == null || !_seenStoryIds.contains(profileId));

        void Function()? onStoryTap;
        if (hasStories) {
          onStoryTap = () {
            if (profileId != null) {
              setState(() {
                _seenStoryIds.add(profileId);
              });
            }
            if (context.mounted) {
              context.push(
                AppRoutes.discoverStory,
                extra: {
                  'users': state.items,
                  'initialUserIndex': 0,
                  'onPageChanged': (int newIndex) {
                    final viewedItem = state.items[newIndex];
                    if (viewedItem.profile?.id != null) {
                      setState(() {
                        _seenStoryIds.add(viewedItem.profile!.id!);
                      });
                    }
                  },
                },
              );
            }
          };
        }

        final double imageHeight = isTablet(context) ? 280 : 170;
        final double overflowHeight = 60; // Space for the overlapping avatar

        return SizedBox(
          height: imageHeight + overflowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: imageHeight,
                child: GestureDetector(
                  onTap: onStoryTap,
                  child: ClipRRect(
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: widget.store.banner?.isNotEmpty == true
                          ? CustomImageContainer(imagePath: widget.store.banner!, fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(color: AppTheme.primaryColor),
                              child: const Center(
                                child: Icon(Icons.store, size: 50, color: Colors.white70),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              if (widget.store.isRecommended ?? false)
                const PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: RecommendBadge(),
                ),
              PositionedDirectional(
                start: 16,
                bottom: 0,
                child: Builder(
                  builder: (context) {
                    if (hasStories && widget.store.logo?.isNotEmpty == true) {
                      return InkWell(
                        onTap: onStoryTap,
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                          padding: const EdgeInsets.all(2), // match original border space
                          child: StoryAvatarWidget(
                            avatarSize: isTablet(context) ? 116 : 86,
                            imageUrl: widget.store.logo!,
                            username: widget.store.name ?? '',
                            showProfileName: false,
                            hasUnseen: hasUnseen,
                            onTap: onStoryTap ?? () {},
                          ),
                        ),
                      );
                    }

                    return Container(
                      width: isTablet(context) ? 120 : 90,
                      height: isTablet(context) ? 120 : 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: widget.store.logo?.isNotEmpty == true
                            ? CustomImageContainer(imagePath: widget.store.logo!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.blue.shade50,
                                child: const Icon(Icons.store, size: 28, color: AppTheme.primaryColor),
                              ),
                      ),
                    );
                  },
                ),
              ),
              PositionedDirectional(
                end: 12,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AppTheme.ratingStarIconFilled, size: 16, color: AppTheme.ratingStarColor),
                      const SizedBox(width: 4),
                      Text('${widget.rating}/5 (${widget.totalStoreFeedback})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

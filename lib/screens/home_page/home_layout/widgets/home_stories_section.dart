import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/home_page/home_layout/model/home_layout_models.dart';
import 'package:hyper_local/utils/widgets/story_avatar_widget.dart';
import 'package:hyper_local/config/helper.dart';

class HomeStoriesSection extends StatefulWidget {
  final HomeSection section;

  const HomeStoriesSection({
    super.key,
    required this.section,
  });

  @override
  State<HomeStoriesSection> createState() => _HomeStoriesSectionState();
}

class _HomeStoriesSectionState extends State<HomeStoriesSection> {
  final Set<int> _seenStoryIds = {};

  @override
  Widget build(BuildContext context) {
    final stories = widget.section.stories;
    if (stories.isEmpty) return const SizedBox.shrink();

    final config = widget.section.storiesConfig;

    // Parse ringColor and showProfileName from config
    final ringColorHex = config.ringColor;
    Color? ringColor;
    if (ringColorHex != null && ringColorHex.isNotEmpty) {
      var cleaned = ringColorHex.replaceAll('#', '');
      if (cleaned.length == 3) cleaned = cleaned.split('').map((c) => '$c$c').join();
      if (cleaned.length == 6) cleaned = 'FF$cleaned';
      final value = int.tryParse(cleaned, radix: 16);
      if (value != null) ringColor = Color(value);
    }

    final showProfileName = config.showProfileName;

    final double avatarSize = 75.0.w;

    final outerPadding =
        parseOuterPadding(widget.section.config) ?? EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w);
    final horizontalGap = parseItemGapHorizontal(widget.section.config) ?? 12.0;

    final String? title = widget.section.title;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorVal = widget.section.config is Map ? (widget.section.config as Map)['text_color'] : null;
    final Color? textColor = parseThemeColor(textColorVal, isDark);

    final Widget content = SizedBox(
      height: showProfileName ? avatarSize + 45 : avatarSize + 20,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final item = stories[index];
          final profileId = item.profile?.id;
          final username = item.profile?.username ?? 'User';
          final photoUrl = item.profile?.photoUrl ?? '';

          // Locally override unseen status if we've seen it during this session
          final bool hasUnseen =
              (item.profile?.hasUnseenStatus ?? false) && (profileId == null || !_seenStoryIds.contains(profileId));

          return Padding(
            padding: EdgeInsets.only(right: index == stories.length - 1 ? 0 : horizontalGap.toDouble()),
            child: StoryAvatarWidget(
              avatarSize: avatarSize,
              imageUrl: photoUrl,
              username: username,
              hasUnseen: hasUnseen,
              textOpacity: 1.0,
              ringColor: ringColor,
              showProfileName: showProfileName,
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
                    },
                  },
                );
              },
            ),
          );
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (title != null && title.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.w, 16.w, 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: outerPadding,
            child: content,
          ),
      ],
    );
  }
}

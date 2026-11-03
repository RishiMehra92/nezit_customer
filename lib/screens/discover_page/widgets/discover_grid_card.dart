import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:video_player/video_player.dart';
import '../model/discover_reel_model.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class DiscoverGridCard extends StatelessWidget {
  final DiscoverReelItem item;
  final int index;
  final List<DiscoverReelItem> reelsItems;
  final VoidCallback onLikeToggled;

  final double? height;
  final double? width;
  final bool showLikes;
  final bool showTitle;

  const DiscoverGridCard({
    super.key,
    required this.item,
    required this.index,
    required this.reelsItems,
    required this.onLikeToggled,
    this.height,
    this.width,
    this.showLikes = true,
    this.showTitle = true,
  });

  String _formatLikes(int likes) {
    if (likes >= 1000) {
      return "${(likes / 1000).toStringAsFixed(1)}k";
    }
    return likes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final String? coverImage = item.coverUrl;

    // Determinstic views based on likes/index so they don't jump/randomize on every setState/scroll

    // Define varying heights to create the staggered masonry effect
    final double cardHeight = height ??
        ((index % 4 == 0) ? 300.0 : ((index % 4 == 2) ? 230.0 : 280.0));

    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.discoverReels,
          extra: {
            'initialIndex': index,
            'reels': reelsItems,
          },
        );
      },
      child: Container(
        height: cardHeight,
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkProductCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 0.8,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 1. Cover Image
              if (coverImage != null && coverImage.isNotEmpty)
                Positioned.fill(
                  child: CustomImageContainer(
                    imagePath: coverImage,
                    fit: BoxFit.cover,
                    errorWidget: Container(color: Colors.black26),
                    placeholder: Container(color: Colors.black26),
                  ),
                )
              else if (item.videoUrl != null && item.videoUrl!.isNotEmpty)
                Positioned.fill(
                  child: VideoCoverFallback(videoUrl: item.videoUrl!),
                )
              else
                Positioned.fill(
                  child: Container(color: Colors.black26),
                ),
              // 2. Black Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.5), // Darker at top for profile visibility
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.25, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // 3. Profile Info (Top Left)
              if (item.profile != null)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: ClipOval(
                          child: CustomImageContainer(
                            imagePath: item.profile!.photoUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: Container(color: Colors.grey),
                            errorWidget: Container(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.profile!.username ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              )
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // 4. Views & Likes Overlay Row (Frosted Glassmorphism bar at bottom)
              if (showLikes || showTitle)
                Positioned(
                  left: 6,
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white12,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showTitle)
                          Text(
                            item.caption ?? item.profile?.username ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (showTitle && showLikes) const SizedBox(height: 4),
                        if (showLikes)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onLikeToggled,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (item.likedByMe ?? false)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: (item.likedByMe ?? false)
                                      ? Colors.red
                                      : Colors.white70,
                                  size: 13,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _formatLikes(item.likeCount ?? 0),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: (item.likedByMe ?? false)
                                        ? Colors.red
                                        : Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoCoverFallback extends StatefulWidget {
  final String videoUrl;

  const VideoCoverFallback({super.key, required this.videoUrl});

  @override
  State<VideoCoverFallback> createState() => _VideoCoverFallbackState();
}

class _VideoCoverFallbackState extends State<VideoCoverFallback> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((_) {
        // Ignore initialization errors for thumbnails
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(color: Colors.black26);
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

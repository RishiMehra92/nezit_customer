import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../widgets/reel_video_item.dart';
import '../model/discover_reel_model.dart';

class DiscoverReelsPage extends StatefulWidget {
  final int initialIndex;
  final List<DiscoverReelItem> reels;

  const DiscoverReelsPage({
    super.key,
    required this.initialIndex,
    required this.reels,
  });

  @override
  State<DiscoverReelsPage> createState() => _DiscoverReelsPageState();
}

class _DiscoverReelsPageState extends State<DiscoverReelsPage> {
  late PageController _pageController;
  late int _currentIndex;
  static bool _isGlobalMuted = false;

  // Cache of VideoPlayerControllers. Key is the reel index.
  final Map<int, VideoPlayerController> _videoControllers = {};

  int get _maxFeedCount => widget.reels.length;

  @override
  void initState() {
    super.initState();
    final int maxFeed = _maxFeedCount;
    final int startPage = maxFeed > 0 ? widget.initialIndex % maxFeed : 0;
    _currentIndex = startPage;
    _pageController = PageController(initialPage: startPage);
    _preloadReels(startPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  void _preloadReels(int index) {
    final int maxFeed = _maxFeedCount;
    if (index >= maxFeed) return;

    // Play active, pause others
    for (final entry in _videoControllers.entries) {
      final key = entry.key;
      final controller = entry.value;
      if (key == index) {
        if (controller.value.isInitialized) {
          controller.play();
        }
      } else {
        controller.pause();
      }
    }

    // Initialize active if not done yet
    _initController(index).then((controller) {
      if (mounted && _currentIndex == index) {
        controller.play();
      }
    });

    // Preload next 2 reels
    for (int i = index + 1; i <= index + 2; i++) {
      if (i < maxFeed) {
        _initController(i);
      }
    }

    // Cleanup: dispose controllers outside [index - 1, index + 2]
    final keysToDispose = _videoControllers.keys.where((key) => key < index - 1 || key > index + 2).toList();
    for (var key in keysToDispose) {
      final controller = _videoControllers.remove(key);
      controller?.dispose();
    }
  }

  Future<VideoPlayerController> _initController(int index) async {
    VideoPlayerController? controller = _videoControllers[index];
    if (controller == null) {
      final videoUrl = widget.reels[index].videoUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        // Fallback for null video URL (though ideally shouldn't happen)
        return Future.error('Video URL is null');
      }
      controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[index] = controller;
      try {
        await controller.initialize();
        controller.setLooping(false);
        controller.setVolume(_isGlobalMuted ? 0.0 : 1.0);
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        debugPrint('Error initializing reel at $index: $e');
      }
    }
    return controller;
  }

  Widget _buildEndPage() {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Theme.of(context).primaryColor.withValues(alpha: 0.15),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('youAreAllCaughtUp', fallback: "You're all caught up!"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('clickHereToGoToTop', fallback: "Click here to go to Top"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int maxFeed = _maxFeedCount;

    if (maxFeed == 0) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_library_outlined, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                context.tr('noReelsFound', fallback: "No Reels Found"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('checkBackLaterForNewReels', fallback: "Check back later for new reels."),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Stack(
            children: [
              // Vertical PageView for scrolling through videos
              PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                itemCount: maxFeed + 1,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _preloadReels(index);
                },
                itemBuilder: (context, index) {
                  if (index == maxFeed) {
                    return _buildEndPage();
                  }

                  final item = widget.reels[index];
                  final isActive = index == _currentIndex;

                  return ReelVideoItem(
                    controller: _videoControllers[index],
                    item: item,
                    isActive: isActive,
                    index: index,
                    isMuted: _isGlobalMuted,
                    onLikeToggle: () {
                      setState(() {});
                    },
                    onVideoComplete: () {
                      if (_currentIndex < maxFeed) {
                        _pageController.animateToPage(
                          _currentIndex + 1,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                  );
                },
              ),

              // Custom back button overlay at top left
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.3),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Custom global mute/unmute overlay at top right
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isGlobalMuted = !_isGlobalMuted;
                      for (final controller in _videoControllers.values) {
                        controller.setVolume(_isGlobalMuted ? 0.0 : 1.0);
                      }
                    });
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.3),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _isGlobalMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )));
  }
}

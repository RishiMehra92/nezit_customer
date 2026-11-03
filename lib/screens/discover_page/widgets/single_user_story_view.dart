import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/price_utils.dart';
import '../bloc/discover_bloc/discover_bloc.dart';
import '../bloc/discover_bloc/discover_event.dart';
import '../bloc/discover_bloc/discover_state.dart';
import '../model/discover_status_model.dart';
import '../model/discover_profile_status_model.dart';

class SingleUserStoryView extends StatefulWidget {
  final int userIndex;
  final DiscoverStatusItem userItem;
  final DiscoverStatusItem? nextUserItem;
  final VoidCallback onComplete;
  final VoidCallback onPreviousUser;
  final VoidCallback onClose;

  const SingleUserStoryView({
    super.key,
    required this.userIndex,
    required this.userItem,
    this.nextUserItem,
    required this.onComplete,
    required this.onPreviousUser,
    required this.onClose,
  });

  @override
  State<SingleUserStoryView> createState() => _SingleUserStoryViewState();
}

class _SingleUserStoryViewState extends State<SingleUserStoryView> {
  @override
  void initState() {
    super.initState();
    _fetchProfileStoriesIfNeeded();
    _preloadNextUserIfNeeded();
  }

  @override
  void didUpdateWidget(covariant SingleUserStoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userItem.profile?.username !=
        widget.userItem.profile?.username) {
      _fetchProfileStoriesIfNeeded();
      _preloadNextUserIfNeeded();
    }
  }

  void _fetchProfileStoriesIfNeeded() {
    final username = widget.userItem.profile?.username ?? '';
    if (username.isNotEmpty) {
      final state = context.read<DiscoverBloc>().state;
      final status = state.profileStatusMap[username];
      if (status != ApiStatus.loading) {
        context.read<DiscoverBloc>().add(
            FetchDiscoverProfileStatuses(username: username, isRefresh: true));
      }
    }
  }

  void _preloadNextUserIfNeeded() {
    final nextUsername = widget.nextUserItem?.profile?.username ?? '';
    if (nextUsername.isNotEmpty) {
      final state = context.read<DiscoverBloc>().state;
      final status = state.profileStatusMap[nextUsername];
      if (status == null || status == ApiStatus.initial) {
        context
            .read<DiscoverBloc>()
            .add(FetchDiscoverProfileStatuses(username: nextUsername));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.userItem.profile?.username ?? '';
    final avatarUrl = widget.userItem.profile?.photoUrl ?? '';

    return BlocBuilder<DiscoverBloc, DiscoverState>(
      builder: (context, state) {
        final status = state.profileStatusMap[username] ?? ApiStatus.initial;
        final items = state.profileItemsMap[username] ?? [];

        // Also precache the first media item of next user if available
        final nextUsername = widget.nextUserItem?.profile?.username ?? '';
        if (nextUsername.isNotEmpty) {
          final nextItems = state.profileItemsMap[nextUsername] ?? [];
          if (nextItems.isNotEmpty) {
            final firstNext = nextItems.first;
            final isNextVideo =
                (firstNext.contentType ?? '').toLowerCase() == 'video';
            final mediaUrl = firstNext.mediaUrl ?? '';
            if (!isNextVideo && mediaUrl.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  precacheImage(CachedNetworkImageProvider(mediaUrl), context);
                }
              });
            }
          }
        }

        if (status == ApiStatus.loading && items.isEmpty) {
          return _buildLoadingView(username, avatarUrl);
        }

        if (status == ApiStatus.failure && items.isEmpty) {
          return _buildErrorView(
              username, avatarUrl, state.profileErrorMessageMap[username]);
        }

        if (items.isEmpty) {
          return _buildEmptyView(username, avatarUrl);
        }

        return _UserStoryPlayer(
          key: ValueKey(username),
          userIndex: widget.userIndex,
          username: username,
          avatarUrl: avatarUrl,
          items: items,
          onComplete: widget.onComplete,
          onPreviousUser: widget.onPreviousUser,
          onClose: widget.onClose,
        );
      },
    );
  }

  Widget _buildLoadingView(String username, String avatarUrl) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          _buildHeaderOverlay(username, avatarUrl),
        ],
      ),
    );
  }

  Widget _buildErrorView(String username, String avatarUrl, String? error) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.white70, size: 48),
                const SizedBox(height: 12),
                Text(
                  error ?? 'Unable to load stories.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<DiscoverBloc>().add(
                          FetchDiscoverProfileStatuses(
                              username: username, isRefresh: true),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          _buildHeaderOverlay(username, avatarUrl),
        ],
      ),
    );
  }

  Widget _buildEmptyView(String username, String avatarUrl) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          const Center(
            child: Text(
              'No active stories.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
          _buildHeaderOverlay(username, avatarUrl),
        ],
      ),
    );
  }

  Widget _buildHeaderOverlay(String username, String avatarUrl) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 10,
          right: 10,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              username.isNotEmpty ? '@$username' : 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserStoryPlayer extends StatefulWidget {
  final int userIndex;
  final String username;
  final String avatarUrl;
  final List<DiscoverProfileStatusItem> items;
  final VoidCallback onComplete;
  final VoidCallback onPreviousUser;
  final VoidCallback onClose;

  const _UserStoryPlayer({
    super.key,
    required this.userIndex,
    required this.username,
    required this.avatarUrl,
    required this.items,
    required this.onComplete,
    required this.onPreviousUser,
    required this.onClose,
  });

  @override
  State<_UserStoryPlayer> createState() => _UserStoryPlayerState();
}

class _UserStoryPlayerState extends State<_UserStoryPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late DiscoverBloc _discoverBloc;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Set<int> _seenStatusIds = {};
  int _currentIndex = 0;
  bool _isPaused = false;

  String _formatTimeAgo(int? seconds) {
    if (seconds == null) return '';
    if (seconds < 10) return 'Now';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).floor()}m';
    if (seconds < 86400) return '${(seconds / 3600).floor()}h';
    return '${(seconds / 86400).floor()}d';
  }

  @override
  void initState() {
    super.initState();
    _discoverBloc = context.read<DiscoverBloc>();
    _animController = AnimationController(vsync: this);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.stop();
        _animController.reset();
        _nextStory();
      }
    });

    final firstUnseenIndex =
        widget.items.indexWhere((item) => item.seenByMe == false);
    if (firstUnseenIndex != -1) {
      _currentIndex = firstUnseenIndex;
    } else {
      _currentIndex = 0;
    }

    _loadStory(_currentIndex);
  }

  @override
  void dispose() {
    if (_seenStatusIds.isNotEmpty) {
      _discoverBloc.add(MarkDiscoverStoriesAsSeen(_seenStatusIds.toList()));
    }
    _animController.dispose();
    for (var controller in _videoControllers.values) {
      controller.removeListener(_videoListener);
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  void _videoListener() {
    final activeController = _videoControllers[_currentIndex];
    if (activeController != null && activeController.value.isInitialized) {
      final bool isPlaying = activeController.value.isPlaying;
      final bool isBuffering = activeController.value.isBuffering;
      final Duration position = activeController.value.position;
      final Duration duration = activeController.value.duration;
      final bool isFinished = position >= duration && duration > Duration.zero;

      final bool isActuallyPlaying = isPlaying && !isBuffering;

      if (isFinished && !_isPaused) {
        // Video finished but progress bar might not have perfectly reached 100% due to frame skipping
        if (_animController.isAnimating || _animController.value < 1.0) {
          _animController.value =
              1.0; // This triggers the AnimationStatus.completed listener
        }
      } else if (isActuallyPlaying && !_isPaused) {
        if (!_animController.isAnimating) {
          _animController.forward();
        }
      } else {
        if (_animController.isAnimating) {
          _animController.stop();
        }
      }
    }
  }

  void _loadStory(int index) {
    if (index >= widget.items.length || index < 0) {
      return;
    }

    // Mark current item as seen
    final itemId = widget.items[index].id;
    if (itemId != null) {
      _seenStatusIds.add(itemId);
    }

    _animController.stop();
    _animController.reset();

    // Pause all other controllers
    _videoControllers.forEach((key, controller) {
      if (key != index) {
        controller.pause();
      }
    });

    _currentIndex = index;
    final item = widget.items[index];
    final bool isVideo = (item.contentType ?? '').toLowerCase() == 'video';
    final mediaUrl = item.mediaUrl ?? '';

    if (!isVideo) {
      if (mediaUrl.isNotEmpty) {
        final provider = CachedNetworkImageProvider(mediaUrl);
        final stream = provider.resolve(ImageConfiguration.empty);
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (imageInfo, synchronousCall) {
            if (mounted && _currentIndex == index) {
              final duration = item.durationMs != null
                  ? Duration(milliseconds: item.durationMs!)
                  : const Duration(seconds: 5);
              _animController.duration = duration;
              if (!_isPaused && !_animController.isAnimating) {
                _animController.forward();
              }
            }
          },
          onError: (exception, stackTrace) {
            if (mounted && _currentIndex == index) {
              _animController.duration = const Duration(seconds: 3);
              if (!_isPaused && !_animController.isAnimating) {
                _animController.forward();
              }
            }
          },
        );
        stream.addListener(listener);
      }
    } else if (mediaUrl.isNotEmpty) {
      VideoPlayerController? activeController = _videoControllers[index];
      if (activeController == null) {
        activeController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
          ..addListener(_videoListener);
        _videoControllers[index] = activeController;
        activeController.initialize().then((_) {
          if (mounted && _currentIndex == index) {
            setState(() {});
            _animController.duration = activeController!.value.duration;
            activeController.seekTo(Duration.zero).then((_) {
              activeController!.play();
            });
          }
        }).catchError((e) {
          debugPrint("VideoPlayer error: $e");
        });
      } else {
        if (activeController.value.isInitialized) {
          _animController.duration = activeController.value.duration;
          activeController.seekTo(Duration.zero).then((_) {
            activeController?.play();
          });
        }
      }
    }

    // Preload next 1 item in current user stories
    for (int i = index + 1; i <= index + 1; i++) {
      if (i < widget.items.length) {
        final nextItem = widget.items[i];
        final bool isNextVideo =
            (nextItem.contentType ?? '').toLowerCase() == 'video';
        final nextMediaUrl = nextItem.mediaUrl ?? '';
        if (!isNextVideo && nextMediaUrl.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              precacheImage(CachedNetworkImageProvider(nextMediaUrl), context);
            }
          });
        } else if (isNextVideo && nextMediaUrl.isNotEmpty) {
          if (!_videoControllers.containsKey(i)) {
            final nextController =
                VideoPlayerController.networkUrl(Uri.parse(nextMediaUrl))
                  ..addListener(_videoListener);
            _videoControllers[i] = nextController;
            nextController.initialize().then((_) {
              if (mounted) {
                setState(() {});
                if (_currentIndex == i) {
                  _animController.duration = nextController.value.duration;
                  nextController.seekTo(Duration.zero).then((_) {
                    nextController.play();
                  });
                }
              }
            }).catchError((e) {
              debugPrint("VideoPlayer preload error: $e");
            });
          }
        }
      }
    }

    // Clean up controllers outside [index - 1, index + 1]
    final keysToDispose = _videoControllers.keys
        .where((key) => key < index - 1 || key > index + 1)
        .toList();
    for (var key in keysToDispose) {
      final controller = _videoControllers.remove(key);
      if (controller != null) {
        controller.removeListener(_videoListener);
        controller.dispose();
      }
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.items.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadStory(_currentIndex);
    } else {
      widget.onComplete();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadStory(_currentIndex);
    } else {
      widget.onPreviousUser();
    }
  }

  double _getProgressValue(int index) {
    if (index < _currentIndex) {
      return 1.0;
    } else if (index == _currentIndex) {
      return _animController.value;
    } else {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentIndex];
    final bool isVideo =
        (currentItem.contentType ?? '').toLowerCase() == 'video';
    final mediaUrl = currentItem.mediaUrl ?? '';

    return GestureDetector(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media Background
          if (!isVideo && mediaUrl.isNotEmpty)
            _buildImageMedia(currentItem, mediaUrl)
          else if (isVideo && mediaUrl.isNotEmpty)
            Builder(
              builder: (context) {
                final activeController = _videoControllers[_currentIndex];
                if (activeController != null &&
                    activeController.value.isInitialized) {
                  double vidWidth = activeController.value.size.width;
                  double vidHeight = activeController.value.size.height;

                  if (vidWidth == 0 || vidHeight == 0) {
                    vidWidth = currentItem.mediaWidth?.toDouble() ?? 9;
                    vidHeight = currentItem.mediaHeight?.toDouble() ?? 16;
                  }

                  final double aspectRatio = vidWidth / vidHeight;
                  final bool isLandscape = aspectRatio > 1.05;

                  if (isLandscape) {
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: VideoPlayer(activeController),
                        ),
                      ),
                    );
                  }

                  return SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: vidWidth,
                        height: vidHeight,
                        child: VideoPlayer(activeController),
                      ),
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
              },
            )
          else
            const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
            ),

          // Interactive Tap & Hold Zones
          Positioned.fill(
            child: Row(
              children: [
                // Left Column: Previous Story
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _previousStory,
                  ),
                ),
                // Middle Column: Pause on Hold
                Expanded(
                  flex: 2,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) {
                      setState(() {
                        _isPaused = true;
                      });
                      _animController.stop();
                      _videoControllers[_currentIndex]?.pause();
                    },
                    onPointerUp: (_) {
                      setState(() {
                        _isPaused = false;
                      });
                      if (_animController.duration != null) {
                        _animController.forward();
                      }
                      _videoControllers[_currentIndex]?.play();
                    },
                    child: Container(),
                  ),
                ),
                // Right Column: Next Story
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _nextStory,
                  ),
                ),
              ],
            ),
          ),

          // Header Overlay with Progress Bars
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 10,
                right: 10,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Bars
                  Row(
                    children: List.generate(
                      widget.items.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _getProgressValue(index),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                                minHeight: 2.5,
                                borderRadius: BorderRadius.circular(10),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // User Avatar & Name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: widget.avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(widget.avatarUrl)
                            : null,
                        child: widget.avatarUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.username.isNotEmpty
                                ? widget.username
                                : 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_formatTimeAgo(currentItem.timeAgo).isNotEmpty)
                            Text(
                              _formatTimeAgo(currentItem.timeAgo),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom Story Overlay (Text & Products)
          if ((currentItem.text != null &&
                  currentItem.text!.trim().isNotEmpty) ||
              currentItem.products.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentItem.text != null &&
                      currentItem.text!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentItem.text!.trim(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (currentItem.products.isNotEmpty) ...[
                    if (currentItem.text != null &&
                        currentItem.text!.trim().isNotEmpty)
                      const SizedBox(height: 16),
                    _buildProductsList(currentItem.products),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageMedia(DiscoverProfileStatusItem item, String mediaUrl) {
    final int? width = item.mediaWidth;
    final int? height = item.mediaHeight;
    final bool hasValidDimensions =
        width != null && height != null && width > 0 && height > 0;
    final double? aspectRatio = hasValidDimensions ? width / height : null;
    final bool isLandscape = aspectRatio != null && aspectRatio > 1.05;

    if (isLandscape) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Blurred Backdrop
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Transform.scale(
              scale: 1.15,
              child: CustomImageContainer(
                imagePath: mediaUrl,
                fit: BoxFit.cover,
                errorWidget: const SizedBox.shrink(),
              ),
            ),
          ),
          // Dark Tint overlay over blur
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
          // 2. Centered uncropped image maintaining exact aspect ratio
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: CustomImageContainer(
                imagePath: mediaUrl,
                fit: BoxFit.contain,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white54, size: 48),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Portrait / Vertical / Square images fill screen directly
    return CustomImageContainer(
      imagePath: mediaUrl,
      fit: BoxFit.cover,
      placeholder: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
      ),
    );
  }

  Widget _buildProductsList(List<DiscoverProfileProduct> products) {
    return SizedBox(
      height: 72, // enough for product card
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        padEnds: true,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final productDetails = product.product;
          final variant = product.variant;
          final store = product.store;
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          final specialPrice = variant?.specialPrice;
          final regularPrice = variant?.price;
          final bool hasDiscount = specialPrice != null &&
              specialPrice > 0 &&
              regularPrice != null &&
              specialPrice < regularPrice;
          final num displayPrice = (specialPrice != null && specialPrice > 0)
              ? specialPrice
              : (regularPrice ?? 0);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              // Open product details
              if (productDetails?.slug != null) {
                _animController.stop();
                _videoControllers[_currentIndex]?.pause();

                await context.push(AppRoutes.productDetailPage,
                    extra: {'productSlug': productDetails!.slug!});

                if (mounted) {
                  if (_animController.duration != null) {
                    _animController.forward();
                  }
                  _videoControllers[_currentIndex]?.play();
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: productDetails?.imageUrl ?? '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          productDetails?.title ?? 'Unknown Product',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store?.name ?? 'Unknown Store',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              PriceUtils.formatPrice(displayPrice.toDouble()),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 4),
                              Text(
                                PriceUtils.formatPrice(regularPrice.toDouble()),
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black45,
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

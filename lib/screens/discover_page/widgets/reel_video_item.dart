import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/discover_bloc/discover_bloc.dart';
import '../bloc/discover_bloc/discover_event.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/services/location/user_location_hive.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/price_utils.dart';
import 'package:share_plus/share_plus.dart';
import '../model/discover_reel_model.dart';
import '../model/discover_profile_status_model.dart';

class ReelVideoItem extends StatefulWidget {
  final VideoPlayerController? controller;
  final DiscoverReelItem item;
  final bool isActive;
  final int index;
  final VoidCallback onLikeToggle;
  final bool isMuted;
  final VoidCallback onVideoComplete;

  const ReelVideoItem({
    super.key,
    required this.controller,
    required this.item,
    required this.isActive,
    required this.index,
    required this.onLikeToggle,
    required this.isMuted,
    required this.onVideoComplete,
  });

  @override
  State<ReelVideoItem> createState() => _ReelVideoItemState();
}

class _ReelVideoItemState extends State<ReelVideoItem> with SingleTickerProviderStateMixin {
  VideoPlayerController? get _controller => widget.controller;
  bool get _isInitialized => _controller != null && _controller!.value.isInitialized;
  bool get _hasError => _controller != null && _controller!.value.hasError;
  String get _errorMsg => _controller?.value.errorDescription ?? '';

  bool _isLiked = false;
  int _likeCount = 0;

  bool _isFastForwarding = false;

  late AnimationController _likeController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.item.likedByMe ?? false;
    _likeCount = widget.item.likeCount ?? 0;
    log('Reel[${widget.index}]: initState, isActive=${widget.isActive}, controllerInitialized=$_isInitialized');
    widget.controller?.addListener(_videoListener);
    if (widget.controller != null && widget.controller!.value.isInitialized) {
      widget.controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
      if (widget.isActive) {
        log('Reel[${widget.index}]: Playing video in initState');
        widget.controller!.play();
      }
    }

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _likeScaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.elasticOut),
    );
    _likeOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_likeController);
  }

  void _showLoginRequiredMessage() {
    ToastManager.show(
      context: context,
      message: 'Please sign in to like this reel',
      type: ToastType.info,
    );
  }

  Future<void> _likeReel({bool toggle = false}) async {
    final token = Global.token;
    if (token == null || token.isEmpty) {
      _showLoginRequiredMessage();
      return;
    }

    if (toggle) {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
        if (_likeCount < 0) _likeCount = 0;
      });
      widget.onLikeToggle();
      if (_isLiked) {
        _likeController.forward(from: 0.0);
      }
    } else {
      if (!_isLiked) {
        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
        widget.onLikeToggle();
      } else {
        return; // Already liked, no API call needed
      }
    }

    final location = HiveLocationHelper.getCurrentUserLocation();
    final lat = location?.latitude;
    final lng = location?.longitude;

    context.read<DiscoverBloc>().add(
          LikeReelEvent(
            reelId: widget.item.id ?? 0,
            liked: _isLiked,
            latitude: lat,
            longitude: lng,
          ),
        );
  }

  void _videoListener() {
    if (!mounted || widget.controller == null || !widget.controller!.value.isInitialized) {
      return;
    }

    final bool isFinished = widget.controller!.value.position >= widget.controller!.value.duration;
    if (isFinished) {
      widget.controller!.removeListener(_videoListener);
      widget.onVideoComplete();
      return;
    }

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant ReelVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool controllerChanged = widget.controller != oldWidget.controller;

    if (controllerChanged) {
      oldWidget.controller?.removeListener(_videoListener);
      widget.controller?.addListener(_videoListener);
    }

    if (widget.controller != null && widget.controller!.value.isInitialized) {
      widget.controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
      if (widget.isActive) {
        if (!oldWidget.isActive || controllerChanged) {
          log('Reel[${widget.index}]: Playing video in didUpdateWidget (isActive changed to true or controller changed)');
          widget.controller!.play();
        }
      } else {
        if (oldWidget.isActive || controllerChanged) {
          log('Reel[${widget.index}]: Pausing video in didUpdateWidget (isActive changed to false or controller changed)');
          widget.controller!.pause();
          widget.controller!.seekTo(Duration.zero);
        }
      }
    }
  }

  void _initializePlayer() {
    widget.controller?.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _likeController.dispose();
    widget.controller?.removeListener(_videoListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
        key: Key('reel_${widget.index}'),
        onVisibilityChanged: (info) {
          log('Reel[${widget.index}]: onVisibilityChanged -> fraction=${info.visibleFraction}');
          if (!mounted || _controller == null || !_isInitialized) return;

          if (info.visibleFraction == 0.0) {
            if (_controller!.value.isPlaying) {
              log('Reel[${widget.index}]: Pausing video because visibleFraction == 0.0');
              _controller!.pause();
              setState(() {});
            }
          } else if (info.visibleFraction == 1.0 && widget.isActive) {
            if (!_controller!.value.isPlaying) {
              log('Reel[${widget.index}]: Playing video because visibleFraction == 1.0 and isActive == true');
              _controller!.play();
              setState(() {});
            }
          }
        },
        child: Stack(
          children: [
            // Video display or loading/error states
            Positioned.fill(
              child: Hero(
                tag: 'reel_${widget.index}',
                child: Container(
                  color: Colors.black,
                  child: _hasError
                      ? _buildErrorScreen()
                      : !_isInitialized
                          ? _buildLoadingScreen()
                          : GestureDetector(
                              onTap: () {
                                if (_controller != null) {
                                  if (_controller!.value.isPlaying) {
                                    _controller!.pause();
                                  } else {
                                    _controller!.play();
                                  }
                                  setState(() {});
                                }
                              },
                              onDoubleTap: () {
                                if (Global.token != null && Global.token!.isNotEmpty) {
                                  _likeReel(toggle: false);
                                  _likeController.forward(from: 0.0);
                                } else {
                                  _showLoginRequiredMessage();
                                }
                              },
                              onLongPressStart: (details) {
                                if (_controller != null && _controller!.value.isPlaying) {
                                  final screenWidth = MediaQuery.of(context).size.width;
                                  if (details.globalPosition.dx > screenWidth / 2) {
                                    _controller!.setPlaybackSpeed(2);
                                    setState(() {
                                      _isFastForwarding = true;
                                    });
                                  }
                                }
                              },
                              onLongPressEnd: (details) {
                                if (_isFastForwarding && _controller != null) {
                                  _controller!.setPlaybackSpeed(1.0);
                                  setState(() {
                                    _isFastForwarding = false;
                                  });
                                }
                              },
                              onLongPressCancel: () {
                                if (_isFastForwarding && _controller != null) {
                                  _controller!.setPlaybackSpeed(1.0);
                                  setState(() {
                                    _isFastForwarding = false;
                                  });
                                }
                              },
                              child: SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _controller!.value.size.width,
                                    height: _controller!.value.size.height,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                              ),
                            ),
                ),
              ),
            ),

            // Black gradient overlay to read overlays clearly
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Like animation overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _likeController,
                    builder: (context, child) {
                      if (_likeController.isDismissed) {
                        return const SizedBox.shrink();
                      }
                      return Opacity(
                        opacity: _likeOpacityAnimation.value,
                        child: Transform.scale(
                          scale: _likeScaleAnimation.value,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 100,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Video pause icon overlay (indicates pause status)
            if (_isInitialized && _controller != null && !_controller!.value.isPlaying)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

            // Duration Tag (Top Right)

            // Frosted glass bar at the bottom with details and interactive likes
            Positioned(
              key: const ValueKey('bottom_ui'),
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 10,
              child: Column(
                children: [
                  Center(
                    child: AnimatedOpacity(
                      opacity: _isFastForwarding ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('twoXSpeed', fallback: '2x Speed'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Reel Info & Actions Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left side: User info and caption
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: widget.item.profile?.photoUrl != null
                                        ? CachedNetworkImageProvider(widget.item.profile!.photoUrl!)
                                        : null,
                                    child: widget.item.profile?.photoUrl == null
                                        ? const Icon(Icons.person, size: 18, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.item.profile?.username ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.item.caption != null && widget.item.caption!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  widget.item.caption!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right side: Actions (Like, Share)
                        Column(
                          spacing: 16,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (Global.token == null || Global.token!.isEmpty) {
                                  _showLoginRequiredMessage();
                                  return;
                                }
                                _likeReel(toggle: true);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: _isLiked ? Colors.red : Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatLikes(_likeCount),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                final String? reelUrl = widget.item.videoUrl ?? widget.item.source;
                                if (reelUrl != null && reelUrl.isNotEmpty) {
                                  SharePlus.instance.share(
                                    ShareParams(
                                      text: reelUrl,
                                    ),
                                  );
                                } else {
                                  ToastManager.show(
                                    context: context,
                                    message: context.tr('reelUrlNotAvailable', fallback: 'Reel URL is not available'),
                                    type: ToastType.error,
                                  );
                                }
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.share_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('share', fallback: "Share"),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Products Row
                  if (widget.item.products.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildProductsList(widget.item.products),
                  ],

                  // Progress Bar
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _isInitialized && _controller != null
                        ? ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: _controller!,
                            builder: (context, value, child) {
                              final duration = value.duration;
                              final position = value.position;
                              final targetValue =
                                  duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: targetValue),
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.linear,
                                  builder: (context, val, _) {
                                    return LinearProgressIndicator(
                                      value: val,
                                      minHeight: 3,
                                      backgroundColor: Colors.white24,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: const LinearProgressIndicator(
                              minHeight: 3,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ));
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
                log('Reel[${widget.index}]: Tapped product, pausing video and pushing product details');
                _controller?.pause();
                setState(() {});
                await context.push(AppRoutes.productDetailPage, extra: {'productSlug': productDetails!.slug!});

                if (!mounted) return;
                final isCurrent = ModalRoute.of(this.context)?.isCurrent;
                log('Reel[${widget.index}]: Returned from product details. isCurrent=$isCurrent, mounted=$mounted');

                if (isCurrent == true) {
                  log('Reel[${widget.index}]: Route is current, playing video');
                  _controller?.play();
                } else {
                  log('Reel[${widget.index}]: Route is NOT current (maybe went to login?), NOT playing video');
                }
                setState(() {});
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95),
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
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          productDetails?.title ?? context.tr('unknownProduct', fallback: 'Unknown Product'),
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
                          store?.name ?? context.tr('unknownStore', fallback: 'Unknown Store'),
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

  Widget _buildLoadingScreen() {
    return Stack(
      children: [
        if (widget.item.coverUrl != null && widget.item.coverUrl!.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.item.coverUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        const Center(
          child: CircularProgressIndicator(
            color: Colors.white70,
            strokeWidth: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white54,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('unableToLoadVideo', fallback: 'Unable to load video'),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (_errorMsg.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMsg,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializePlayer,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(context.tr('retry', fallback: 'Retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLikes(int likes) {
    if (likes >= 1000) {
      return "${(likes / 1000).toStringAsFixed(1)}k";
    }
    return likes.toString();
  }

  // Bottom sheet removed as it's no longer used for products
}

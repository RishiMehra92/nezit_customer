import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/introduction_pages/model/onboarding_model.dart';
import 'package:hyper_local/screens/introduction_pages/widgets/onboarding_design_helpers.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

class OnboardingMediaWidget extends StatefulWidget {
  final OnboardingScreenItem screen;
  final bool isActive;
  final double height;

  const OnboardingMediaWidget({
    super.key,
    required this.screen,
    required this.isActive,
    required this.height,
  });

  @override
  State<OnboardingMediaWidget> createState() => _OnboardingMediaWidgetState();
}

class _OnboardingMediaWidgetState extends State<OnboardingMediaWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    if (widget.screen.isVideo && widget.screen.isNetworkMedia) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.screen.isVideo) {
      if (widget.screen.media != oldWidget.screen.media) {
        _disposeVideo();
        _initVideo();
      } else if (_videoController != null && _isVideoInitialized) {
        if (widget.isActive && !_videoController!.value.isPlaying) {
          _videoController!.play();
        } else if (!widget.isActive && _videoController!.value.isPlaying) {
          _videoController!.pause();
        }
      }
    }
  }

  Future<void> _initVideo() async {
    try {
      final uri = Uri.parse(widget.screen.media);
      _videoController = VideoPlayerController.networkUrl(uri);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0);
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        if (widget.isActive) {
          _videoController!.play();
        }
      }
    } catch (e) {
      log('[Onboarding] Error initializing video player (${widget.screen.media}): $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
      }
    }
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _hasVideoError = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = widget.screen;

    // Handle empty media (e.g. when main media is removed in dynamic design)
    if (screen.media.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. Fallback / Local Assets
    if (screen.isFallback || !screen.isNetworkMedia) {
      return _buildLocalAsset(screen);
    }

    // 2. Video Media
    if (screen.isVideo) {
      return _buildVideoPlayer();
    }

    // 3. Lottie JSON Animation
    if (screen.isLottie) {
      return _buildLottie(screen);
    }

    // 4. Remote SVG
    if (screen.isSvg) {
      return _buildRemoteSvg(screen);
    }

    // 5. TXT Media
    if (screen.isTxt) {
      return _buildTextCard(screen);
    }

    // 6. Remote Raster Image (JPG, PNG, WebP, GIF)
    return _buildRemoteImage(screen);
  }

  Widget _buildLocalAsset(OnboardingScreenItem screen) {
    return CustomImageContainer(
      imagePath: screen.media,
      fit: BoxFit.contain,
      height: widget.height,
      width: double.infinity,
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasVideoError) {
      return _buildPlaceholderIcon(Icons.videocam_off_rounded);
    }

    if (!_isVideoInitialized || _videoController == null) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio > 0
              ? _videoController!.value.aspectRatio
              : 1.0,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget _buildLottie(OnboardingScreenItem screen) {
    return SizedBox(
      height: widget.height,
      child: Lottie.network(
        screen.media,
        fit: DesignMapper.mapBoxFit(screen.design.media.fit),
        errorBuilder: (context, error, stackTrace) {
          log('[Onboarding] Error loading Lottie (${screen.media}): $error');
          return _buildPlaceholderIcon(Icons.animation_rounded);
        },
        frameBuilder: (context, child, composition) {
          if (composition == null) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            );
          }
          return child;
        },
      ),
    );
  }

  Widget _buildRemoteSvg(OnboardingScreenItem screen) {
    return SizedBox(
      height: widget.height,
      child: SvgPicture.network(
        screen.media,
        fit: DesignMapper.mapBoxFit(screen.design.media.fit),
        placeholderBuilder: (context) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTextCard(OnboardingScreenItem screen) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            screen.title.isNotEmpty ? screen.title : screen.subtitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteImage(OnboardingScreenItem screen) {
    return SizedBox(
      height: widget.height,
      child: CachedNetworkImage(
        imageUrl: screen.media,
        fit: DesignMapper.mapBoxFit(screen.design.media.fit),
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
        errorWidget: (context, url, error) {
          log('[Onboarding] Error loading network image ($url): $error');
          return _buildPlaceholderIcon(Icons.broken_image_rounded);
        },
      ),
    );
  }

  Widget _buildPlaceholderIcon(IconData icon) {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

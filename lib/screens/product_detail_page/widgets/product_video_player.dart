import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/video_player_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Use a single global instance to avoid HttpClientClosedException
final _yt = YoutubeExplode();

class ProductVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;

  const ProductVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isActive,
  });

  @override
  State<ProductVideoPlayer> createState() => _ProductVideoPlayerState();
}

class _ProductVideoPlayerState extends State<ProductVideoPlayer> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  final _manager = VideoPlayerManager();

  // Track if we are currently fetching so we can cancel/ignore old fetches
  String? _fetchingUrl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(ProductVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle video URL change
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _initializePlayer();
    }

    // Handle active state change
    if (oldWidget.isActive != widget.isActive) {
      _handleActiveStateChange();
    }
  }

  Future<void> _initializePlayer() async {
    final currentUrl = widget.videoUrl;
    _fetchingUrl = currentUrl;

    setState(() {
      _isInitialized = false;
    });

    try {
      String videoSourceUrl = currentUrl;

      // Check if it's a YouTube URL
      bool isYouTube = currentUrl.contains('youtube.com') || currentUrl.contains('youtu.be');
      if (isYouTube) {
        final videoId = VideoId(currentUrl);
        final manifest = await _yt.videos.streamsClient.getManifest(videoId);

        final muxed = manifest.muxed;
        if (muxed.isNotEmpty) {
          final streamInfo = muxed.withHighestBitrate();
          videoSourceUrl = streamInfo.url.toString();
        } else {
          log('No muxed stream found for YouTube video');
          // Try videoOnly as fallback just in case
          if (manifest.videoOnly.isNotEmpty) {
            videoSourceUrl = manifest.videoOnly.withHighestBitrate().url.toString();
          } else {
            return;
          }
        }
      }

      // Ensure we haven't changed URLs while fetching
      if (!mounted || _fetchingUrl != currentUrl) return;

      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(videoSourceUrl), videoPlayerOptions: VideoPlayerOptions())
            ..initialize().then((_) {
              if (!mounted || _fetchingUrl != currentUrl) {
                _videoController?.dispose();
                _videoController = null;
                return;
              }

              _manager.videoPlayerController = _videoController;
              if (widget.isActive) {
                _videoController!.play();
              }
              _videoController!.setLooping(true);

              setState(() {
                _isInitialized = true;
              });
            }).catchError((error) {
              log('Video initialization error: $error');
            });
    } catch (e) {
      log('Error extracting video stream: $e');
    }
  }

  void _handleActiveStateChange() {
    if (!mounted) return;

    if (widget.isActive) {
      // Only control if this widget's controllers are the active ones
      if (_manager.videoPlayerController == _videoController) {
        _videoController?.play();
        _videoController?.seekTo(Duration.zero);
      }
    } else {
      // Unconditionally pause THIS widget's video when it becomes inactive
      _videoController?.pause();
    }
  }

  void _disposeControllers() {
    _fetchingUrl = null; // Cancel any pending initialization

    // Only clear manager references if they point to our controllers
    if (_manager.videoPlayerController == _videoController) {
      _manager.videoPlayerController = null;
    }

    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    // Do NOT close _yt since it's a global shared instance now
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const topRadius = BorderRadius.vertical(top: Radius.circular(16));

    Widget content;
    if (!_isInitialized) {
      content = Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    } else if (_videoController != null && _videoController!.value.isInitialized) {
      content = Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else {
      content = Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        ),
      );
    }

    return ClipRRect(
      borderRadius: topRadius,
      child: content,
    );
  }
}

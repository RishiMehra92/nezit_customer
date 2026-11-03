import 'dart:ui';
import 'package:video_player/video_player.dart';

class VideoPlayerManager {
  static final VideoPlayerManager _instance = VideoPlayerManager._internal();
  factory VideoPlayerManager() => _instance;
  VideoPlayerManager._internal();

  // Hold references to active controllers
  VideoPlayerController? videoPlayerController;

  // Optional: callback when state changes
  VoidCallback? onPlayerStateChanged;

  void play() {
    videoPlayerController?.play();
    onPlayerStateChanged?.call();
  }

  void pause() {
    videoPlayerController?.pause();
    onPlayerStateChanged?.call();
  }

  void mute() {
    videoPlayerController?.setVolume(0);
  }

  void unmute() {
    videoPlayerController?.setVolume(1.0);
  }

  void seekToStart() {
    videoPlayerController?.seekTo(Duration.zero);
  }

  void disposeAll() {
    videoPlayerController?.dispose();
    videoPlayerController = null;
  }
}
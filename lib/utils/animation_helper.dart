import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension FlipAnimateExtension on Widget {
  // ignore: non_constant_identifier_names
  Widget FlipAnimate({
    Duration duration = const Duration(seconds: 2),
    bool repeat = true,
  }) {
    return Animate(
      onPlay: repeat ? (controller) => controller.repeat() : null,
      child: this,
    ).flip(
      duration: duration,
      begin: 0,
      end: 2,
      direction: Axis.horizontal,
    );
  }
}

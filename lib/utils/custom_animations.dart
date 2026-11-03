import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension CustomAnimations on Widget {
  /// Animates the widget from right to left (slide in).
  Widget animateRightToLeft({Duration? duration, double delay = 0}) {
    return animate(delay: delay.ms)
        .slideX(
            begin: .2,
            end: 0,
            duration: duration ?? 400.ms,
            curve: Curves.easeOutCubic)
        .fadeIn(duration: duration ?? 400.ms);
  }

  /// Animates the widget from left to right (slide in).
  Widget animateLeftToRight({Duration? duration, double delay = 0}) {
    return animate(delay: delay.ms)
        .slideX(
            begin: -1,
            end: 0,
            duration: duration ?? 400.ms,
            curve: Curves.easeOutCubic)
        .fadeIn(duration: duration ?? 400.ms);
  }

  /// Animates the widget from top to bottom (slide in).
  Widget animateTopToBottom({Duration? duration, double delay = 0}) {
    return animate(delay: delay.ms)
        .slideY(
            begin: -1,
            end: 0,
            duration: duration ?? 400.ms,
            curve: Curves.easeOutCubic)
        .fadeIn(duration: duration ?? 400.ms);
  }

  /// Animates the widget from bottom to top (slide in).
  Widget animateBottomToTop({Duration? duration, double delay = 0}) {
    return animate(delay: delay.ms)
        .slideY(
            begin: 1,
            end: 0,
            duration: duration ?? 400.ms,
            curve: Curves.easeOutCubic)
        .fadeIn(duration: duration ?? 400.ms);
  }

  /// Animates the widget with a simple fade in.
  Widget animateFadeIn({Duration? duration, double delay = 0}) {
    return animate(delay: delay.ms)
        .fadeIn(duration: duration ?? 400.ms, curve: Curves.easeOutCubic);
  }

  /// Animates the widget with a scale in.
  Widget animateScaleIn({Duration? duration, double delay = 0}) {
    return animate(delay: delay.ms)
        .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: duration ?? 400.ms,
            curve: Curves.easeOutBack)
        .fadeIn(duration: duration ?? 400.ms);
  }
}

/// A wrapper widget that animates its child from bottom to top with a staggered delay based on its index.
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final double delayMilliseconds;
  final Duration duration;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayMilliseconds = 50,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: (index * delayMilliseconds).ms)
        .slideY(
            begin: 0.5, end: 0, duration: duration, curve: Curves.easeOutCubic)
        .fadeIn(duration: duration);
  }
}

Future<T?> showSleekDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color barrierColor = const Color(0x80000000),
  String? barrierLabel,
  Duration transitionDuration = const Duration(milliseconds: 400),
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );

      return ScaleTransition(
        scale: curvedAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

/// A Column that automatically applies staggered animations to its children.
/// Spacers like [SizedBox] and [Divider] are ignored when calculating staggered delays.
class AnimatedColumn extends StatelessWidget {
  final List<Widget> children;
  final double delayMilliseconds;
  final Duration? duration;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AnimatedColumn({
    super.key,
    required this.children,
    this.delayMilliseconds = 50,
    this.duration,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    int animatableIndex = 0;
    final animatedChildren = children.map((child) {
      if (child is SizedBox || child is Divider) {
        return child;
      }
      final currentIndex = animatableIndex;
      animatableIndex++;
      return StaggeredListItem(
        index: currentIndex,
        delayMilliseconds: delayMilliseconds,
        duration: duration ?? const Duration(milliseconds: 400),
        child: child,
      );
    }).toList();

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: animatedChildren,
    );
  }
}

/// A Row that automatically applies staggered animations to its children.
/// Spacers like [SizedBox] and [VerticalDivider] are ignored when calculating staggered delays.
class AnimatedRow extends StatelessWidget {
  final List<Widget> children;
  final double delayMilliseconds;
  final Duration? duration;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AnimatedRow({
    super.key,
    required this.children,
    this.delayMilliseconds = 50,
    this.duration,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    int animatableIndex = 0;
    final animatedChildren = children.map((child) {
      if (child is SizedBox || child is VerticalDivider) {
        return child;
      }
      final currentIndex = animatableIndex;
      animatableIndex++;
      return StaggeredListItem(
        index: currentIndex,
        delayMilliseconds: delayMilliseconds,
        duration: duration ?? const Duration(milliseconds: 400),
        child: child,
      );
    }).toList();

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: animatedChildren,
    );
  }
}

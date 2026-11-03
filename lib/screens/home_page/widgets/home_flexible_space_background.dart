import 'package:flutter/material.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';

class HomeFlexibleSpaceBackground extends StatelessWidget {
  final bool isImageEmpty;
  final String backgroundImagePath;
  final String? backgroundColor;

  const HomeFlexibleSpaceBackground({
    super.key,
    required this.isImageEmpty,
    required this.backgroundImagePath,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!isImageEmpty && backgroundImagePath.isNotEmpty) {
      child = CustomImageContainer(
        key: ValueKey('image_$backgroundImagePath'),
        imagePath: backgroundImagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.fill,
        placeholder: ShimmerWidget.rectangular(
          height: double.infinity,
          width: double.infinity,
          isBorder: false,
        ),
      );
    } else {
      child = _buildGradientBackground();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: child,
    );
  }

  Widget _buildGradientBackground() {
    Color primaryColor = AppTheme.primaryColor;
    if (backgroundColor != null) {
      Color? categoryColor = hexStringToColor(backgroundColor);
      if (categoryColor != null) {
        primaryColor = categoryColor;
      }
    }
    return Container(
      key: ValueKey('gradient_${backgroundColor ?? "default"}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }
}

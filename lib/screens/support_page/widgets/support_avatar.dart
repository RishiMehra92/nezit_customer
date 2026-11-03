import 'package:flutter/material.dart';

class SupportAvatar extends StatelessWidget {
  const SupportAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 15,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final background =
        backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer;
    final foreground =
        foregroundColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final url = imageUrl?.trim();

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: url?.isNotEmpty == true
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Initials(
                name: name,
                color: foreground,
                fontSize: radius * .68,
              ),
            )
          : _Initials(
              name: name,
              color: foreground,
              fontSize: radius * .68,
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.name,
    required this.color,
    required this.fontSize,
  });

  final String name;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final initials = words.map((word) => word[0]).take(2).join().toUpperCase();
    return Center(
      child: Text(
        initials.isEmpty ? 'S' : initials,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

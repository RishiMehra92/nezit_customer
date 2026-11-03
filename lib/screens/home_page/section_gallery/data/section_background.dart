import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../utils/widgets/cache_manager.dart';

/// What kind of background a section paints behind its content.
enum SectionBackgroundType { none, color, image }

/// Describes a section's background — either nothing, a solid color, or an
/// image (asset or network). Built as one value object so a section only needs
/// a single `background` field, and so the future unified home API can map its
/// per-section background config straight onto this.
class SectionBackground {
  final SectionBackgroundType type;
  final Color? color;

  /// Asset path or network URL, depending on [isAsset].
  final String? image;
  final bool isAsset;
  final BoxFit fit;

  /// Optional tint painted over the image (e.g. for text legibility).
  final Color? scrim;

  const SectionBackground._({
    required this.type,
    this.color,
    this.image,
    this.isAsset = false,
    this.fit = BoxFit.cover,
    this.scrim,
  });

  const SectionBackground.none() : this._(type: SectionBackgroundType.none);

  const SectionBackground.color(Color color) : this._(type: SectionBackgroundType.color, color: color);

  const SectionBackground.networkImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    Color? scrim,
  }) : this._(
          type: SectionBackgroundType.image,
          image: url,
          isAsset: false,
          fit: fit,
          scrim: scrim,
        );

  const SectionBackground.assetImage(
    String path, {
    BoxFit fit = BoxFit.cover,
    Color? scrim,
  }) : this._(
          type: SectionBackgroundType.image,
          image: path,
          isAsset: true,
          fit: fit,
          scrim: scrim,
        );

  bool get hasBackground => type != SectionBackgroundType.none;

  /// Returns a [Decoration] for this background, or null when there is none.
  Decoration? toDecoration() {
    switch (type) {
      case SectionBackgroundType.none:
        return null;
      case SectionBackgroundType.color:
        return BoxDecoration(color: color);
      case SectionBackgroundType.image:
        final ImageProvider provider;
        if (isAsset) {
          provider = AssetImage(image!);
        } else {
          provider = CachedNetworkImageProvider(
            image!,
            cacheManager: customCacheManager,
          );
        }
        return BoxDecoration(
          image: DecorationImage(
            image: provider,
            fit: fit,
            colorFilter: scrim != null ? ColorFilter.mode(scrim!, BlendMode.srcOver) : null,
          ),
        );
    }
  }
}

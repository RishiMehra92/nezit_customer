import 'dart:convert';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart' show ProductData;
import 'package:hyper_local/screens/discover_page/model/discover_status_model.dart';
import 'package:hyper_local/screens/discover_page/model/discover_reel_model.dart';
import '../../model/brands_model.dart';
import '../../model/category_model.dart';

class HomeLayoutResponse {
  final bool success;
  final String message;
  final String scopeType;
  final int? scopeId;
  final List<HomeSection> sections;

  HomeLayoutResponse({
    required this.success,
    required this.message,
    required this.scopeType,
    required this.scopeId,
    required this.sections,
  });

  factory HomeLayoutResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rawSections = (data['sections'] as List?) ?? const [];
    return HomeLayoutResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      scopeType: data['scope_type']?.toString() ?? 'global',
      scopeId: data['scope_id'] is int ? data['scope_id'] as int : null,
      sections: rawSections
          .whereType<Map>()
          .map((e) => HomeSection.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class HomeSection {
  final int id;
  final String type; // hero | categories | banners | brands | products
  final String? title;
  final String? style;
  final dynamic config; // Map or List depending on type
  final String? backgroundImage;
  final String? heroMedia;
  final String? cardBackgroundImage;
  final Map<String, dynamic> content;

  HomeSection({
    required this.id,
    required this.type,
    required this.title,
    required this.style,
    required this.config,
    required this.backgroundImage,
    required this.heroMedia,
    required this.cardBackgroundImage,
    required this.content,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      id: json['id'] is int ? json['id'] as int : 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString(),
      style: json['style']?.toString(),
      config: json['config'],
      backgroundImage: json['background_image']?.toString(),
      heroMedia: json['hero_media']?.toString(),
      cardBackgroundImage: json['card_background_image']?.toString(),
      content: (json['content'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  String? configStr(String key) {
    if (config is Map && (config as Map)[key] != null) {
      return (config as Map)[key].toString();
    }
    return null;
  }

  List<dynamic> _list(String key) => (content[key] is List) ? content[key] as List : const [];

  List<HeroItem> get heroItems => _list('items')
      .whereType<Map>()
      .map((e) => HeroItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<BannerItem> get bannerItems => _list('items')
      .whereType<Map>()
      .map((e) => BannerItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<CategoryData> get categories => _list('categories')
      .whereType<Map>()
      .map((e) => CategoryData.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<BrandData> get brands => _list('brands')
      .whereType<Map>()
      .map((e) => BrandData.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<ProductData> get products => _list('products')
      .whereType<Map>()
      .map((e) => ProductData.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<DiscoverStatusItem> get stories => _list('stories')
      .whereType<Map>()
      .map((e) => DiscoverStatusItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  StoriesSectionConfig get storiesConfig => (config is Map)
      ? StoriesSectionConfig.fromJson((config as Map).cast<String, dynamic>())
      : StoriesSectionConfig();

  List<DiscoverReelItem> get reels => _list('reels')
      .whereType<Map>()
      .map((e) => DiscoverReelItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  ReelsSectionConfig get reelsConfig => (config is Map)
      ? ReelsSectionConfig.fromJson((config as Map).cast<String, dynamic>())
      : ReelsSectionConfig();

  PlayImageSectionConfig get playImageConfig => (config is Map)
      ? PlayImageSectionConfig.fromJson((config as Map).cast<String, dynamic>())
      : PlayImageSectionConfig();

  List<PlayImageRow> get playImageRows {
    final rowsRaw = _list('rows');
    final sectionConfig = playImageConfig;
    if (rowsRaw.isNotEmpty) {
      return rowsRaw
          .whereType<Map>()
          .toList()
          .asMap()
          .entries
          .map((e) {
            final rowMap = e.value.cast<String, dynamic>();
            final rowIndex = e.key;
            final sectionRowConfig = (sectionConfig.rows.length > rowIndex)
                ? sectionConfig.rows[rowIndex]
                : null;
            return PlayImageRow.fromJson(
              rowMap,
              indexFallback: rowIndex,
              fallbackConfig: sectionRowConfig,
              sectionAspectRatio: sectionConfig.aspectRatio,
            );
          })
          .toList();
    }
    final itemsRaw = _list('items');
    if (itemsRaw.isNotEmpty) {
      final items = itemsRaw
          .whereType<Map>()
          .map((e) => PlayImageItem.fromJson(
                e.cast<String, dynamic>(),
                fallbackAspectRatio: sectionConfig.aspectRatio,
              ))
          .toList();
      return [
        PlayImageRow(
          rowIndex: 0,
          style: style ?? 'grid',
          config: PlayImageRowConfig.fromJson((config is Map)
              ? (config as Map).cast<String, dynamic>()
              : null),
          items: items,
        ),
      ];
    }
    return const [];
  }
}

class HeroItem {
  final int id;
  final String title;
  final String? image;
  final String? defaultImage;
  final String type;
  final int? targetId;
  final String slug;

  HeroItem({
    required this.id,
    required this.title,
    required this.image,
    required this.defaultImage,
    required this.type,
    required this.targetId,
    required this.slug,
  });

  factory HeroItem.fromJson(Map<String, dynamic> json) => HeroItem(
        id: json['id'] is int ? json['id'] as int : 0,
        title: json['title']?.toString() ?? '',
        image: (json['image']?.toString().isNotEmpty ?? false) ? json['image'].toString() : null,
        defaultImage: (json['default_image']?.toString().isNotEmpty ?? false) ? json['default_image'].toString() : null,
        type: json['type']?.toString() ?? '',
        targetId: json['target_id'] is int ? json['target_id'] as int : null,
        slug: json['slug']?.toString() ?? '',
      );
}

class BannerItem {
  final int id;
  final String image;
  final String? linkType;
  final String? linkUrl;
  final int? targetId;
  final String? slug;

  BannerItem({
    required this.id,
    required this.image,
    required this.linkType,
    required this.linkUrl,
    required this.targetId,
    required this.slug,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
        id: json['id'] is int ? json['id'] as int : 0,
        image: json['image']?.toString() ?? '',
        linkType: json['link_type']?.toString(),
        linkUrl: json['link_url']?.toString(),
        targetId: json['target_id'] is int ? json['target_id'] as int : null,
        slug: json['slug']?.toString(),
      );
}


class PlayImageSectionConfig {
  final double outerPadding;
  final double gridGap;
  final double borderRadius;
  final String hoverEffect;
  final double itemsToShow;
  final double itemsToShowMobile;
  final bool showScrollButtons;
  final bool showBullets;
  final bool autoScroll;
  final int autoScrollTime;
  final List<PlayImageRowConfig> rows;
  final String? legacyBannerStyle;
  final String? aspectRatio;

  PlayImageSectionConfig({
    this.outerPadding = 0,
    this.gridGap = 0,
    this.borderRadius = 0,
    this.hoverEffect = 'none',
    this.itemsToShow = 2.0,
    this.itemsToShowMobile = 1.0,
    this.showScrollButtons = false,
    this.showBullets = false,
    this.autoScroll = false,
    this.autoScrollTime = 3,
    this.rows = const [],
    this.legacyBannerStyle,
    this.aspectRatio,
  });

  factory PlayImageSectionConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PlayImageSectionConfig();
    final sectionAutoScroll = _toBool(json['auto_scroll']);
    final sectionAutoScrollTime = _toInt(json['auto_scroll_time'], 3);
    final sectionShowBullets = _toBool(json['show_bullets']);
    final sectionShowScrollButtons = _toBool(json['show_scroll_buttons']);
    final sectionOuterPadding = _toDouble(json['outer_padding'], 0);
    final sectionGridGap = _toDouble(json['grid_gap'], 0);
    final sectionBorderRadius = _toDouble(json['border_radius'], 0);
    final sectionHoverEffect = json['hover_effect']?.toString() ?? 'none';
    final sectionItemsToShow = _toDouble(json['items_to_show'], 2.0);
    final sectionItemsToShowMobile = _toDouble(json['items_to_show_mobile'], 1.0);
    final sectionAspectRatio = (json['aspect_ratio'] ?? json['aspectRatio'])?.toString();

    final sectionFallback = PlayImageRowConfig(
      autoScroll: sectionAutoScroll,
      autoScrollTime: sectionAutoScrollTime,
      showBullets: sectionShowBullets,
      showScrollButtons: sectionShowScrollButtons,
      outerPadding: sectionOuterPadding,
      gridGap: sectionGridGap,
      borderRadius: sectionBorderRadius,
      hoverEffect: sectionHoverEffect,
      itemsToShow: sectionItemsToShow,
      itemsToShowMobile: sectionItemsToShowMobile,
      aspectRatio: sectionAspectRatio,
    );

    final rowsRaw = json['rows'] as List?;
    final parsedRows = (rowsRaw != null)
        ? rowsRaw
            .whereType<Map>()
            .map((e) => PlayImageRowConfig.fromJson(
                  e.cast<String, dynamic>(),
                  fallback: sectionFallback,
                ))
            .toList()
        : <PlayImageRowConfig>[];

    return PlayImageSectionConfig(
      outerPadding: sectionOuterPadding,
      gridGap: sectionGridGap,
      borderRadius: sectionBorderRadius,
      hoverEffect: sectionHoverEffect,
      itemsToShow: sectionItemsToShow,
      itemsToShowMobile: sectionItemsToShowMobile,
      showScrollButtons: sectionShowScrollButtons,
      showBullets: sectionShowBullets,
      autoScroll: sectionAutoScroll,
      autoScrollTime: sectionAutoScrollTime,
      rows: parsedRows,
      legacyBannerStyle: json['_legacy_banner_style']?.toString(),
      aspectRatio: sectionAspectRatio,
    );
  }
}

class PlayImageRow {
  final int rowIndex;
  final String? title;
  final String style; // 'grid' | 'scroll'
  final PlayImageRowConfig config;
  final List<PlayImageItem> items;

  PlayImageRow({
    required this.rowIndex,
    this.title,
    required this.style,
    required this.config,
    required this.items,
  });

  factory PlayImageRow.fromJson(
    Map<String, dynamic> json, {
    int indexFallback = 0,
    PlayImageRowConfig? fallbackConfig,
    String? sectionAspectRatio,
  }) {
    Map<String, dynamic>? rawConfig;
    if (json['config'] is Map) {
      rawConfig = (json['config'] as Map).cast<String, dynamic>();
    } else if (json['config'] is String && (json['config'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['config'] as String);
        if (decoded is Map) rawConfig = decoded.cast<String, dynamic>();
      } catch (_) {}
    }

    final parsedConfig = rawConfig != null
        ? PlayImageRowConfig.fromJson(rawConfig, fallback: fallbackConfig)
        : (fallbackConfig ?? PlayImageRowConfig());

    final rawItems = (json['items'] as List?) ?? const [];
    final rowStyle = json['style']?.toString() ??
        rawConfig?['style']?.toString() ??
        fallbackConfig?.style ??
        'grid';

    final effectiveAspectRatio = parsedConfig.aspectRatio ?? sectionAspectRatio;

    return PlayImageRow(
      rowIndex: _toInt(json['row_index'], indexFallback),
      title: json['title']?.toString() ?? rawConfig?['title']?.toString(),
      style: rowStyle,
      config: parsedConfig,
      items: rawItems
          .whereType<Map>()
          .map((e) => PlayImageItem.fromJson(
                e.cast<String, dynamic>(),
                fallbackAspectRatio: effectiveAspectRatio,
              ))
          .toList(),
    );
  }
}

class PlayImageRowConfig {
  final String style;
  final String containerWidth;
  final double outerPadding;
  final String? outerPaddingCustom;
  final double gridGap;
  final double borderRadius;
  final String hoverEffect;
  final double itemsToShow;
  final double itemsToShowMobile;
  final bool showScrollButtons;
  final bool showBullets;
  final bool autoScroll;
  final int autoScrollTime;
  final String? mediaKey;
  final String? backgroundImage;
  final String? aspectRatio;

  PlayImageRowConfig({
    this.style = 'grid',
    this.containerWidth = 'container',
    this.outerPadding = 0,
    this.outerPaddingCustom,
    this.gridGap = 0,
    this.borderRadius = 0,
    this.hoverEffect = 'none',
    this.itemsToShow = 2.0,
    this.itemsToShowMobile = 1.0,
    this.showScrollButtons = false,
    this.showBullets = false,
    this.autoScroll = false,
    this.autoScrollTime = 3,
    this.mediaKey,
    this.backgroundImage,
    this.aspectRatio,
  });

  factory PlayImageRowConfig.fromJson(
    Map<String, dynamic>? json, {
    PlayImageRowConfig? fallback,
  }) {
    if (json == null) return fallback ?? PlayImageRowConfig();
    return PlayImageRowConfig(
      style: json['style']?.toString() ?? fallback?.style ?? 'grid',
      containerWidth: json['container_width']?.toString() ?? fallback?.containerWidth ?? 'container',
      outerPadding: json['outer_padding'] != null
          ? _toDouble(json['outer_padding'], 0)
          : (fallback?.outerPadding ?? 0),
      outerPaddingCustom: json['outer_padding_custom']?.toString() ?? fallback?.outerPaddingCustom,
      gridGap: json['grid_gap'] != null
          ? _toDouble(json['grid_gap'], 0)
          : (fallback?.gridGap ?? 0),
      borderRadius: json['border_radius'] != null
          ? _toDouble(json['border_radius'], 0)
          : (fallback?.borderRadius ?? 0),
      hoverEffect: json['hover_effect']?.toString() ?? fallback?.hoverEffect ?? 'none',
      itemsToShow: json['items_to_show'] != null
          ? _toDouble(json['items_to_show'], 2.0)
          : (fallback?.itemsToShow ?? 2.0),
      itemsToShowMobile: json['items_to_show_mobile'] != null
          ? _toDouble(json['items_to_show_mobile'], 1.0)
          : (fallback?.itemsToShowMobile ?? 1.0),
      showScrollButtons: json['show_scroll_buttons'] != null
          ? _toBool(json['show_scroll_buttons'])
          : (fallback?.showScrollButtons ?? false),
      showBullets: json['show_bullets'] != null
          ? _toBool(json['show_bullets'])
          : (fallback?.showBullets ?? false),
      autoScroll: json['auto_scroll'] != null
          ? _toBool(json['auto_scroll'])
          : (fallback?.autoScroll ?? false),
      autoScrollTime: json['auto_scroll_time'] != null
          ? _toInt(json['auto_scroll_time'], 3)
          : (fallback?.autoScrollTime ?? 3),
      mediaKey: json['media_key']?.toString() ?? fallback?.mediaKey,
      backgroundImage: json['background_image']?.toString() ?? fallback?.backgroundImage,
      aspectRatio: (json['aspect_ratio'] ?? json['aspectRatio'])?.toString() ?? fallback?.aspectRatio,
    );
  }
}

class PlayImageItem {
  final int id;
  final String image;
  final String? mobileImage;
  final String? linkType;
  final String? linkUrl;
  final int? targetId;
  final String? slug;
  final PlayImageItemConfig config;

  PlayImageItem({
    required this.id,
    required this.image,
    required this.mobileImage,
    required this.linkType,
    required this.linkUrl,
    required this.targetId,
    required this.slug,
    required this.config,
  });

  factory PlayImageItem.fromJson(
    Map<String, dynamic> json, {
    String? fallbackAspectRatio,
  }) {
    Map<String, dynamic>? rawConfig;
    if (json['config'] is Map) {
      rawConfig = (json['config'] as Map).cast<String, dynamic>();
    } else if (json['config'] is String && (json['config'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['config'] as String);
        if (decoded is Map) rawConfig = decoded.cast<String, dynamic>();
      } catch (_) {}
    }

    return PlayImageItem(
      id: _toInt(json['id'], 0),
      image: json['image']?.toString() ?? '',
      mobileImage: (json['mobile_image']?.toString().isNotEmpty ?? false)
          ? json['mobile_image'].toString()
          : (json['mobileImage']?.toString().isNotEmpty ?? false)
              ? json['mobileImage'].toString()
              : null,
      linkType: (json['link_type'] ?? json['linkType'])?.toString(),
      linkUrl: (json['link_url'] ?? json['linkUrl'])?.toString(),
      targetId: _toIntNullable(json['target_id'] ?? json['targetId']),
      slug: json['slug']?.toString(),
      config: PlayImageItemConfig.fromJson(
        rawConfig,
        itemRootJson: json,
        fallbackAspectRatio: fallbackAspectRatio,
      ),
    );
  }
}

class PlayImageItemConfig {
  final String? rowIndex;
  final String cols;
  final String colsMobile;
  final String aspectRatio;
  final double? parsedAspectRatio;
  final String? mediaType;

  PlayImageItemConfig({
    this.rowIndex,
    this.cols = 'auto',
    this.colsMobile = 'auto',
    this.aspectRatio = 'original',
    this.mediaType,
    this.parsedAspectRatio,
  });

  factory PlayImageItemConfig.fromJson(
    Map<String, dynamic>? json, {
    Map<String, dynamic>? itemRootJson,
    String? fallbackAspectRatio,

  }) {


    final raw = json ?? const {};
    final root = itemRootJson ?? const {};

    final ratioStr = parseString(raw['aspect_ratio']).toString();
    final rowIndex = raw['row_index']?.toString() ?? root['row_index']?.toString();
    final cols = raw['cols']?.toString() ?? root['cols']?.toString() ?? 'auto';
    final colsMobile = raw['cols_mobile']?.toString() ??
        root['cols_mobile']?.toString() ??
        raw['colsMobile']?.toString() ??
        root['colsMobile']?.toString() ??
        cols;
    final aspectRatio = raw['aspect_ratio']?.toString() ??
        root['aspect_ratio']?.toString() ??
        raw['aspectRatio']?.toString() ??
        root['aspectRatio']?.toString() ??
        fallbackAspectRatio ??
        'original';
    final mediaType = raw['media_type']?.toString() ??
        root['media_type']?.toString() ??
        raw['mediaType']?.toString() ??
        root['mediaType']?.toString();

    return PlayImageItemConfig(
      rowIndex: rowIndex,
      cols: cols,
      colsMobile: colsMobile,
      aspectRatio: aspectRatio,
      mediaType: mediaType,
      parsedAspectRatio: parseAspectRatio(ratioStr),
    );
  }
}

double? parseAspectRatio(String? ratioStr) {
  if (ratioStr == null) return null;
  final clean = ratioStr.trim().toLowerCase();
  if (clean.isEmpty || clean == 'original' || clean == 'auto') {
    return null;
  }
  final delimiter = clean.contains(':')
      ? ':'
      : clean.contains('/')
      ? '/'
      : clean.contains('x')
      ? 'x'
      : null;

  if (delimiter != null) {
    final parts = clean.split(delimiter);
    if (parts.length == 2) {
      final width = double.tryParse(parts[0].trim());
      final height = double.tryParse(parts[1].trim());
      if (width != null && height != null && height > 0) {
        return width / height;
      }
    }
  }
  return double.tryParse(clean);
}

// ── parsing helpers ────────────────────────────────────────────────────────
double _toDouble(dynamic val, double fallback) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? fallback;
}

int _toInt(dynamic val, int fallback) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
}

int? _toIntNullable(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString());
}

bool _toBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  final s = val.toString().trim().toLowerCase();
  return s == '1' || s == 'true' || s == 'yes';
}

// ── Stories Section Models ──────────────────────────────────────────────
class StoriesSectionConfig {
  final String? ringColor;
  final String? limit;
  final bool showProfileName;

  StoriesSectionConfig({
    this.ringColor,
    this.limit,
    this.showProfileName = false,
  });

  factory StoriesSectionConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StoriesSectionConfig();
    return StoriesSectionConfig(
      ringColor: json['ring_color']?.toString(),
      limit: json['limit']?.toString(),
      showProfileName: _toBool(json['show_profile_name']),
    );
  }
}

// ── Reels Section Models ──────────────────────────────────────────────
class ReelsSectionConfig {
  final String? source;
  final String? limit;
  final bool showLikes;
  final bool showTitle;

  ReelsSectionConfig({
    this.source,
    this.limit,
    this.showLikes = false,
    this.showTitle = false,
  });

  factory ReelsSectionConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ReelsSectionConfig();
    return ReelsSectionConfig(
      source: json['source']?.toString(),
      limit: json['limit']?.toString(),
      showLikes: _toBool(json['show_likes']),
      showTitle: _toBool(json['show_title']),
    );
  }
}

// ── Categories Section Models ──────────────────────────────────────────────

import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hyper_local/config/helper.dart';
import '../../../../router/app_routes.dart';
import '../../../product_listing_page/model/product_listing_type.dart';

import '../../section_gallery/data/sample_section_data.dart';
import '../../section_gallery/data/section_background.dart';
import '../../section_gallery/widgets/brands/brand_section.dart';
import '../../section_gallery/widgets/categories/category_section.dart';
import '../../section_gallery/widgets/hero/hero_section_style.dart';

import '../model/home_layout_models.dart';
import '../../widgets/sections/play_image/play_image_section.dart';
import 'dynamic_product_section.dart';
import 'home_stories_section.dart';
import 'home_reels_section.dart';


class HomeLayoutBody extends StatelessWidget {
  final List<HomeSection> sections;
  const HomeLayoutBody({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    log('🏗️ HomeLayoutBody build() called with ${sections.length} sections');
    return SliverMainAxisGroup(
      slivers: [
        for (var i = 0; i < sections.length; i++) 
          sections[i].type == 'products' 
              ? _section(context, sections[i], i)
              : SliverToBoxAdapter(child: _section(context, sections[i], i)),
        SliverToBoxAdapter(child: SizedBox(height: 30.h)),
      ],
    );
  }

  Widget _section(BuildContext context, HomeSection s, int index) {
    switch (s.type) {
      case 'hero':
        return _hero(context, s);
      case 'categories':
        return _categories(context, s);
      case 'play_image':
        return _playImage(context, s);
      case 'brands':
        return _brands(context, s);
      case 'products':
        return _products(context, s);
      case 'stories':
        return _stories(context, s);
      case 'reels':
        return _reels(context, s);
      default:
        return const SizedBox.shrink();
    }
  }

  void _openListing(
    BuildContext context, {
    required ProductListingType type,
    required String? slug,
    String? title,
    String? logo,
    bool isTheirMoreCategory = false,
  }) {
    if (slug == null || slug.isEmpty) return;
    GoRouter.of(context).push(AppRoutes.productListing, extra: {
      'type': type,
      'identifier': slug,
      'title': title ?? '',
      'logo': logo ?? '',
      'isTheirMoreCategory': isTheirMoreCategory,
    });
  }

  void _openSeeAll(BuildContext context, HomeSection s) {
    GoRouter.of(context).push(AppRoutes.sectionSeeAll, extra: {
      'section-id': s.id,
      'type': s.type,
      'title': s.type == 'brands'
          ? (s.title != null && s.title!.isNotEmpty ? s.title! : context.tr('brand'))
          : (s.title != null && s.title!.isNotEmpty ? s.title! : context.tr('categories')),
    });
  }

  void _openProductSeeAll(BuildContext context, HomeSection s) {
    GoRouter.of(context).push(AppRoutes.productSectionSeeAll, extra: {
      'section-id': s.id,
      'title': s.title ?? 'Products',
    });
  }

  void _openHeroItem(BuildContext context, HeroItem it) {
    if (it.type == 'product') {
      if (it.slug.isEmpty) return;
      GoRouter.of(context).push(AppRoutes.productDetailPage, extra: {
        'productSlug': it.slug,
        'title': it.title,
        'mainImage': it.defaultImage ?? '',
      });
      return;
    }
    _openListing(
      context,
      type: it.type == 'brand' ? ProductListingType.brand : ProductListingType.category,
      slug: it.slug,
      title: it.title,
      logo: it.defaultImage,
    );
  }

  void _openPlayImageItem(BuildContext context, PlayImageItem item) {
    if (item.linkType == 'product') {
      final slug = item.slug ?? '';
      if (slug.isEmpty) return;
      GoRouter.of(context).push(AppRoutes.productDetailPage, extra: {
        'productSlug': slug,
        'title': '',
        'mainImage': item.image,
      });
      return;
    }
    if (item.linkType == 'category') {
      _openListing(
        context,
        type: ProductListingType.category,
        slug: item.slug,
        title: '',
        logo: item.image,
      );
      return;
    }
    if (item.linkType == 'brand') {
      _openListing(
        context,
        type: ProductListingType.brand,
        slug: item.slug,
        title: '',
        logo: item.image,
      );
      return;
    }
    if (item.linkType == 'url' || (item.linkUrl?.isNotEmpty ?? false)) {
      final url = item.linkUrl ?? '';
      if (url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      return;
    }
  }

  Widget _playImage(BuildContext context, HomeSection s) {
    return Column(
      children: [
        PlayImageSection(
          section: s,
          onItemTap: (item) => _openPlayImageItem(context, item),
        ),
        SizedBox(height: 15.h),
      ],
    );
  }

  Widget _hero(BuildContext context, HomeSection s) {
    final mediaType = s.configStr('media_type');
    final layout = s.configStr('layout') == 'items' ? HeroLayout.withItems : HeroLayout.bannerOnly;
    final cards = s.heroItems
        .map((it) => HeroPromoCard(
              title: it.title,
              imageUrls: it.image != null ? [it.image!] : const [],
              onTap: () => _openHeroItem(context, it),
            ))
        .toList();

    return HeroSectionStyle(
      bgType: mediaType == 'lottie' ? 'animation' : 'image',
      bgPath: s.heroMedia ?? s.backgroundImage ?? '',
      layout: layout,
      cards: cards,
      cardBgType: s.configStr('card_bg_type'),
      cardBgColor: hexStringToColor(s.configStr('card_bg_color')),
      cardBgImage: s.cardBackgroundImage,
      cardTitleColor: hexStringToColor(s.configStr('card_title_color')),
      cardStyle: _heroStyle(s.style),
      spacing: HeroSpacing.fromConfig(s.config),
    );
  }

  HeroCardStyle _heroStyle(String? style) {
    return style == 'full' ? HeroCardStyle.full : HeroCardStyle.imageTitle;
  }

  Widget _categories(BuildContext context, HomeSection s) {
    final tiles = s.categories
        .map((c) => SampleTile(
              name: c.title ?? '',
              imageUrl: c.image ?? '',
              onTap: () => _openListing(
                context,
                type: ProductListingType.category,
                slug: c.slug,
                title: c.title,
                logo: c.image,
                isTheirMoreCategory: (c.subcategoryCount ?? 0) > 0,
              ),
            ))
        .toList();

    final isDark = isDarkMode(context);
    final bgColorVal = s.config is Map ? (s.config as Map)['background_color'] : null;
    final textColorVal = s.config is Map ? (s.config as Map)['text_color'] : null;

    final bgColor = parseThemeColor(bgColorVal, isDark);
    final textColor = parseThemeColor(textColorVal, isDark);

    final bgType = s.configStr('background_type')?.toLowerCase();
    SectionBackground background = const SectionBackground.none();
    if (bgType == 'color') {
      final color = bgColor ?? hexStringToColor(s.configStr('background_color'));
      if (color != null) background = SectionBackground.color(color);
    } else if (bgType == 'image' && (s.backgroundImage?.isNotEmpty ?? false)) {
      background = SectionBackground.networkImage(s.backgroundImage!);
    }
    final outerPadding = parseOuterPadding(s.config);
    final horizontalGap = parseItemGapHorizontal(s.config);
    final verticalGap = parseItemGapVertical(s.config);

    final categorySectionWidget = CategorySection(
      title: s.title ?? '',
      categories: tiles,
      style: _categoryStyle(s.style),
      background: background,
      onSeeAll: () => _openSeeAll(context, s),
      isGrid: s.configStr('rows_layout') == 'grid',
      gridColumns: int.tryParse(s.configStr('grid_columns') ?? '') ?? 3,
      outerPadding: outerPadding,
      horizontalGap: horizontalGap,
      verticalGap: verticalGap,
      textColor: textColor,
    );

    if (outerPadding != null) {
      return categorySectionWidget;
    }

    return categorySectionWidget;
  }

  CategoryCardStyle _categoryStyle(String? style) {
    switch (style) {
      case 'overlay':
        return CategoryCardStyle.overlayTitle;
      case 'full':
        return CategoryCardStyle.imageCards;
      case 'custom_image':
        return CategoryCardStyle.customImage;
      default:
        return CategoryCardStyle.grid;
    }
  }



  Widget _brands(BuildContext context, HomeSection s) {
    final tiles = s.brands
        .map((b) => SampleTile(
              name: b.title ?? '',
              imageUrl: b.logo ?? '',
              onTap: () => _openListing(
                context,
                type: ProductListingType.brand,
                slug: b.slug,
                title: b.title,
                logo: b.logo,
              ),
            ))
        .toList();

    final outerPadding = parseOuterPadding(s.config);
    final borderRadius = parseBorderRadius(s.config);
    final horizontalGap = parseItemGapHorizontal(s.config);
    final verticalGap = parseItemGapVertical(s.config);

    final isDark = isDarkMode(context);
    final bgColorVal = s.config is Map ? (s.config as Map)['background_color'] : null;
    final bgColor = parseThemeColor(bgColorVal, isDark) ?? hexStringToColor(s.configStr('background_color'));

    final bgType = s.configStr('background_type')?.toLowerCase();
    SectionBackground background = const SectionBackground.none();
    if (bgType == 'color') {
      if (bgColor != null) background = SectionBackground.color(bgColor);
    } else if (bgType == 'image' && (s.backgroundImage?.isNotEmpty ?? false)) {
      background = SectionBackground.networkImage(s.backgroundImage!);
    }

    final brandSectionWidget = BrandSection(
      title: s.title ?? '',
      brands: tiles,
      style: _brandStyle(s.style),
      isGrid: s.configStr('rows_layout') == 'grid',
      gridColumns: int.tryParse(s.configStr('grid_columns') ?? '') ?? 3,
      borderRadius: borderRadius,
      background: background,
      outerPadding: outerPadding,
      horizontalGap: horizontalGap,
      verticalGap: verticalGap,
      onSeeAll: () => _openSeeAll(context, s),
    );

    return brandSectionWidget;
  }

  BrandCardStyle _brandStyle(String? style) {
    switch (style) {
      case 'custom_image':
        return BrandCardStyle.customImage;
      case 'full':
        return BrandCardStyle.cards;
      default:
        return BrandCardStyle.grid;
    }
  }

  Widget _products(BuildContext context, HomeSection s) {
    final orientation = s.configStr('orientation') ?? 'horizontal';
    SectionBackground background = const SectionBackground.none();
    final isDark = isDarkMode(context);

    final bgColorVal = s.config is Map ? (s.config as Map)['background_color'] : null;
    final textColorVal = s.config is Map ? (s.config as Map)['text_color'] : null;

    final bgColor = parseThemeColor(bgColorVal, isDark);
    final textColor = parseThemeColor(textColorVal, isDark);

    // Ignore background configurations if the style is explicitly without_background
    // Ignore background configurations if the style is explicitly without_background
    final bgType = s.configStr('background_type')?.toLowerCase();
    if (bgType == 'color') {
      final color = bgColor ?? hexStringToColor(s.configStr('background_color') ?? s.configStr('card_bg_color'));
      if (color != null) background = SectionBackground.color(color);
    } else if (bgType == 'image' && (s.backgroundImage?.isNotEmpty ?? false)) {
      background = SectionBackground.networkImage(s.backgroundImage!);
    }

    final outerPadding = parseOuterPadding(s.config);
    final borderRadius = parseBorderRadius(s.config);
    final horizontalGap = parseItemGapHorizontal(s.config);
    final verticalGap = parseItemGapVertical(s.config);
    final bgImageStyle = s.configStr('background_image_style')?.toLowerCase() ?? 'full';

    if (s.products.isNotEmpty) {
      final dynamicProductWidget = DynamicProductSection(
        title: s.title ?? '',
        products: s.products,
        orientation: orientation,
        background: background,
        backgroundImageStyle: bgImageStyle,
        onSeeAll: () => _openProductSeeAll(context, s),
        outerPadding: outerPadding,
        borderRadius: borderRadius,
        horizontalGap: horizontalGap,
        verticalGap: verticalGap,
        textColor: textColor,
      );

      return dynamicProductWidget;
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _stories(BuildContext context, HomeSection s) {
    return HomeStoriesSection(section: s);
  }

  Widget _reels(BuildContext context, HomeSection s) {
    return HomeReelsSection(section: s);
  }

}

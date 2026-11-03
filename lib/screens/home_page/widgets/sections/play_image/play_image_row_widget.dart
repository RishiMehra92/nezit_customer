import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/home_page/home_layout/model/home_layout_models.dart';
import 'play_image_item_card.dart';

class PlayImageRowWidget extends StatefulWidget {
  final PlayImageRow row;
  final double sectionGridGap;
  final double sectionBorderRadius;
  final void Function(PlayImageItem item)? onItemTap;

  const PlayImageRowWidget({
    super.key,
    required this.row,
    this.sectionGridGap = 0,
    this.sectionBorderRadius = 0,
    this.onItemTap,
  });

  @override
  State<PlayImageRowWidget> createState() => _PlayImageRowWidgetState();
}

class _PlayImageRowWidgetState extends State<PlayImageRowWidget> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  final ValueNotifier<int> _currentScrollIndexNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _setupAutoScroll();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final offset = _scrollController.offset;
    final row = widget.row;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final itemsToShow = isTablet ? row.config.itemsToShow : row.config.itemsToShowMobile;
    final effectiveItemsToShow = itemsToShow > 0 ? itemsToShow : 1.0;
    final gap = row.config.gridGap > 0 ? row.config.gridGap : widget.sectionGridGap;
    final totalGaps = (effectiveItemsToShow - 1) * gap.w;
    final itemWidth = (MediaQuery.of(context).size.width - totalGaps) / effectiveItemsToShow;
    if (itemWidth > 0) {
      final newIndex = (offset / (itemWidth + gap.w)).round().clamp(0, row.items.length - 1);
      if (newIndex != _currentScrollIndexNotifier.value) {
        _currentScrollIndexNotifier.value = newIndex;
      }
    }
  }

  @override
  void didUpdateWidget(covariant PlayImageRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.config.autoScroll != widget.row.config.autoScroll ||
        oldWidget.row.config.autoScrollTime != widget.row.config.autoScrollTime) {
      _setupAutoScroll();
    }
  }

  void _setupAutoScroll() {
    _autoScrollTimer?.cancel();
    final config = widget.row.config;
    if (config.autoScroll && widget.row.items.length > 1 && widget.row.style == 'scroll') {
      final seconds = config.autoScrollTime > 0 ? config.autoScrollTime : 3;
      _autoScrollTimer = Timer.periodic(Duration(seconds: seconds), (timer) {
        if (!_scrollController.hasClients) return;
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll <= 0) return;

        final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
        final itemsToShow = isTablet ? config.itemsToShow : config.itemsToShowMobile;
        final effectiveItemsToShow = itemsToShow > 0 ? itemsToShow : 1.0;
        final gap = widget.row.config.gridGap > 0 ? widget.row.config.gridGap : widget.sectionGridGap;
        final totalGaps = (effectiveItemsToShow - 1) * gap.w;
        final itemWidth = (MediaQuery.of(context).size.width - totalGaps) / effectiveItemsToShow;

        int targetIndex = _currentScrollIndexNotifier.value + 1;
        if (targetIndex >= widget.row.items.length) {
          targetIndex = 0;
        }

        double nextOffset = targetIndex * (itemWidth + gap.w);
        if (nextOffset > maxScroll) {
          if ((_scrollController.offset - maxScroll).abs() < 5) {
            targetIndex = 0;
            nextOffset = 0;
          } else {
            nextOffset = maxScroll;
          }
        }

        _scrollController.animateTo(
          nextOffset.clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    if (row.items.isEmpty) return const SizedBox.shrink();

    final customPadding = _parsePaddingCustom(row.config.outerPaddingCustom);
    final outerPadding = row.config.outerPadding > 0 ? row.config.outerPadding : 0.0;
    final gap = row.config.gridGap > 0 ? row.config.gridGap : widget.sectionGridGap;
    final radius = row.config.borderRadius > 0 ? row.config.borderRadius : widget.sectionBorderRadius;

    Widget content;
    if (row.style == 'scroll') {
      content = _buildScrollRow(context, row, gap, radius);
    } else {
      content = _buildGridRow(context, row, gap, radius);
    }

    if (row.title != null && row.title!.isNotEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              row.title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          content,
        ],
      );
    }

    if (customPadding != null) {
      return Padding(
        padding: customPadding,
        child: content,
      );
    } else if (outerPadding > 0) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: outerPadding.w),
        child: content,
      );
    }
    return content;
  }

  EdgeInsets? _parsePaddingCustom(String? custom) {
    if (custom == null || custom.trim().isEmpty) return null;
    final parts = custom.split('/');
    if (parts.length == 4) {
      final top = double.tryParse(parts[0].trim()) ?? 0;
      final right = double.tryParse(parts[1].trim()) ?? 0;
      final bottom = double.tryParse(parts[2].trim()) ?? 0;
      final left = double.tryParse(parts[3].trim()) ?? 0;
      return EdgeInsets.only(
        top: top.h,
        right: right.w,
        bottom: bottom.h,
        left: left.w,
      );
    }
    return null;
  }

  Widget _buildGridRow(
    BuildContext context,
    PlayImageRow row,
    double gap,
    double radius,
  ) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final items = row.items;

    if (items.length == 1) {
      return PlayImageItemCard(
        item: items.first,
        borderRadius: radius,
        onTap: widget.onItemTap,
      );
    }

    final lines = _buildGridLines(items, isTablet);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) ...[
          if (lineIdx > 0 && gap > 0) SizedBox(height: gap.h),
          _buildGridLine(lines[lineIdx], gap, radius),
        ],
      ],
    );
  }

  Widget _buildGridLine(
    List<_GridLineItem> line,
    double gap,
    double radius,
  ) {
    final totalSpan = line.fold<int>(0, (sum, it) => sum + it.colSpan);
    final remainingSpan = 12 - totalSpan;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < line.length; i++) ...[
          if (i > 0 && gap > 0) SizedBox(width: gap.w),
          Expanded(
            flex: line[i].colSpan,
            child: PlayImageItemCard(
              item: line[i].item,
              borderRadius: radius,
              onTap: widget.onItemTap,
            ),
          ),
        ],
        if (remainingSpan > 0) ...[
          if (gap > 0 && line.isNotEmpty) SizedBox(width: gap.w),
          Spacer(flex: remainingSpan),
        ],
      ],
    );
  }

  List<List<_GridLineItem>> _buildGridLines(List<PlayImageItem> items, bool isTablet) {
    final List<List<_GridLineItem>> lines = [];
    List<_GridLineItem> currentLine = [];
    int currentLineSpan = 0;

    for (final item in items) {
      final colSpan = _resolveColSpan(item, isTablet, items.length);
      if (currentLineSpan + colSpan > 12 && currentLine.isNotEmpty) {
        lines.add(currentLine);
        currentLine = [];
        currentLineSpan = 0;
      }
      currentLine.add(_GridLineItem(item, colSpan));
      currentLineSpan += colSpan;
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }

  int _resolveColSpan(PlayImageItem item, bool isTablet, int totalItems) {
    final colStr = isTablet ? item.config.cols : item.config.colsMobile;
    if (colStr.isNotEmpty && colStr.toLowerCase() != 'auto') {
      final parsed = int.tryParse(colStr);
      if (parsed != null && parsed > 0) {
        return parsed.clamp(1, 12);
      }
    }
    if (totalItems <= 1) return 12;
    if (totalItems == 2) return 6;
    if (totalItems == 3) return 4;
    if (totalItems == 4) return 3;
    if (totalItems == 5 || totalItems == 6) return 2;
    return (12 ~/ totalItems).clamp(1, 12);
  }

  Widget _buildScrollRow(
    BuildContext context,
    PlayImageRow row,
    double gap,
    double radius,
  ) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final items = row.items;
    final itemsToShow = isTablet ? row.config.itemsToShow : row.config.itemsToShowMobile;
    final effectiveItemsToShow = itemsToShow > 0 ? itemsToShow : 1.5;
    final bool showBullets = row.config.showBullets && items.length > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth > 0 ? constraints.maxWidth : MediaQuery.of(context).size.width;
        final totalGaps = (effectiveItemsToShow - 1) * gap.w;
        final itemWidth = (totalWidth - totalGaps) / effectiveItemsToShow;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0 && gap > 0) SizedBox(width: gap.w),
                      SizedBox(
                        width: itemWidth > 0 ? itemWidth : 120.w,
                        child: PlayImageItemCard(
                          item: items[i],
                          borderRadius: radius,
                          onTap: widget.onItemTap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (showBullets) ...[
              SizedBox(height: 8.h),
              ValueListenableBuilder(
                valueListenable: _currentScrollIndexNotifier,
                builder: (BuildContext context, activeIdx, Widget? child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.symmetric(horizontal: 1.w),
                        height: 3.h,
                        width: activeIdx == index ? 4.w : 3.w,
                        decoration: BoxDecoration(
                          color: activeIdx == index
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(50.r),
                          // shape: BoxShape.circle
                        ),
                      ),
                    ),
                  );
                },
                child: ValueListenableBuilder(
                  valueListenable: _currentScrollIndexNotifier,
                  builder: (BuildContext context, activeIdx, Widget? child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        items.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: EdgeInsets.symmetric(horizontal: 1.w),
                          height: 3.h,
                          width: activeIdx == index ? 4.w : 3.w,
                          decoration: BoxDecoration(
                            color: activeIdx == index
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GridLineItem {
  final PlayImageItem item;
  final int colSpan;

  const _GridLineItem(this.item, this.colSpan);
}

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations_plus/flutter_staggered_animations_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

enum StaggeredListType {
  column,
  row,
  listView,
  gridView,
  masonryGridView,
}

class StaggeredListAnimator extends StatelessWidget {
  final List<Widget>? children;
  final Widget Function(BuildContext, int)? itemBuilder;
  final int? itemCount;
  final StaggeredListType type;
  final double verticalOffset;
  final double horizontalOffset;
  final Duration duration;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;
  final dynamic gridDelegate;
  final int? columnCount;
  final Axis scrollDirection;
  final ScrollController? controller;

  const StaggeredListAnimator({
    super.key,
    required List<Widget> this.children,
    this.type = StaggeredListType.column,
    this.verticalOffset = 40.0,
    this.horizontalOffset = 0.0,
    this.duration = const Duration(milliseconds: 300),
    this.physics,
    this.padding,
    this.shrinkWrap = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.gridDelegate,
    this.columnCount,
    this.scrollDirection = Axis.vertical,
    this.controller,
  })  : itemBuilder = null,
        itemCount = null;

  const StaggeredListAnimator.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.type = StaggeredListType.listView,
    this.verticalOffset = 40.0,
    this.horizontalOffset = 0.0,
    this.duration = const Duration(milliseconds: 300),
    this.physics,
    this.padding,
    this.shrinkWrap = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.gridDelegate,
    this.columnCount,
    this.scrollDirection = Axis.vertical,
    this.controller,
  }) : children = null;

  @override
  Widget build(BuildContext context) {
    final int count = itemCount ?? children?.length ?? 0;

    if (type == StaggeredListType.masonryGridView) {
      return AnimationLimiter(
        child: MasonryGridView.builder(
          controller: controller,
          physics: physics,
          padding: padding,
          shrinkWrap: shrinkWrap,
          gridDelegate: (gridDelegate as SliverSimpleGridDelegate?) ?? const SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          mainAxisSpacing: spacing ?? 0.0,
          crossAxisSpacing: spacing ?? 0.0,
          itemCount: count,
          itemBuilder: (context, index) {
            final child = itemBuilder != null ? itemBuilder!(context, index) : children![index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: duration,
              columnCount: columnCount ?? 2,
              child: SlideAnimation(
                verticalOffset: verticalOffset,
                horizontalOffset: horizontalOffset,
                curve: Curves.easeOutCubic,
                child: FadeInAnimation(
                  child: child,
                ),
              ),
            );
          },
        ),
      );
    }

    if (type == StaggeredListType.gridView) {
      assert(gridDelegate != null, 'gridDelegate is required for gridView layout');
      return AnimationLimiter(
        child: GridView.builder(
          controller: controller,
          physics: physics,
          padding: padding,
          shrinkWrap: shrinkWrap,
          gridDelegate: gridDelegate as SliverGridDelegate,
          itemCount: count,
          itemBuilder: (context, index) {
            final child = itemBuilder != null ? itemBuilder!(context, index) : children![index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: duration,
              columnCount: columnCount ?? 2,
              child: SlideAnimation(
                verticalOffset: verticalOffset,
                horizontalOffset: horizontalOffset,
                curve: Curves.easeOutCubic,
                child: FadeInAnimation(
                  child: child,
                ),
              ),
            );
          },
        ),
      );
    }

    if (type == StaggeredListType.listView) {
      return AnimationLimiter(
        child: ListView.separated(
          controller: controller,
          scrollDirection: scrollDirection,
          physics: physics,
          padding: padding,
          shrinkWrap: shrinkWrap,
          itemCount: count,
          separatorBuilder: (context, index) => spacing != null
              ? (scrollDirection == Axis.horizontal ? SizedBox(width: spacing) : SizedBox(height: spacing))
              : const SizedBox.shrink(),
          itemBuilder: (context, index) {
            final child = itemBuilder != null ? itemBuilder!(context, index) : children![index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: duration,
              child: SlideAnimation(
                verticalOffset: verticalOffset,
                horizontalOffset: horizontalOffset,
                curve: Curves.easeOutCubic,
                child: FadeInAnimation(
                  child: child,
                ),
              ),
            );
          },
        ),
      );
    }

    assert(children != null, 'StaggeredListType.column and row only support the default constructor with children.');
    final actualChildren = children!;

    final double vOffset = type == StaggeredListType.row && verticalOffset == 40.0 ? 0.0 : verticalOffset;
    final double hOffset = type == StaggeredListType.row && horizontalOffset == 0.0 ? 40.0 : horizontalOffset;

    final animatedChildren = AnimationConfiguration.toStaggeredList(
      duration: duration,
      childAnimationBuilder: (widget) => SlideAnimation(
        verticalOffset: vOffset,
        horizontalOffset: hOffset,
        curve: Curves.easeOutCubic,
        child: FadeInAnimation(
          child: widget,
        ),
      ),
      children: type == StaggeredListType.row ? actualChildren.reversed.toList() : actualChildren,
    );

    final finalChildren = <Widget>[];
    for (var i = 0; i < animatedChildren.length; i++) {
      if (type == StaggeredListType.row) {
        finalChildren.add(Expanded(child: animatedChildren[i]));
        if (i < animatedChildren.length - 1 && spacing != null) {
          finalChildren.add(SizedBox(width: spacing));
        }
      } else {
        finalChildren.add(animatedChildren[i]);
        if (i < animatedChildren.length - 1 && spacing != null) {
          finalChildren.add(SizedBox(height: spacing));
        }
      }
    }

    return AnimationLimiter(
      child: type == StaggeredListType.row
          ? Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: finalChildren,
            )
          : Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: finalChildren,
            ),
    );
  }
}

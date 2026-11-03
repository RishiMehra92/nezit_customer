  import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A render-object-based auto-shrinking text widget.
///
/// Unlike `LayoutBuilder`-based solutions (such as `AutoSizeText`),
/// [AdaptiveShrinkText] operates directly at the [RenderBox] level.
/// This means it safely supports Flutter's intrinsic dimensions calculation
/// and can be placed inside [IntrinsicHeight] or [IntrinsicWidth] widgets
/// without throwing "LayoutBuilder does not support returning intrinsic dimensions".
class AdaptiveShrinkText extends LeafRenderObjectWidget {
  final String text;
  final TextStyle? style;
  final double? maxFontSize;
  final double minFontSize;
  final double stepGranularity;
  final int maxLines; 
  final TextOverflow overflow;
  final TextAlign textAlign;

  const AdaptiveShrinkText(
    this.text, {
    super.key,
    this.style,
    this.maxFontSize,
    this.minFontSize = 8.5,
    this.stepGranularity = 0.5,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign = TextAlign.start,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle.merge(style);
    return RenderAdaptiveShrinkText(
      text: text,
      style: effectiveStyle,
      maxFontSize: maxFontSize ?? effectiveStyle.fontSize ?? 14.0,
      minFontSize: minFontSize,
      stepGranularity: stepGranularity,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderAdaptiveShrinkText renderObject) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle.merge(style);
    renderObject
      ..text = text
      ..style = effectiveStyle
      ..maxFontSize = maxFontSize ?? effectiveStyle.fontSize ?? 14.0
      ..minFontSize = minFontSize
      ..stepGranularity = stepGranularity
      ..maxLines = maxLines
      ..overflow = overflow
      ..textAlign = textAlign
      ..textDirection = Directionality.of(context)
      ..textScaler = MediaQuery.textScalerOf(context);
  }
}

class RenderAdaptiveShrinkText extends RenderBox {
  String _text;
  TextStyle _style;
  double _maxFontSize;
  double _minFontSize;
  double _stepGranularity;
  int _maxLines;
  TextOverflow _overflow;
  TextAlign _textAlign;
  TextDirection _textDirection;
  TextScaler _textScaler;

  final TextPainter _textPainter = TextPainter();

  RenderAdaptiveShrinkText({
    required String text,
    required TextStyle style,
    required double maxFontSize,
    required double minFontSize,
    required double stepGranularity,
    required int maxLines,
    required TextOverflow overflow,
    required TextAlign textAlign,
    required TextDirection textDirection,
    required TextScaler textScaler,
  })  : _text = text,
        _style = style,
        _maxFontSize = maxFontSize,
        _minFontSize = minFontSize,
        _stepGranularity = stepGranularity,
        _maxLines = maxLines,
        _overflow = overflow,
        _textAlign = textAlign,
        _textDirection = textDirection,
        _textScaler = textScaler;

  set text(String value) {
    if (_text != value) {
      _text = value;
      markNeedsLayout();
      markNeedsSemanticsUpdate();
    }
  }

  set style(TextStyle value) {
    if (_style != value) {
      _style = value;
      markNeedsLayout();
    }
  }

  set maxFontSize(double value) {
    if (_maxFontSize != value) {
      _maxFontSize = value;
      markNeedsLayout();
    }
  }

  set minFontSize(double value) {
    if (_minFontSize != value) {
      _minFontSize = value;
      markNeedsLayout();
    }
  }

  set stepGranularity(double value) {
    if (_stepGranularity != value) {
      _stepGranularity = value;
      markNeedsLayout();
    }
  }

  set maxLines(int value) {
    if (_maxLines != value) {
      _maxLines = value;
      markNeedsLayout();
    }
  }

  set overflow(TextOverflow value) {
    if (_overflow != value) {
      _overflow = value;
      markNeedsLayout();
    }
  }

  set textAlign(TextAlign value) {
    if (_textAlign != value) {
      _textAlign = value;
      markNeedsLayout();
    }
  }

  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  set textScaler(TextScaler value) {
    if (_textScaler != value) {
      _textScaler = value;
      markNeedsLayout();
    }
  }

  @override
  void dispose() {
    _textPainter.dispose();
    super.dispose();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutPainterForSize(_minFontSize, double.infinity, applyEllipsis: false);
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutPainterForSize(_maxFontSize, double.infinity, applyEllipsis: false);
    return _textPainter.maxIntrinsicWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _layoutBestFit(width);
    return _textPainter.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _layoutBestFit(width);
    return _textPainter.height;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    final maxWidth = constraints.maxWidth;
    _layoutBestFit(maxWidth);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    _layoutBestFit(maxWidth);
    return constraints.constrain(Size(_textPainter.width, _textPainter.height));
  }

  @override
  void performLayout() {
    final maxWidth = constraints.maxWidth;
    _layoutBestFit(maxWidth);
    size = constraints.constrain(Size(_textPainter.width, _textPainter.height));
  }

  void _layoutBestFit(double maxWidth) {
    final startSize = math.max(_maxFontSize, _minFontSize);
    final effectiveMin = math.min(_minFontSize, startSize);

    if (maxWidth <= 0 || maxWidth.isInfinite || startSize <= effectiveMin) {
      _layoutPainterForSize(startSize, maxWidth, applyEllipsis: true);
      return;
    }

    // Fast-path: Check if start size fits without any shrinkage
    _layoutPainterForSize(startSize, double.infinity, applyEllipsis: false);
    if (_textPainter.width <= maxWidth) {
      _layoutPainterForSize(startSize, maxWidth, applyEllipsis: true);
      return;
    }

    // Binary search for the largest font size between effectiveMin and startSize
    double low = effectiveMin;
    double high = startSize;
    double bestFit = effectiveMin;
    final step = math.max(0.1, _stepGranularity);

    while ((high - low) > step) {
      final mid = (low + high) / 2;
      _layoutPainterForSize(mid, double.infinity, applyEllipsis: false);
      if (_textPainter.width <= maxWidth) {
        bestFit = mid;
        low = mid;
      } else {
        high = mid;
      }
    }

    // Layout at the best fitting font size. If at effectiveMin it still exceeds maxWidth, apply ellipsis.
    _layoutPainterForSize(bestFit, maxWidth, applyEllipsis: true);
  }

  void _layoutPainterForSize(double fontSize, double maxWidth, {required bool applyEllipsis}) {
    _textPainter.text = TextSpan(
      text: _text,
      style: _style.copyWith(fontSize: fontSize),
    );
    _textPainter.textAlign = _textAlign;
    _textPainter.textDirection = _textDirection;
    _textPainter.textScaler = _textScaler;
    _textPainter.maxLines = _maxLines;
    _textPainter.ellipsis = (applyEllipsis && _overflow == TextOverflow.ellipsis) ? '\u2026' : null;
    _textPainter.layout(minWidth: 0, maxWidth: maxWidth < 0 ? 0 : maxWidth);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_text.isNotEmpty) {
      _textPainter.paint(context.canvas, offset);
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..label = _text
      ..textDirection = _textDirection;
  }
}

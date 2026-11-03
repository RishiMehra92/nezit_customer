import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';

class CustomButton extends StatelessWidget {
  final String text; // simple text version
  final Widget? child; // keep old child support
  final VoidCallback? onPressed; // nullable when disabled
  final bool isDisabled; // existing
  final bool isLoading; // show loading
  final double? height; // optional styling
  final double? width; // optional styling
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  CustomButton({
    super.key,
    this.text = '',
    this.child,
    this.onPressed,
    this.isDisabled = false,
    this.isLoading = false,
    this.height,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  }) : assert(text.isNotEmpty || child != null, 'Either text or child must be provided');

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (isDisabled || isLoading) ? null : onPressed;
    final bg = backgroundColor ?? AppTheme.primaryColor;
    final fg = foregroundColor ?? Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      height: height ?? (isTablet(context) ? 40.h : 48),
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none,
          ),
          elevation: 0,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
        ),
        onPressed: effectiveOnPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : (child ?? Text(text)),
      ),
    );
  }
}

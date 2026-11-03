import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import '../../../config/helper.dart';
import '../../../config/theme.dart';
// import your bloc if you use one for order note

class OrderNoteWidget extends StatefulWidget {
  final String? initialNote;
  final Function(String note)? onNoteChanged;
  final bool isEnabled;

  const OrderNoteWidget({
    super.key,
    this.initialNote,
    this.onNoteChanged,
    this.isEnabled = true,
  });

  @override
  State<OrderNoteWidget> createState() => _OrderNoteWidgetState();
}

class _OrderNoteWidgetState extends State<OrderNoteWidget> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.onNoteChanged != null) {
      widget.onNoteChanged!(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {

    final dark = isDarkMode(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: dark ? AppTheme.mainDarkContainerBgColor : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible)
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Icon(
                    TablerIcons.note,
                    size: isTablet(context) ? 18.r : 24.r,
                    color: dark ? const Color(0xFF64B5F6) : AppTheme.primaryColor,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      context.tr('addOrderNote', fallback: "Add Order Note"),
                      style: TextStyle(
                        fontSize: isTablet(context) ? 22 : 15.sp,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? TablerIcons.chevron_up : TablerIcons.chevron_down,
                    size: isTablet(context) ? 18.r : 20.sp,
                    color: dark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('specialInstructionsStore', fallback: "Any special instructions for the store (e.g., delivery time, fragile items, etc.)"),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: dark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  CustomTextFormField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 3,
                    enabled: widget.isEnabled,
                    hintText: context.tr('writeYourNoteHere', fallback: "Write your note here..."),
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_controller.text.length}/300',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: _controller.text.length > 300 ? Colors.red : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

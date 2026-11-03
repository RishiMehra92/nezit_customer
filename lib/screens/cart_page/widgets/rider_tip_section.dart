import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';
class RiderTipSection extends StatefulWidget {
  final bool isCod;
  final ValueChanged<double?> onTipChanged;
  final double? initialTip;
  final ValueChanged<String?>? onValidationErrorChanged;
  final bool isFromOrderDetails;
  final VoidCallback? onTipButtonPressed;

  const RiderTipSection({
    super.key,
    required this.isCod,
    required this.onTipChanged,
    this.initialTip,
    this.onValidationErrorChanged,
    this.isFromOrderDetails = false,
    this.onTipButtonPressed,
    this.currencyCode,
  });

  final String? currencyCode;

  @override
  State<RiderTipSection> createState() => _RiderTipSectionState();
}

class _RiderTipSectionState extends State<RiderTipSection> {
  int? _selectedPreset; // dynamic presets
  String? _errorText;
  bool _isCustomActive = false;
  bool _shouldAutofocusCustom = false;
  final TextEditingController _customController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _setError(String? text) {
    if (_errorText != text) {
      setState(() {
        _errorText = text;
      });
      widget.onValidationErrorChanged?.call(text);
    }
  }

  @override
  void initState() {
    super.initState();
    final deliveryBoySettings = SettingsData.instance.deliveryBoy;
    final p1 = deliveryBoySettings?.preset1 ?? 10;
    final p2 = deliveryBoySettings?.preset2 ?? 20;
    final p3 = deliveryBoySettings?.preset3 ?? 50;

    if (widget.initialTip != null) {
      if (widget.initialTip == p1) {
        _selectedPreset = p1;
      } else if (widget.initialTip == p2) {
        _selectedPreset = p2;
      } else if (widget.initialTip == p3) {
        _selectedPreset = p3;
      } else if (widget.initialTip! > 0) {
        _isCustomActive = true;
        _customController.text = widget.initialTip!.toStringAsFixed(0);
      }
    }
  }

  @override
  void didUpdateWidget(RiderTipSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCod && !oldWidget.isCod) {
      // Clear tip when switching to COD
      setState(() {
        _selectedPreset = null;
        _isCustomActive = false;
        _customController.clear();
      });
      _setError(null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTipChanged(null);
      });
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectPreset(int value) {
    if (widget.isCod) return;
    final deliveryBoySettings = SettingsData.instance.deliveryBoy;
    final p1 = deliveryBoySettings?.preset1 ?? 10;
    final p2 = deliveryBoySettings?.preset2 ?? 20;
    final p3 = deliveryBoySettings?.preset3 ?? 50;

    setState(() {
      if (_selectedPreset == value) {
        // Deselect
        _selectedPreset = null;
        widget.onTipChanged(null);
      } else {
        _selectedPreset = value;
        _isCustomActive = false;
        _customController.clear();
        widget.onTipChanged(value.toDouble());
      }
    });
    _setError(null);

    if (_selectedPreset != null) {
      // Scroll to start or end depending on selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          if (value == p1 || value == p2) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } else if (value == p3) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      });
    }
  }

  void _toggleCustom() {
    if (widget.isCod) return;
    setState(() {
      if (_isCustomActive) {
        // Deselect
        _isCustomActive = false;
        _customController.clear();
        widget.onTipChanged(null);
        _shouldAutofocusCustom = false;
      } else {
        _isCustomActive = true;
        _selectedPreset = null;
        _shouldAutofocusCustom = true;
        widget.onTipChanged(null); // Wait for input

        // Scroll to end when Custom is selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
    _setError(null);
  }

  void _onCustomAmountChanged(String val) {
    // Strip any non-digit characters (including decimal points)
    String cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');

    // Restrict to max 4 digits
    if (cleanVal.length > 4) {
      cleanVal = cleanVal.substring(0, 4);
    }

    if (cleanVal != val) {
      _customController.text = cleanVal;
      _customController.selection = TextSelection.fromPosition(
        TextPosition(offset: cleanVal.length),
      );
    }

    if (cleanVal.isEmpty) {
      _setError(null);
      widget.onTipChanged(null);
      return;
    }

    final parsed = int.tryParse(cleanVal);
    final deliveryBoySettings = SettingsData.instance.deliveryBoy;
    final minTip = deliveryBoySettings?.minTipAmount ?? 10;
    final maxTip = deliveryBoySettings?.maxTipAmount ?? 100;

    if (parsed != null) {
      if (parsed < minTip) {
        final amountString = MoneyDisplay.format(minTip, currencyCode: widget.currencyCode);
        _setError(context.tr('minTipAmountError', positionalArgs: [amountString], fallback: "Minimum tip amount is $amountString."));
        widget.onTipChanged(null);
      } else if (parsed > maxTip) {
        final amountString = MoneyDisplay.format(maxTip, currencyCode: widget.currencyCode);
        _setError(context.tr('maxTipAmountError', positionalArgs: [amountString], fallback: "Maximum tip amount is $amountString."));
        widget.onTipChanged(null);
      } else {
        _setError(null);
        widget.onTipChanged(parsed.toDouble());
      }
    } else {
      _setError(null);
      widget.onTipChanged(null);
    }
  }

  bool _hasActiveTipSelection() {
    if (_selectedPreset != null) return true;
    if (_isCustomActive) {
      final text = _customController.text.trim();
      if (text.isNotEmpty) {
        final parsed = double.tryParse(text);
        if (parsed != null && parsed > 0) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currency = MoneyDisplay.resolveCurrencySymbol(widget.currencyCode);
    final dark = isDarkMode(context);

    final deliveryBoySettings = SettingsData.instance.deliveryBoy;
    final preset1 = deliveryBoySettings?.preset1 ?? 10;
    final preset2 = deliveryBoySettings?.preset2 ?? 20;
    final preset3 = deliveryBoySettings?.preset3 ?? 50;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: dark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Image on left, professional Text on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomImageContainer(
                imagePath: 'assets/images/rider_tip.png',
                width: 55.w,
                height: 55.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('thankYourDeliveryPartner', fallback: "Thank Your Delivery Partner"),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      context.tr('tipGoesToDeliveryPartner', fallback: "100% of your tip goes directly to support our delivery partners."),
                      style: TextStyle(
                        fontSize: 12,
                        color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Tip Selection Boxes Row
          Opacity(
            opacity: widget.isCod ? 0.5 : 1.0,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTipBox("😀$currency$preset1", _selectedPreset == preset1, () => _selectPreset(preset1)),
                  _buildTipBox("☺️$currency$preset2", _selectedPreset == preset2, () => _selectPreset(preset2)),
                  _buildTipBox("😍$currency$preset3", _selectedPreset == preset3, () => _selectPreset(preset3)),
                  _isCustomActive
                      ? _buildCustomInputBox()
                      : _buildTipBox(context.tr('customPreset', fallback: "👏Custom"), false, _toggleCustom),
                ],
              ),
            ),
          ),

          // Error text when input is below 10
          if (_errorText != null && !widget.isCod) ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                _errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          // Message below boxes if it's Cash on Delivery
          if (widget.isCod) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade800,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      context.tr('tipOnlineOnlyWarning', fallback: "Rider tips are only supported with online payment methods."),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.isFromOrderDetails && _hasActiveTipSelection() && _errorText == null) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: context.tr('tipRider', fallback: "Tip Rider"),
                  onPressed: widget.onTipButtonPressed,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomInputBox() {
    final currency = MoneyDisplay.resolveCurrencySymbol(widget.currencyCode);
    return Container(
      width: 100.w,
      height: 38.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppTheme.primaryColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            currency,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              onChanged: _onCustomAmountChanged,
              autofocus: _shouldAutofocusCustom,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: "...",
                hintStyle: TextStyle(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBox(String label, bool isSelected, VoidCallback onTap) {
    final dark = isDarkMode(context);
    return InkWell(
      onTap: widget.isCod ? null : onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : (dark ? Theme.of(context).colorScheme.surface : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : (dark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primaryColor : (dark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}

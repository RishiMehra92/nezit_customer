import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/auth/bloc/apply_referral/apply_referral_bloc.dart';
import 'package:hyper_local/services/referral_attribution_service.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';

class ReferralPromptSheet extends StatefulWidget {
  const ReferralPromptSheet({super.key});

  @override
  State<ReferralPromptSheet> createState() => _ReferralPromptSheetState();
}

class _ReferralPromptSheetState extends State<ReferralPromptSheet> {
  final TextEditingController _codeController = TextEditingController();
  final ReferralAttributionService _attribution =
      GetIt.instance<ReferralAttributionService>();

  bool _hasPrefilled = false;

  @override
  void initState() {
    super.initState();
    _loadStoredCode();
  }

  Future<void> _loadStoredCode() async {
    final stored = await _attribution.getCode();
    if (!mounted) return;
    if (stored != null && stored.isNotEmpty) {
      _codeController.text = stored;
      setState(() => _hasPrefilled = true);
    }
  }

  void _onApply() {
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _onSkip();
      return;
    }
    context
        .read<ApplyReferralBloc>()
        .add(ApplyReferralRequest(code: code));
  }

  void _onSkip() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(false);
  }

  Future<void> _onSuccess(String successMessage) async {
    await _attribution.clearCode();
    if (!mounted) return;
    if (successMessage.isNotEmpty) {
      ToastManager.show(
        context: context,
        message: successMessage,
        type: ToastType.success,
      );
    }
    Navigator.of(context).pop(true);
    context.read<GetUserCartBloc>().add(SyncCart());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<ApplyReferralBloc, ApplyReferralState>(
      listener: (context, state) {
        if (state is ApplyReferralSuccess) {
          final msg = state.message.isNotEmpty
              ? state.message
              : context.tr('referralAppliedSuccess');
          _onSuccess(msg);
        } else if (state is ApplyReferralFailed) {
          ToastManager.show(
            context: context,
            message: state.message.isNotEmpty
                ? state.message
                : context.tr('referralFailedRetry'),
            type: ToastType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ApplyReferralLoading;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20.r),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Drag Handle
                  Container(
                    width: 40.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _buildHeroIcon(),
                  SizedBox(height: 20.h),
                  Text(
                    context.tr('referralCodeTitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    context.tr('referralCodeSubtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  CustomTextFormField(
                    controller: _codeController,
                    hintText: context.tr('referralCodeHint'),
                    prefixIcon: Icons.card_giftcard_outlined,
                    enabled: !isLoading,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onApply(),
                  ),
                  if (_hasPrefilled) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14.sp,
                            color: AppTheme.primaryColor),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            context.tr('referralCodePrefilledHint'),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.sp,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onPressed: _onApply,
                      isLoading: isLoading,
                      child: Text(
                        context.tr('applyReferralCode'),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: isLoading ? null : _onSkip,
                    style: TextButton.styleFrom(
                      minimumSize: Size(double.infinity, 44.h),
                    ),
                    child: Text(
                      context.tr('skipReferral'),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroIcon() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.card_giftcard_rounded,
        color: Colors.white,
        size: 36.sp,
      ),
    );
  }
}

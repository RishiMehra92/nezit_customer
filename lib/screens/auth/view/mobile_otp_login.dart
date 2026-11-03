import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../config/global.dart';
import '../../../config/helper.dart';
import '../../../config/settings_data_instance.dart';
import '../../../config/theme.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_button.dart';
import '../../../utils/widgets/custom_image_container.dart';
import '../../../utils/widgets/custom_textfield.dart';
import '../../../utils/widgets/custom_toast.dart';
import '../../../utils/widgets/shake_widget.dart';
import '../../../utils/widgets/whole_page_progress.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/user_verification/user_verification_bloc.dart';
import '../bloc/user_verification/user_verification_event.dart';
import '../bloc/user_verification/user_verification_state.dart';

/// Pair of (ShakeWidget key, FocusNode) used to highlight the first invalid.
typedef _FieldHandle = ({
  GlobalKey<ShakeWidgetState> shakeKey,
  FocusNode focusNode,
});

class MobileOtpLoginPage extends StatefulWidget {
  final bool? isDirectLogin;

  /// When true, this page is being used by an already-logged-in user to.
  final bool isUpdate;

  const MobileOtpLoginPage({
    super.key,
    required this.isDirectLogin,
    this.isUpdate = false,
  });

  @override
  State<MobileOtpLoginPage> createState() => _MobileOtpLoginPageState();
}

class _MobileOtpLoginPageState extends State<MobileOtpLoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  String? _completePhoneNumber;
  String _phoneNumber = '';
  String? _countryCode;
  String? _countryIso2;

  // Verification feedback (same as login_page.dart)
  bool? isUserVerified;
  bool? _phoneOk;
  String? helperText;
  Widget? statusIcon;

  /// Manually-managed errorText for the phone field.
  String? _phoneErrorText;
  bool _phoneSubmitAttempted = false;
  // Debounce for verification
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 800);

  // Animation controllers
  late AnimationController _slideController;

  // Shake + focus handles — on invalid submit, the first invalid field is
  final GlobalKey<ShakeWidgetState> _nameShakeKey = GlobalKey<ShakeWidgetState>();
  final GlobalKey<ShakeWidgetState> _phoneShakeKey = GlobalKey<ShakeWidgetState>();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
      // Reset verification state when page opens
      context.read<UserVerificationBloc>().add(ResetVerification());
    });
  }

  void _handlePhoneNumberChange(String value) {
    _debounceTimer?.cancel();

    if (value.isEmpty) {
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      if (_phoneNumber == value) {
        // Clean phone: remove all non-digits except +
        String cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
        context.read<UserVerificationBloc>().add(VerifyUser(value: cleanPhone, type: 'mobile'));
      }
    });
  }

  // ─── Field-level validators (reused by form + submit) ──────────────────
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('pleaseEnterYourFullName');
    }
    if (value.trim().length < 2) {
      return context.tr('nameMustBeAtLeast2Characters');
    }
    return null;
  }

  String? _validatePhoneString(String? number) {
    if (number == null || number.isEmpty) {
      return context.tr('pleaseEnterYourPhoneNumber');
    }
    final trimmed = number.trim();
    if (trimmed.length < 5) return context.tr('phoneNumberTooShort');
    if (trimmed.length > 16) return context.tr('phoneNumberTooLong');
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) return context.tr('onlyNumbersAllowed');
    return null;
  }

  /// Returns the first field (top-to-bottom) that fails its validator, or.
  _FieldHandle? _firstInvalidField() {
    if (_isRegisterMode && _validateName(_userNameController.text) != null) {
      return (shakeKey: _nameShakeKey, focusNode: _nameFocus);
    }
    if (_validatePhoneString(_phoneNumber) != null) {
      return (shakeKey: _phoneShakeKey, focusNode: _phoneFocus);
    }
    return null;
  }

  /// Shake + haptic + scroll-into-view + focus for an invalid field.
  Future<void> _shakeFocusScroll(_FieldHandle field) async {
    field.shakeKey.currentState?.shake();
    HapticFeedback.heavyImpact();
    final ctx = field.shakeKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    }
    if (!mounted) return;
    field.focusNode.requestFocus();
  }

  void _sendOtp() {
    FocusManager.instance.primaryFocus?.unfocus();
    
    // Flag that a submit has been attempted — phone errorText will now
    setState(() {
      _phoneSubmitAttempted = true;
      _phoneErrorText = _validatePhoneString(_phoneNumber);
    });

    // 1. First-invalid → shake + focus + scroll, then render all errors.
    final invalid = _firstInvalidField();
    if (invalid != null) {
      _formKey.currentState?.validate();
      _shakeFocusScroll(invalid);
      return;
    }

    // 2. Phone-verification gate (server already told us the phone state).
    if (_phoneOk != true) {
      ToastManager.show(
        context: context,
        message: _isRegisterMode ? context.tr('phoneNumberAlreadyRegistered') : context.tr('thisPhoneNumberIsNotRegistered'),
        type: ToastType.error,
      );
      return;
    }

    if (_completePhoneNumber == null || _phoneNumber.isEmpty) {
      return;
    }

    // Trigger AuthBloc to send OTP
    context.read<AuthBloc>().add(SendOtpToPhoneEvent(
          number: _phoneNumber,
          countryCode: _countryCode!,
          isoCode: _countryIso2!,
          isLogin: true,
          userName: _userNameController.text,
          referralCode: _referralCodeController.text,
          isUpdate: widget.isUpdate,
        ));
  }

  bool userIsRegistered() {
    final user = Global.userData;
    if (user == null) return false;

    // `user.mobile` holds the phone-number string; `user.mobileVerified` holds
    final mobile = user.mobile.trim();
    final mobileVerified = user.mobileVerified?.trim() ?? '';

    return mobile.isNotEmpty && mobileVerified.isNotEmpty;
  }

  /// Register mode means the user is signing up a NEW phone (post-social-auth).
  bool get _isRegisterMode => widget.isDirectLogin == false && !userIsRegistered();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LoginPhoneCodeSentState) {
            // Navigate to OTP verification page
            GoRouter.of(context).push(
              AppRoutes.otpVerification,
              extra: {
                'phoneNumber': _completePhoneNumber,
                'registrationData': <String, dynamic>{},
                'verificationId': state.verificationId,
                'userNumber': _phoneNumber,
                'countryCode': _countryCode,
                'isoCode': _countryIso2,
                'isLogin': true,
                'userName': _userNameController.text,
                'referralCode': _referralCodeController.text,
                'isUpdate': widget.isUpdate,
              },
            );
          } else if (state is AuthFailed) {
            ToastManager.show(context: context, message: state.error, type: ToastType.error);
          }
        },
        builder: (context, authState) {
          return Stack(
            children: [
              _buildStaticBackground(),
              _buildScrollableContent(),
              if (authState is AuthLoading || authState is LoginCodeSentProgress) const WholePageProgress(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStaticBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        image: DecorationImage(
          image: AssetImage('assets/images/doodle.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          // Fixed Logo
          Positioned(
            top: 70.h,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: CustomImageContainer(
                imagePath: getAppLogoUrl(context),
                height: 120,
              ),
            ),
          ),

          // Skip Button
          Positioned(
            width: MediaQuery.sizeOf(context).width,
            top: 10.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(
                  color: Colors.white,
                ),
                InkWell(
                  onTap: () {
                    Global.setIsFirstTime(false);
                    Global.shouldRedirectToHome = true;
                    GoRouter.of(context).go(AppRoutes.home);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                    child: Builder(
                      builder: (context) {
                                                return Text(
                          context.tr('skip'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet(context) ? 18 : 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.32,
            child: _buildFormContainer(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer() {
        return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, verificationState) {
        final isVerifying = verificationState is VerifyingUser;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16.w,
              18.h,
              16.w,
              18.h + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: Global.isUserFirstTimeLoginNotifier,
                    builder: (context, isUserFirstTimeLogin, _) {
                                            return Text(
                        isUserFirstTimeLogin ? context.tr('heyThere') : context.tr('welcomeBack'),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: isTablet(context) ? 32 : 22.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 2.h),
                  Builder(
                    builder: (context) {
                                            return Text(
                        context.tr('enterYourPhoneNumberToReceiveOtp'),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: isTablet(context) ? 18 : 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 32.h),
                  if (_isRegisterMode) ...[
                    ShakeWidget(
                      key: _nameShakeKey,
                      shakeOffset: 8,
                      child: CustomTextFormField(
                        controller: _userNameController,
                        focusNode: _nameFocus,
                        labelText: context.tr('fullName'),
                        hintText: context.tr('enterYourFullName'),
                        prefixIcon: Icons.person,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) => _validateName(value),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ShakeWidget(
                    key: _phoneShakeKey,
                    shakeOffset: 8,
                    child: _buildPhoneField(verificationState),
                  ),
                  const SizedBox(height: 16),
                  if (SettingsData.instance.system!.referEarnStatus == true && _isRegisterMode) ...[
                    CustomTextFormField(
                      controller: _referralCodeController,
                      labelText: context.tr('referralCode'),
                      hintText: context.tr('referralCodeHintText'),
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 32),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onPressed: isVerifying || _phoneOk != true ? null : _sendOtp,
                      child: Builder(
                        builder: (context) {
                                                    return Text(
                            isVerifying ? context.tr('verifying') : context.tr('sendOtp'),
                            style: TextStyle(
                              fontSize: isTablet(context) ? 28 : 16,
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  if (!widget.isUpdate) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (GoRouter.of(context).canPop()) {
                              GoRouter.of(context).pop();
                            } else {
                              GoRouter.of(context).pushReplacement(AppRoutes.login);
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                            child: Builder(
                              builder: (context) {
                                                                return Text(
                                  context.tr('continueWithEmail'),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: AppTheme.primaryColor,
                                    fontSize: isTablet(context) ? 18 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneField(UserVerificationState state) {
        final registerMode = _isRegisterMode;

    // Logic for verification feedback (matched from login_page.dart,
    if (_phoneNumber.isEmpty) {
      isUserVerified = null;
      _phoneOk = null;
      helperText = null;
      statusIcon = null;
    } else if (state is VerifyingUser) {
      isUserVerified = null;
      _phoneOk = null;
      helperText = context.tr('verifying');
      statusIcon = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.warningColor),
      );
    } else if (state is UserVerified) {
      isUserVerified = state.isUserVerified;
      // Register mode: phone MUST NOT already be registered.
      _phoneOk = registerMode ? isUserVerified == false : isUserVerified == true;
      if (registerMode) {
        helperText = _phoneOk == true ? context.tr('phoneNumberAvailable') : context.tr('phoneNumberAlreadyRegistered');
      } else {
        helperText = _phoneOk == true ? context.tr('phoneNumberVerifiedSuccessfully') : context.tr('thisPhoneNumberIsNotRegistered');
      }
      statusIcon = Icon(
        _phoneOk == true ? Icons.check_circle : Icons.cancel,
        color: _phoneOk == true ? AppTheme.successColor : AppTheme.errorColor,
        size: 16,
      );
    } else if (state is UserVerificationFailed) {
      // Verification *failing* is not the same as "phone unregistered" —
      isUserVerified = null;
      _phoneOk = null;
      helperText = context.tr('unableToVerifyUser');
      statusIcon = const Icon(Icons.error, color: AppTheme.errorColor, size: 16);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntlPhoneField(
          showDropdownIcon: false,
          showCountryFlag: false,
          disableLengthCheck: true,
          cursorColor: Theme.of(context).colorScheme.tertiary,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            labelText: context.tr('phoneNumber'),
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: isTablet(context) ? 20 : 16,
                ),
            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: isTablet(context) ? 20 : 16,
                ),
            hintText: context.tr('enterYourPhoneNumber'),
            prefixIcon: Icon(
              Icons.phone,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            prefixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: isTablet(context) ? 20 : 16,
                ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            // Border colors handle both code paths — see register_page.dart
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: _phoneErrorText != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: _phoneErrorText != null ? Theme.of(context).colorScheme.error : AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
          ),
          initialCountryCode: AppHelpers.countryCode,
          textInputAction: TextInputAction.done,
          focusNode: _phoneFocus,
          onChanged: (phone) {
            setState(() {
              _completePhoneNumber = phone.completeNumber;
              _countryCode = phone.countryCode;
              _phoneNumber = phone.number;
              _countryIso2 = phone.countryISOCode;
              // Keep the manual errorText in sync once the user has tried
              if (_phoneSubmitAttempted) {
                _phoneErrorText = _validatePhoneString(phone.number);
              }
            });
            _handlePhoneNumberChange(phone.number);
          },
          validator: (phone) => _validatePhoneString(phone?.number),
        ),
        // Manual errorText row — IntlPhoneField doesn't render it itself.
        if (_phoneErrorText != null) ...[
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              _phoneErrorText!,
              style: TextStyle(
                fontSize: isTablet(context) ? 16 : 12.sp,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
        if (helperText != null) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              if (statusIcon != null) ...[
                statusIcon!,
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: Text(
                  helperText!,
                  style: TextStyle(
                    fontSize: isTablet(context) ? 18 : 12.sp,
                    color: _phoneOk == true
                        ? AppTheme.successColor
                        : _phoneOk == false
                            ? AppTheme.errorColor
                            : AppTheme.warningColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _slideController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }
}

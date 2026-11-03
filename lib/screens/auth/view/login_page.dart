import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/services/referral_attribution_service.dart';
import 'package:hyper_local/services/clarity_service.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/auth/bloc/user_verification/user_verification_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/user_verification/user_verification_event.dart';
import 'package:hyper_local/screens/auth/bloc/user_verification/user_verification_state.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';
import '../../../config/helper.dart';
import '../../cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../widgets/social_button_widget.dart';
import '../../../utils/extensions/translation_extension.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFieldKey = GlobalKey<FormFieldState>();

  bool _isPasswordVisible = false;

  // Verification feedback
  bool? isUserVerified;
  String? helperText;
  Widget? statusIcon;
  String? inputHint;

  // Animation controllers
  late AnimationController _slideController;

  static const String _demoEmail = '9000000000';
  static const String _demoPassword = '12345678';

  // Debounce
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    ClarityService.initialize(context);

    _slideController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);

    if (AppHelpers.isDemo) {
      _identifierController.text = _demoEmail;
      _passwordController.text = _demoPassword;
      // Immediately trigger the verification logic for the pre-filled demo data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleIdentifierChange(_identifierController.text);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _slideController.forward());
  }

  // Smart Detection: Email or Phone?
  String _detectInputType(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'empty';

    // Prefer email if it looks valid
    if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed)) {
      return 'email';
    }

    // Phone: clean typical separators, then strict check
    final cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned) && !trimmed.contains('@')) {
      return 'phone';
    }

    return 'invalid';
  }

  bool _isValidEmail(String s) => _detectInputType(s) == 'email';
  bool _isValidPhone(String s) => _detectInputType(s) == 'phone';
  bool _isValidIdentifier(String s) => _isValidEmail(s) || _isValidPhone(s);

  void _handleIdentifierChange(String value) {
    _debounceTimer?.cancel();

    final type = _detectInputType(value);
    log('Input typee $type');

    if (type == 'empty' || type == 'invalid') {
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      if (_identifierController.text.trim() == value.trim()) {
        if (type == 'email') {
          context.read<UserVerificationBloc>().add(VerifyUser(value: value.trim(), type: type));
        } else {
          // Normalize phone: remove all non-digits except +
          String cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
          context.read<UserVerificationBloc>().add(VerifyUser(value: cleanPhone, type: 'mobile'));
        }
      }
    });
  }

  void _handleLogin() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (isUserVerified != true) {
      ToastManager.show(
        context: context,
        message: context.tr('noAccountFoundWithEmailOrPhone'),
        type: ToastType.error,
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ToastManager.show(
        context: context,
        message: context.tr('pleaseEnterYourPassword'),
        type: ToastType.error,
      );
      return;
    }

    final identifier = _identifierController.text.trim();

    context.read<AuthBloc>().add(LoginRequest(
          email: _isValidEmail(identifier) ? identifier : null,
          phoneNumber: _isValidPhone(identifier) ? identifier : null,
          password: _passwordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              Global.setIsUserFirstTimeLogin(false);
              Global.shouldRedirectToHome = true;
              GoRouter.of(context).pushReplacement(AppRoutes.splashScreen);
              ToastManager.show(context: context, message: state.message, type: ToastType.success);
              final getUserCartBloc = context.read<GetUserCartBloc>();

              Future.delayed(const Duration(seconds: 1), () {
                getUserCartBloc.add(SyncCart());
              });
            } else if (state is AuthFailed) {
              ToastManager.show(context: context, message: state.error, type: ToastType.error);
            } else if (state is SocialAuthSuccess) {
              Global.setIsUserFirstTimeLogin(false);
              Global.shouldRedirectToHome = true;
              if (state.isRegister) {
                // Fresh signup via social auth
                final referralAttribution = GetIt.instance<ReferralAttributionService>();
                referralAttribution.setJustRegistered(true);
                // Go through splash like all other auth flows.
                // pushReplacement directly to /home would bypass the
                // StatefulShellRoute, breaking bottom navigation.
                GoRouter.of(context).pushReplacement(
                  AppRoutes.splashScreen,
                );
              } else {
                // Returning user — mirror the AuthSuccess path.
                GoRouter.of(context).pushReplacement(
                  AppRoutes.splashScreen,
                );

                ToastManager.show(
                  context: context,
                  message: state.message ?? 'Login successful',
                  type: ToastType.success,
                );

                final getUserCartBloc = context.read<GetUserCartBloc>();

                Future.delayed(const Duration(seconds: 1), () {
                  getUserCartBloc.add(SyncCart());
                });
              }
            }
          },
          builder: (context, authState) {
            return Stack(
              children: [
                // Static background with doodle
                _buildStaticBackground(),

                _buildScrollableContent(),

                if (authState is AuthLoading) const WholePageProgress(),
              ],
            );
          },
        ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

          return Stack(
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
                top: 10.h,
                right: 20.w,
                child: InkWell(
                  onTap: () {
                    Global.setIsFirstTime(false);
                    Global.shouldRedirectToHome = true;
                    GoRouter.of(context).go(AppRoutes.home);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.tr('skip'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet(context) ? 18 : 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),

              // Main Content (scroll only when keyboard opens)
              Positioned.fill(
                top: MediaQuery.of(context).size.height * 0.32,
                child: keyboardOpen
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: _buildLoginFormContainer(),
                      )
                    : _buildLoginFormContainer(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginFormContainer() {
    return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, verificationState) {
        final isVerifying = verificationState is VerifyingUser;
        final isInteractionBlocked = isVerifying || isUserVerified == false;

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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome text
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
                  Text(
                    context.tr('signInToYourAccount'),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: isTablet(context) ? 18 : 12.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  _buildIdentifierField(),
                  SizedBox(height: 16.h),

                  _buildPasswordField(),
                  SizedBox(height: 8.h),

                  GestureDetector(
                    onTap: isInteractionBlocked
                        ? null
                        : () {
                            GoRouter.of(context).push(AppRoutes.forgotPassword);
                          },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        context.tr('forgotPassword'),
                        style: TextStyle(
                          color: isInteractionBlocked ? Colors.grey[400] : AppTheme.primaryColor,
                          fontSize: isTablet(context) ? 18 : 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isAuthLoading = state is AuthLoading;
                      final isButtonEnabled = !isInteractionBlocked && !isAuthLoading && isUserVerified == true;

                      return SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          onPressed: isVerifying
                              ? () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                }
                              : isButtonEnabled
                                  ? _handleLogin
                                  : () {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      ToastManager.show(
                                          context: context,
                                          message: context.tr('pleaseEnterTheEmptyFields', fallback: 'Please enter the empty fields'),
                                          type: ToastType.error);
                                    },
                          child: Text(
                            isVerifying ? context.tr('verifying') : context.tr('signIn'),
                            style: TextStyle(
                              fontSize: isTablet(context) ? 28 : 16,
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 15.h),

                  // Divider
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: RotatedBox(quarterTurns: 2, child: customDivider())),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          context.tr('or'),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: isTablet(context) ? 18 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(child: customDivider()),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),

                  Opacity(
                    opacity: isVerifying ? 0.5 : 1.0,
                    child: AbsorbPointer(
                      absorbing: isVerifying,
                      child: socialButton(
                          onTap: isVerifying
                              ? () {}
                              : () {
                                  GoRouter.of(context).push(AppRoutes.mobileOtpLoginPage,
                                      extra: {'isDirectLogin': true, 'isUpdate': false}).then((value) async {
                                    _handleIdentifierChange(_identifierController.text);
                                  });
                                },
                          icon: Icons.phone,
                          iconColor: AppTheme.primaryColor,
                          background: Theme.of(context).colorScheme.surface,
                          borderColor: Colors.grey.shade300,
                          type: LoginType.mobile,
                          context: context),
                    ),
                  ),

                  if (SettingsData.instance.authentication!.googleLogin) ...[
                    SizedBox(height: 15.h),
                    Opacity(
                      opacity: isVerifying ? 0.5 : 1.0,
                      child: AbsorbPointer(
                        absorbing: isVerifying,
                        child: socialButton(
                            onTap: isVerifying
                                ? () {}
                                : () {
                                    context.read<AuthBloc>().add(GoogleLoginRequest());
                                  },
                            asset: 'assets/images/icons/google-logo.png',
                            background: Theme.of(context).colorScheme.surface,
                            borderColor: Colors.grey.shade300,
                            type: LoginType.google,
                            context: context),
                      ),
                    ),
                  ],

                  if (Platform.isIOS) ...[
                    SizedBox(height: 16.h),
                    Opacity(
                      opacity: isVerifying ? 0.5 : 1.0,
                      child: AbsorbPointer(
                        absorbing: isVerifying,
                        child: socialButton(
                            onTap: () {
                              context.read<AuthBloc>().add(AppleLoginRequest());
                            },
                            asset: 'assets/images/icons/apple-logo.png',
                            background: Theme.of(context).colorScheme.surface,
                            borderColor: Colors.grey.shade300,
                            type: LoginType.apple,
                            context: context),
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('dontHaveAnAccount'),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: Colors.grey[600],
                          fontSize: isTablet(context) ? 18 : 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          GoRouter.of(context).push(AppRoutes.register);
                        },
                        child: Text(
                          context.tr('signUp'),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: isTablet(context) ? 18 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentifierField() {
    return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, state) {
        // Reset on empty
        if (_identifierController.text.trim().isEmpty) {
          isUserVerified = null;
          helperText = null;
          statusIcon = null;
        } else if (state is VerifyingUser) {
          isUserVerified = null;
          helperText = context.tr('verifying');
          statusIcon = const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              ));
        } else if (state is UserVerified) {
          isUserVerified = state.isUserVerified;
          if (isUserVerified == true) {
            helperText = _detectInputType(_identifierController.text) == 'email'
                ? context.tr('emailVerifiedSuccessfully')
                : context.tr('phoneNumberVerifiedSuccessfully');
          } else {
            helperText = _detectInputType(_identifierController.text) == 'email'
                ? context.tr('thisEmailIsNotRegistered')
                : context.tr('thisPhoneNumberIsNotRegistered');
          }
          statusIcon = Icon(
            isUserVerified == true ? Icons.check_circle : Icons.cancel,
            color: isUserVerified == true ? Colors.green : Colors.red,
            size: 16,
          );
        } else if (state is UserVerificationFailed) {
          isUserVerified = false;
          helperText = context.tr('unableToVerifyUser');
          statusIcon = const Icon(Icons.error, color: AppTheme.errorColor, size: 16);
        } else if (_identifierController.text.trim().isNotEmpty) {
          // ── NEW: show feedback for invalid format while typing ────────
          final type = _detectInputType(_identifierController.text);
          if (type == 'invalid') {
            isUserVerified = false;
            helperText = context.tr('enterValidEmailOrPhone');
            statusIcon = const Icon(Icons.error, color: Colors.red, size: 16);
          } else {
            isUserVerified = null;
            helperText = null;
            statusIcon = null;
          }
        } else {
          isUserVerified = null;
          helperText = null;
          statusIcon = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFormField(
              key: _identifierFieldKey,
              controller: _identifierController,
              hintText: context.tr('emailOrPhoneNumber'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (state is VerifyingUser || state is UserVerified || state is UserVerificationFailed) {
                  return null;
                }

                if (value == null || value.isEmpty) {
                  return context.tr('emailOrPhoneNumberIsRequired');
                }
                if (!_isValidIdentifier(value)) return context.tr('enterValidEmailOrPhone');
                return null;
              },
              onChanged: _handleIdentifierChange,
            ),
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
                        color: isUserVerified == true
                            ? Colors.green
                            : isUserVerified == false
                                ? Colors.red
                                : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return CustomTextFormField(
      controller: _passwordController,
      hintText: context.tr('enterYourPassword'),
      obscureText: !_isPasswordVisible,
      suffixIcon: _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      onSuffixIconTap: () {
        setState(() {
          _isPasswordVisible = !_isPasswordVisible;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          ToastManager.show(context: context, message: context.tr('passwordIsRequired'));
          return null;
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _slideController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

Widget customDivider() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Container(
      height: 0.5,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.45),
          Colors.black.withValues(alpha: 0.35),
          Colors.black.withValues(alpha: 0.25),
          Colors.black.withValues(alpha: 0.15),
          Colors.black.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.0),
          Colors.transparent,
        ],
      )),
    ),
  );
}

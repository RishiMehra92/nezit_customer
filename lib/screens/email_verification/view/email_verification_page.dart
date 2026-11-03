import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/auth/bloc/user_verification/user_verification_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/user_verification/user_verification_event.dart';
import 'package:hyper_local/screens/auth/bloc/user_verification/user_verification_state.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';

import '../bloc/send_email_verification_bloc/send_email_verification_bloc.dart';
import '../bloc/send_email_verification_bloc/send_email_verification_event.dart';
import '../bloc/send_email_verification_bloc/send_email_verification_state.dart';


class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _checkingStatus = false;

  /// User has tapped "Change" on the verified callout, so we should treat.
  bool _editing = false;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  /// Debounce guard for user-verification on the email field.
  DateTime? _lastEmailChange;

  static final RegExp _emailRegex =
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: (Global.userData?.email ?? '').trim(),
    );
    // Clear any stale verification state from a previous screen so the
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserVerificationBloc>().add(ResetVerification());
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Debounced user-verification trigger — mirrors the register-page.
  void _onEmailChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }

    final now = DateTime.now();
    _lastEmailChange = now;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_lastEmailChange != now) return; // superseded
      final latest = _emailController.text.trim();
      if (latest != trimmed) return;
      if (!_emailRegex.hasMatch(trimmed)) return;

      context
          .read<UserVerificationBloc>()
          .add(VerifyUser(value: trimmed, type: 'email'));
    });
  }

  bool get _alreadyVerified =>
      (Global.userData?.emailVerified ?? '').trim().isNotEmpty;

  /// Effective "show as verified" — true only if the user has a verified.
  bool get _showAsVerified => _alreadyVerified && !_editing;

  void _onSendPressed() {
    FocusManager.instance.primaryFocus?.unfocus();
    
    if (_formKey.currentState?.validate() != true) return;

    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      ToastManager.show(
        context: context,
        message: context.tr('pleaseEnterAValidEmail'),
        type: ToastType.error,
      );
      return;
    }

    // User-verification gate — don't let a taken email through.
    final verState = context.read<UserVerificationBloc>().state;
    if (verState is VerifyingUser) {
      return;
    }
    if (verState is UserVerified && verState.isUserVerified == true) {
      ToastManager.show(
        context: context,
        message: context.tr('emailAlreadyRegistered'),
        type: ToastType.error,
      );
      return;
    }
    if (verState is UserVerificationFailed) {
      ToastManager.show(
        context: context,
        message: context.tr('unableToVerifyUser'),
        type: ToastType.error,
      );
      return;
    }

    context
        .read<SendEmailVerificationBloc>()
        .add(RequestSendEmailVerification(email: email));
  }

  void _onCheckStatusPressed() {
    setState(() {
      _checkingStatus = true;
    });
    context.read<UserProfileBloc>().add(FetchUserProfile());
  }

  @override
  Widget build(BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;

    return CustomScaffold(
      title: context.tr('emailVerification'),
      showAppBar: true,
      showViewCart: false,
      body: MultiBlocListener(
        listeners: [
          // React to "Send Verification Email" API result.
          BlocListener<SendEmailVerificationBloc, SendEmailVerificationState>(
            listener: (context, state) {
              if (state is SendEmailVerificationSuccess) {
                ToastManager.show(
                  context: context,
                  message: context.tr('verificationEmailSentSuccessfully'),
                  type: ToastType.success,
                );
              } else if (state is SendEmailVerificationError) {
                ToastManager.show(
                  context: context,
                  message: state.error,
                  type: ToastType.error,
                );
              }
            },
          ),
          // React to "Check Verification Status" refresh result.
          BlocListener<UserProfileBloc, UserProfileState>(
            listener: (context, state) {
              if (!_checkingStatus) return;
              if (state is UserProfileLoaded) {
                _checkingStatus = false;
                final nowVerified = (Global.userData?.emailVerified ?? '')
                    .trim()
                    .isNotEmpty;
                if (nowVerified) {
                  ToastManager.show(
                    context: context,
                    message: context.tr('emailIsNowVerified'),
                    type: ToastType.success,
                  );
                  if (context.mounted) GoRouter.of(context).pop();
                } else {
                  ToastManager.show(
                    context: context,
                    message: context.tr('emailStillNotVerified'),
                    type: ToastType.error,
                  );
                }
              } else if (state is UserProfileFailed) {
                _checkingStatus = false;
                ToastManager.show(
                  context: context,
                  message: state.error,
                  type: ToastType.error,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<SendEmailVerificationBloc,
            SendEmailVerificationState>(
          builder: (context, sendState) {
            final isSending = sendState is SendEmailVerificationLoading;
            final hasSent = sendState is SendEmailVerificationSuccess;

            return BlocBuilder<UserProfileBloc, UserProfileState>(
              builder: (context, profileState) {
                final isCheckingStatus = _checkingStatus &&
                    profileState is UserProfileLoading;
                final isBusy = isSending || isCheckingStatus;

                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeaderIcon(colorScheme: colorScheme),
                            SizedBox(height: 18.h),
                            _Headline(
                                                            alreadyVerified: _showAsVerified,
                              hasSent: hasSent,
                            ),
                            SizedBox(height: 16.h),
                            // Editable so users with no email on file can
                            CustomTextFormField(
                              controller: _emailController,
                              labelText: context.tr('email'),
                              hintText: context.tr('enterYourEmail'),
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              enabled: !_showAsVerified && !isBusy,
                              onChanged: _showAsVerified ? null : _onEmailChanged,
                              validator: (value) {
                                if (_showAsVerified) return null;
                                final trimmed = (value ?? '').trim();
                                if (trimmed.isEmpty) {
                                  return context.tr('pleaseEnterYourEmail');
                                }
                                if (!_emailRegex.hasMatch(trimmed)) {
                                  return context.tr('pleaseEnterAValidEmail');
                                }
                                return null;
                              },
                            ),
                            // Inline helper row — verifying / available /
                            if (!_showAsVerified)
                              const _EmailVerificationHelper(),
                            SizedBox(height: 24.h),
                            if (_showAsVerified)
                              _AlreadyVerifiedCallout(
                                                                onChangePressed: isBusy
                                    ? null
                                    : () {
                                        // Reset verification when entering
                                        context
                                            .read<UserVerificationBloc>()
                                            .add(ResetVerification());
                                        setState(() => _editing = true);
                                      },
                              )
                            else ...[
                              BlocBuilder<UserVerificationBloc,
                                  UserVerificationState>(
                                builder: (context, verState) {
                                  final isVerifying =
                                      verState is VerifyingUser;
                                  final isTaken = verState is UserVerified &&
                                      verState.isUserVerified == true;
                                  final disabled =
                                      isBusy || isVerifying || isTaken;
                                  return CustomButton(
                                    onPressed: disabled ? null : _onSendPressed,
                                    child: Text(
                                      hasSent
                                          ? context.tr('resendEmail') : context.tr('sendVerificationEmail'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (hasSent) ...[
                                SizedBox(height: 12.h),
                                OutlinedButton(
                                  onPressed:
                                      isBusy ? null : _onCheckStatusPressed,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    side: const BorderSide(
                                        color: AppTheme.primaryColor),
                                    foregroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr('checkVerificationStatus'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (isBusy) const WholePageProgress(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final ColorScheme colorScheme;
  const _HeaderIcon({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mark_email_unread_outlined,
          size: 48,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
    final bool alreadyVerified;
  final bool hasSent;

  const _Headline({
        required this.alreadyVerified,
    required this.hasSent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String title;
    if (alreadyVerified) {
      title = context.tr('verified');
    } else if (hasSent) {
      title = context.tr('verificationLinkSentMessage');
    } else {
      title = context.tr('emailVerification');
    }
    return Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: hasSent && !alreadyVerified ? 14.5 : 17.5,
        fontWeight:
            hasSent && !alreadyVerified ? FontWeight.w500 : FontWeight.w700,
        color: hasSent && !alreadyVerified
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurface,
      ),
    );
  }
}

/// Helper row rendered directly below the email field.
class _EmailVerificationHelper extends StatelessWidget {
  
  const _EmailVerificationHelper();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, state) {
        String? message;
        Widget? icon;
        Color? color;

        if (state is VerifyingUser) {
          message = context.tr('verifying');
          icon = const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.warningColor,
            ),
          );
          color = AppTheme.warningColor;
        } else if (state is UserVerified) {
          // REGISTER semantic: email must be available (not already taken).
          final taken = state.isUserVerified == true;
          message = taken ? context.tr('emailAlreadyRegistered') : context.tr('emailAvailable');
          icon = Icon(
            taken ? Icons.cancel : Icons.check_circle,
            size: 16,
            color: taken ? AppTheme.errorColor : AppTheme.successColor,
          );
          color = taken ? AppTheme.errorColor : AppTheme.successColor;
        } else if (state is UserVerificationFailed) {
          message = context.tr('unableToVerifyUser');
          icon = const Icon(Icons.error,
              size: 16, color: AppTheme.errorColor);
          color = AppTheme.errorColor;
        }

        if (message == null) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(top: 6.h, left: 4.w),
          child: Row(
            children: [
              if (icon != null) ...[
                icon,
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlreadyVerifiedCallout extends StatelessWidget {
  
  /// When non-null, a "Change" button is rendered to the right of the.
  final VoidCallback? onChangePressed;

  const _AlreadyVerifiedCallout({
        this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.successColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: AppTheme.successColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('emailIsNowVerified'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.successColor,
              ),
            ),
          ),
          if (onChangePressed != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onChangePressed,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.tr('change'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/screens/auth/bloc/apply_referral/apply_referral_bloc.dart';
import 'package:hyper_local/screens/auth/view/referral_prompt_sheet.dart';
import 'package:hyper_local/screens/home_page/widgets/referral_banner.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/services/referral_attribution_service.dart';

class HomeReferralOverlay extends StatefulWidget {
  final ValueChanged<bool>? onVisibilityChanged;

  const HomeReferralOverlay({super.key, this.onVisibilityChanged});

  @override
  State<HomeReferralOverlay> createState() => _HomeReferralOverlayState();
}

class _HomeReferralOverlayState extends State<HomeReferralOverlay> {
  bool _showReferralBanner = false;

  @override
  void initState() {
    super.initState();
    Global.homeNeedsReferralCheckNotifier
        .addListener(_onGlobalReferralCheckChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProfileState = context.read<UserProfileBloc>().state;
        if (userProfileState is UserProfileLoaded) {
          _maybeShowReferralPrompt(userProfileState);
        }
      }
    });
  }

  @override
  void dispose() {
    Global.homeNeedsReferralCheckNotifier
        .removeListener(_onGlobalReferralCheckChanged);
    super.dispose();
  }

  void _onGlobalReferralCheckChanged() {
    if (Global.homeNeedsReferralCheckNotifier.value) {
      Global.homeNeedsReferralCheckNotifier.value = false;
      final userProfileState = context.read<UserProfileBloc>().state;
      if (userProfileState is UserProfileLoaded) {
        _maybeShowReferralPrompt(userProfileState);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      left: 10,
      right: 10,
      child: BlocListener<UserProfileBloc, UserProfileState>(
        listener: (context, state) {
          if (state is UserProfileLoaded) {
            _maybeShowReferralPrompt(state);
          }
        },
        child: _showReferralBanner
            ? ReferralBanner(
                onYes: _onYesReferral,
                onNo: _onNoReferral,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _maybeShowReferralPrompt(UserProfileLoaded state) async {
    try {
      if (SettingsData.instance.system?.referEarnStatus != true) return;

      final referralAttribution = GetIt.instance<ReferralAttributionService>();

      // Check if the user just registered
      final isNewUser = await referralAttribution.getJustRegistered();
      if (!isNewUser) return;

      // Check if referral prompt was already shown
      final alreadyShown = await referralAttribution.getPromptShown();
      if (alreadyShown) return;

      // Check if friends code is already applied
      final friendsCode = state.userData.data?.friendsCode;
      final referralCodeApplied = friendsCode != null && friendsCode.isNotEmpty;
      if (referralCodeApplied) {
        // Clear the just registered flag since they already have a code applied
        await referralAttribution.setJustRegistered(false);
        return;
      }

      // Set shown flag and clear just registered flag so it is shown only once
      await referralAttribution.setPromptShown(true);
      await referralAttribution.setJustRegistered(false);

      if (!mounted) return;

      // Wait a brief delay for Home Screen to be fully loaded
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _showReferralBanner = true;
        });
        widget.onVisibilityChanged?.call(true);
      });
    } catch (e) {
      log('Error showing referral prompt: $e');
    }
  }

  void _onYesReferral() {
    setState(() {
      _showReferralBanner = false;
    });
    widget.onVisibilityChanged?.call(false);
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      builder: (sheetContext) {
        return BlocProvider(
          create: (_) => ApplyReferralBloc(),
          child: const ReferralPromptSheet(),
        );
      },
    );
  }

  void _onNoReferral() {
    setState(() {
      _showReferralBanner = false;
    });
    widget.onVisibilityChanged?.call(false);
  }
}

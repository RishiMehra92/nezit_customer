import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/onboarding/onboarding_cubit.dart';
import 'package:hyper_local/bloc/onboarding/onboarding_state.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/introduction_pages/model/onboarding_model.dart';
import 'package:hyper_local/screens/introduction_pages/widgets/onboarding_background_widget.dart';
import 'package:hyper_local/screens/introduction_pages/widgets/onboarding_design_helpers.dart';
import 'package:hyper_local/screens/introduction_pages/widgets/onboarding_media_widget.dart';
import 'package:hyper_local/services/clarity_service.dart';
import '../../../utils/widgets/custom_toast.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  IntroductionPageState createState() => IntroductionPageState();
}

class IntroductionPageState extends State<IntroductionPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int currentIndex = 0;
  late AnimationController _animationController;
  late AnimationController _iconAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _iconAnimationController.forward();
    ClarityService.initialize(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
    _animationController.reset();
    _iconAnimationController.reset();
    _animationController.forward();
    _iconAnimationController.forward();
  }

  void _nextPage(int totalCount) {
    if (currentIndex < totalCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    const bool isDemoMode = AppConstant.isDemoMode;
    if (!isDemoMode) {
      Global.setIsFirstTime(false);
    }

    if (!AppConstant.hasValidBaseUrl) {
      ToastManager.show(
        context: context,
        message: 'user not found',
        type: ToastType.error,
      );
      GoRouter.of(context).go(AppRoutes.splashScreen);
      return;
    }

    if (Global.userData?.token.isNotEmpty ?? false) {
      Global.shouldRedirectToHome = true;
      GoRouter.of(context).go(AppRoutes.home);
    } else {
      GoRouter.of(context).go(AppRoutes.login);
    }
  }

  void _skipToEnd() {
    _navigateToHome();
  }

  List<OnboardingScreenItem> _getFallbackScreens(BuildContext context) {
    return [
      OnboardingScreenItem(
        id: -1,
        title: context.tr('introPage1Title', fallback: 'Fast & Reliable Delivery'),
        subtitle: context.tr('introPage1Description', fallback: 'Get your daily essentials delivered to your doorstep in minutes'),
        media: 'assets/svg/intro-1.svg',
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -2,
        title: context.tr('introPage2Title', fallback: 'Wide Selection of Stores'),
        subtitle: context.tr('introPage2Description', fallback: 'Shop from your favorite local stores and supermarkets in one place'),
        media: 'assets/svg/intro-2.svg',
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -3,
        title: context.tr('introPage3Title', fallback: 'Easy & Secure Payments'),
        subtitle: context.tr('introPage3Description', fallback: 'Multiple payment options with real-time tracking for peace of mind'),
        media: 'assets/svg/intro-3.svg',
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        List<OnboardingScreenItem> onboardingScreens;

        if (state is OnboardingLoaded && state.screens.isNotEmpty) {
          onboardingScreens = state.screens;
        } else {
          final cubitScreens = context.read<OnboardingCubit>().currentScreens;
          onboardingScreens = cubitScreens.isNotEmpty ? cubitScreens : _getFallbackScreens(context);
        }

        final int totalCount = onboardingScreens.length;
        final currentScreen = onboardingScreens.isNotEmpty && currentIndex < onboardingScreens.length
            ? onboardingScreens[currentIndex]
            : (onboardingScreens.isNotEmpty ? onboardingScreens.first : null);
        final currentDesign = currentScreen?.design ?? OnboardingDesign.defaultDesign();

        return Scaffold(
          backgroundColor: HexColorHelper.parse(
            currentDesign.background.color,
            fallback: Colors.white,
          ),
          body: Stack(
            children: [
              // 1. Full-screen PageView: each page renders its own dynamic background + overlay + content
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: totalCount,
                itemBuilder: (context, index) {
                  return _buildPageContainer(onboardingScreens[index], index);
                },
              ),

              // 2. Top bar (Skip button) floating with dynamic contrast color
              SafeArea(
                child: _buildTopBar(totalCount, currentDesign),
              ),

              // 3. Floating bottom controls: Dynamic Indicators + Dynamic Animated Next/Get Started Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: _buildBottomControls(totalCount, currentDesign),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageContainer(OnboardingScreenItem data, int index) {
    final overlay = data.design.overlay;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Background layer: Video, GIF, Image, Gradient, or Solid + Backdrop Color Tint Scrim
        OnboardingBackgroundWidget(
          design: data.design,
          isActive: currentIndex == index,
        ),

        // 2. Foreground content with SafeArea (Title & Subtitle anchored at bottom)
        SafeArea(
          child: _buildOnboardingPage(data, index),
        ),

        // 3. Overlay Image placed on TOP OF STACK (True Overlay)
        if (overlay != null &&
            overlay.enabled &&
            (overlay.isImage || overlay.image.trim().isNotEmpty))
          OnboardingOverlayImageWidget(overlay: overlay),
      ],
    );
  }

  Widget _buildTopBar(int totalCount, OnboardingDesign design) {
    final bgLuminance = HexColorHelper.estimateBackgroundLuminance(design.background, design.overlay);
    Color skipColor = HexColorHelper.parse(design.button.backgroundColor, fallback: AppTheme.primaryColor);

    if (bgLuminance < 0.4 && skipColor.computeLuminance() < 0.35) {
      skipColor = Colors.white;
    } else if (bgLuminance > 0.65 && skipColor.computeLuminance() > 0.65) {
      skipColor = const Color(0xFF1F2937);
    }

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, right: 16),
        child: Visibility(
          visible: currentIndex < totalCount - 1,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _skipToEnd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: skipColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                ),
                child: Text(context.tr('skip')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(int totalCount, OnboardingDesign design) {
    final buttonBg = HexColorHelper.parse(
      design.button.backgroundColor,
      fallback: AppTheme.primaryColor,
    );
    final buttonFg = HexColorHelper.parse(
      design.button.foregroundColor,
      fallback: Colors.white,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          if (totalCount > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalCount,
                (index) => _buildIndicator(index, design),
              ),
            ),

          const SizedBox(height: 22),

          // Next / Get Started dynamic button
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            width: double.infinity,
            height: 54,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: buttonBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: buttonBg.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _nextPage(totalCount),
                  child: Center(
                    child: Text(
                      currentIndex >= totalCount - 1
                          ? context.tr('getStarted')
                          : context.tr('next'),
                      style: TextStyle(
                        color: buttonFg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingScreenItem data, int index) {
    final hasMedia = data.media.trim().isNotEmpty;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = HexColorHelper.parse(
      data.design.text.titleColor,
      fallback: isDark ? Colors.white : const Color(0xFF111827),
    );
    final subtitleColor = HexColorHelper.parse(
      data.design.text.subtitleColor,
      fallback: isDark ? Colors.white70 : const Color(0xFF6B7280),
    );
    final textAlign = DesignMapper.mapTextAlign(data.design.text.alignment);
    final crossAxisAlignment = DesignMapper.mapCrossAxisAlignment(data.design.text.alignment);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          children: [
            // Clearance for top bar
            const SizedBox(height: 54),

            // Upper stage: takes all space above the text
            Expanded(
              child: hasMedia
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final maxAvail = constraints.maxHeight;
                        final mediaHeight = (maxAvail * 0.88).clamp(80.0, 340.0).clamp(0.0, maxAvail);

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: OnboardingMediaWidget(
                                screen: data,
                                isActive: currentIndex == index,
                                height: mediaHeight,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const SizedBox.expand(),
            ),

            // Content zone: Anchored firmly at the bottom, directly above the dot indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _buildTextContent(
                data,
                textAlign,
                crossAxisAlignment,
                titleColor,
                subtitleColor,
                index,
              ),
            ),

            // Exact clearance directly above the floating bottom controls (Indicators + Button)
            const SizedBox(height: 124),
          ],
        );
      },
    );
  }

  Widget _buildTextContent(
    OnboardingScreenItem data,
    TextAlign textAlign,
    CrossAxisAlignment crossAxisAlignment,
    Color titleColor,
    Color subtitleColor,
    int index,
  ) {
    final hasTitle = data.title.trim().isNotEmpty;
    final hasSubtitle = data.subtitle.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (hasTitle)
            Transform.translate(
              offset: _getSlideOffset(index),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    data.title,
                    textAlign: textAlign,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),
          if (hasSubtitle) ...[
            const SizedBox(height: 12),
            AnimatedOpacity(
              opacity: _fadeAnimation.value > 0.5 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Transform.translate(
                offset: Offset(0, (1 - _fadeAnimation.value) * 20),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    data.subtitle,
                    textAlign: textAlign,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Offset _getSlideOffset(int index) {
    switch (index) {
      case 0:
        return Offset(0, (1 - _fadeAnimation.value) * 50);
      case 1:
        return Offset((1 - _fadeAnimation.value) * 100, 0);
      case 2:
        return Offset((1 - _fadeAnimation.value) * -100, 0);
      default:
        return Offset(0, (1 - _fadeAnimation.value) * 50);
    }
  }

  Widget _buildIndicator(int index, OnboardingDesign design) {
    final activeColor = HexColorHelper.parse(
      design.indicator.activeColor,
      fallback: AppTheme.primaryColor,
    );
    final inactiveColor = HexColorHelper.parse(
      design.indicator.inactiveColor,
      fallback: const Color(0xFFDBE2EA),
    );
    final bool isActive = currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

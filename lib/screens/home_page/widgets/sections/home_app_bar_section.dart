import 'package:flutter/material.dart';

class HomeAppBarSection extends StatelessWidget {
  final bool canUseTabController;
  final double appBarOpacity;
  final Color? textColor;
  final Widget title;
  final Widget flexibleSpaceBackground;
  final Widget searchField;
  final Widget? tabBar;
  final Widget? notificationsAction;
  final bool isDarkMode;
  final Color? darkBackgroundColor;
  final Color? appBarColor;

  const HomeAppBarSection({
    super.key,
    required this.canUseTabController,
    required this.appBarOpacity,
    required this.textColor,
    required this.title,
    required this.flexibleSpaceBackground,
    required this.searchField,
    required this.isDarkMode,
    this.darkBackgroundColor,
    this.appBarColor,
    this.tabBar,
    this.notificationsAction,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: canUseTabController ? 195.0 : 120,
      floating: false,
      pinned: true,
      elevation: 3,
      backgroundColor: appBarColor ?? Colors.transparent,
      automaticallyImplyLeading: false,
      title: title,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          flexibleSpaceBackground,
          const FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: SizedBox.shrink(),
          ),
        ],
      ),
      actions: [
        if (notificationsAction != null) notificationsAction!,
        const SizedBox(width: 10),
      ],
      bottom: canUseTabController
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Column(
                children: [
                  searchField,
                  const SizedBox(height: 5),
                  tabBar ?? const SizedBox(height: 50),
                ],
              ),
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: searchField,
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../model/category_model.dart';
import 'home_tab_item.dart';
import 'home_helpers.dart';
import '../../../config/settings_data_instance.dart';

class HomeTabBar extends StatefulWidget {
  final List<CategoryData> categories;
  final Color? textColor;

  const HomeTabBar({
    super.key,
    required this.categories,
    this.textColor,
  });

  @override
  State<HomeTabBar> createState() => _HomeTabBarState();
}

class _HomeTabBarState extends State<HomeTabBar> {
  late List<Widget> _tabBarTabs;

  @override
  void initState() {
    super.initState();
    _buildTabBarTabs();
  }

  @override
  void didUpdateWidget(covariant HomeTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories) {
      _buildTabBarTabs();
    }
  }

  void _buildTabBarTabs() {
    final homeGeneralSettings = SettingsData.instance.homeGeneralSettings;
    List<Widget> tabs = [
      if (homeGeneralSettings != null && isValidHomeGeneralSettings(homeGeneralSettings))
        HomeAllTabDynamic(settings: homeGeneralSettings)
      else
        const HomeAllTabStatic(),
    ];
    
    tabs.addAll(widget.categories.asMap().entries.map((entry) {
      return HomeCategoryTab(
        category: entry.value,
        index: entry.key,
      );
    }).toList());
    
    _tabBarTabs = tabs;
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      dividerColor: Colors.transparent,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      enableFeedback: true,
      labelColor: widget.textColor,
      automaticIndicatorColorAdjustment: true,
      unselectedLabelColor: widget.textColor,
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: widget.textColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      tabs: _tabBarTabs,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../../bloc/language_bloc/language_bloc.dart';
import '../../config/global.dart';

class LanguageBottomSheet extends StatefulWidget {
  const LanguageBottomSheet({super.key});

  @override
  State<LanguageBottomSheet> createState() => _LanguageBottomSheetState();

  // Static show method - clean and consistent with your sort sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => const LanguageBottomSheet(),
    );
  }
}

class _LanguageBottomSheetState extends State<LanguageBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(14.r),
        topRight: Radius.circular(14.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('selectLanguage', fallback: 'Select Language'),
                    style: TextStyle(
                      fontSize: isTablet(context) ? 22 : 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: isDarkMode(context)
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                  ),
                  icon: const Icon(TablerIcons.x, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1.h, color: Theme.of(context).colorScheme.outlineVariant),

          // Language List
          Flexible(
            child: BlocBuilder<LanguageBloc, LanguageState>(
              builder: (context, state) {
                final currentCode =
                    state is LanguageLoaded ? state.currentLanguage : 'en';
                final dynamicLanguages = state is LanguageLoaded
                    ? (state.languageModel.data?.languages ?? [])
                    : [];
                final hasDynamic = dynamicLanguages.isNotEmpty;

                final List<Map<String, String>> languagesToShow = hasDynamic
                    ? dynamicLanguages
                        .map<Map<String, String>>((l) => <String, String>{
                              'code': l.code ?? '',
                              'name': l.name ?? '',
                              'nativeName': (l.nativeName != null &&
                                      l.nativeName!.isNotEmpty)
                                  ? l.nativeName!
                                  : (l.name ?? ''),
                            })
                        .toList()
                    : Global.supportedLanguages;

                return RadioGroup<String>(
                  groupValue: currentCode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<LanguageBloc>().add(ChangeLanguage(value));
                      context
                          .read<LanguageListBloc>()
                          .add(FetchLanguageList(locale: value));
                      Navigator.pop(context);
                    }
                  },
                  child: StaggeredListAnimator(
                    type: StaggeredListType.listView,
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    children: languagesToShow.map((language) {
                      final code = language['code']!;
                      final isSelected = currentCode == code;

                      return RadioListTile<String>(
                        key: ValueKey(code),
                        title: Text(
                          language['nativeName']!,
                          style: TextStyle(
                            fontSize: isTablet(context) ? 18 : 14.sp,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[800],
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        subtitle: Text(
                          language['name']!,
                          style: TextStyle(
                            fontSize: isTablet(context) ? 16 : 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        value: code,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppTheme.primaryColor;
                          }
                          return AppTheme.primaryColor;
                        }),
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10.h),
        ],
      ),
    );
  }
}

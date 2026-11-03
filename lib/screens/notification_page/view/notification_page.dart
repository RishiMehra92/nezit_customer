import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/notification_page/bloc/notification_bloc.dart';
import 'package:hyper_local/screens/notification_page/view/widgets/notification_card.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(FetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      showAppBar: true,
      title: context.tr('notifications', fallback: 'Notifications'),
      appBarActions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'mark_all_read') {
              context.read<NotificationBloc>().add(MarkAllAsRead());
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'mark_all_read',
              child: Row(
                children: [
                  const Icon(Icons.done_all, size: 20),
                  const SizedBox(width: 8),
                  Text(context.tr('markAllAsRead', fallback: 'Mark all as read')),
                ],
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ],
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          // ── Loading (initial) ────────────────────────────────────────────
          if (state is NotificationLoading) {
            return const CustomCircularProgressIndicator();
          }

          // ── Loaded ───────────────────────────────────────────────────────
          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return _EmptyNotificationState(
                onRetry: () => context.read<NotificationBloc>().add(FetchNotifications()),
              );
            }

            return CustomRefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(FetchNotifications());
                context.read<SettingsBloc>().add(FetchSettingsData(context: context));
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo is ScrollUpdateNotification &&
                      !state.hasReachedMax &&
                      !state.isLoadingMore &&
                      scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                    context.read<NotificationBloc>().add(FetchMoreNotifications());
                  }
                  return false;
                },
                child: StaggeredListAnimator.builder(
                  type: StaggeredListType.listView,
                  shrinkWrap: false,
                  padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
                  itemCount: state.notifications.length + (state.hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index >= state.notifications.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(
                          child: CustomCircularProgressIndicator(),
                        ),
                      );
                    }
                    final notification = state.notifications[index];
                    return NotificationCard(
                      key: ValueKey(notification.id),
                      notification: notification,
                    );
                  },
                ),
              ),
            );
          }

          // ── Failed ───────────────────────────────────────────────────────
          if (state is NotificationFailed) {
            return _EmptyNotificationState(
              message: state.error,
              onRetry: () => context.read<NotificationBloc>().add(FetchNotifications()),
            );
          }

          // ── Fallback ─────────────────────────────────────────────────────
          return _EmptyNotificationState(
            onRetry: () => context.read<NotificationBloc>().add(FetchNotifications()),
          );
        },
      ),
    );
  }
}

/// ── Empty / Error State Widget ────────────────────────────────────────────
class _EmptyNotificationState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _EmptyNotificationState({
    this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 44.sp,
                // color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              context.tr('noNotifications'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message ?? context.tr('caughtUpMessage'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13.sp,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            SizedBox(height: 28.h),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('retry')),
              style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  backgroundColor: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

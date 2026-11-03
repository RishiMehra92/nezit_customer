import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/notification_page/bloc/notification_bloc.dart';

class HomeNotificationAction extends StatelessWidget {
  final Color? textColor;

  const HomeNotificationAction({
    super.key,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        GoRouter.of(context).push(AppRoutes.notifications);
      },
      icon: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          int unreadCount = 0;
          if (state is NotificationLoaded) {
            unreadCount = state.unreadCount;
          }
          return Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            child: Icon(HeroiconsSolid.bell, color: textColor),
          );
        },
      ),
    );
  }
}

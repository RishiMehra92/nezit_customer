import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import '../bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import 'create_wishlist_dialog.dart';

class EmptyWishlistWidget extends StatelessWidget {
  const EmptyWishlistWidget({super.key});

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: isDarkMode(context)
                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 80,
              color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            context.tr('yourWishlistIsEmpty', fallback: 'Your Wishlist is Empty'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              context.tr('createYourFirstWishlistToOrganizeAndSaveItemsYouHave', fallback: 'Create your first wishlist to organize and save items you love'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary(context),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Create New Wishlist button
          SizedBox(
            width: 230,
            child: CustomButton(
              onPressed: () {
                _showCreateWishlistDialog(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: 5,),
                  Text(context.tr('createNewWishlist')),
                ],
              ),

            ),
          ),
          const SizedBox(height: 16),

          // Secondary action
          SizedBox(
            width: 230,
            child: CustomButton(
              onPressed: () {
                context.read<UserWishlistBloc>().add(GetUserWishlistRequest());
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh,),
                  const SizedBox(width: 5,),
                  Text(
                    context.tr('retry', fallback: 'Retry'),
                    style: TextStyle(
                      fontSize: 14.sp
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateWishlistDialog(BuildContext context) async {
    final result = await CreateWishlistDialog.show(context);

    if (result != null && result.isNotEmpty) {
      if (context.mounted) {
        context.read<UserWishlistBloc>().add(CreateNewWishlist(title: result));
      }
    }
  }
}

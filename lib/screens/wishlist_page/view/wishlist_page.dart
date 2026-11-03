import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import '../bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import '../bloc/get_user_wishlist_bloc/get_user_wishlist_state.dart';
import '../widgets/create_wishlist_dialog.dart';
import '../widgets/empty_wishlist_state.dart';
import '../widgets/wishlist_item_card.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    // TODO: implement initState
    context.read<UserWishlistBloc>().add(GetUserWishlistRequest());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        title: Text(
          context.tr('myWishlist', fallback: 'My Wishlist'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                _showCreateWishlistDialog(context);
              },
              icon: const Icon(Icons.add),
              tooltip: context.tr('createNewWishlist', fallback: 'Create new wishlist'),
            ),
          ),
        ],
      ),
      body: BlocBuilder<UserWishlistBloc, UserWishlistState>(
        builder: (context, state) {
          if (state.status == ApiStatus.loading) {
            return const CustomCircularProgressIndicator();
          } else if (state.status == ApiStatus.success) {
            return _buildLoadedState(context, state);
          } else if (state.status == ApiStatus.failure) {
            return _buildErrorState(context, state.error.isNotEmpty ? state.error : state.message);
          }
          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, UserWishlistState state) {
    if (state.wishlistData.isEmpty) {
      return _buildEmptyState(context);
    }
    return CustomRefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<UserWishlistBloc>();
        bloc.add(GetUserWishlistRequest());
        await bloc.stream.first;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification &&
              !state.hasReachedMax &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            context.read<UserWishlistBloc>().add(
                  GetMoreUserWishlistRequest(),
                );
          }
          return false;
        },
        child: StaggeredListAnimator.builder(
          type: StaggeredListType.listView,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: state.wishlistData.length + (state.hasReachedMax ? 0 : 1),
          itemBuilder: (context, index) {
            if (index >= state.wishlistData.length) {
              return const CustomCircularProgressIndicator();
            }
            final wishlistItem = state.wishlistData[index];
            return SizedBox(
              height: 70,
              child: WishlistItemCard(
                key: ValueKey(wishlistItem.id),
                wishlistItem: wishlistItem,
                onEdit: (value) {
                  context.read<UserWishlistBloc>().add(UpdateUserWishlist(title: value, wishlistId: wishlistItem.id!));
                },
                onDelete: () {
                  context.read<UserWishlistBloc>().add(DeleteWishlist(wishlistId: wishlistItem.id!));
                },
                onTap: () {
                  GoRouter.of(context).push(AppRoutes.wishlistProduct, extra: {'wishlist-id': wishlistItem.id});
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<UserWishlistBloc>();
        bloc.add(GetUserWishlistRequest());
        await bloc.stream.first;
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height:
              MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          child: const EmptyWishlistWidget(),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<UserWishlistBloc>();
        bloc.add(GetUserWishlistRequest());
        await bloc.stream.first;
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height:
              MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 24),
                Builder(builder: (context) {
                  return Text(
                    context.tr('somethingWentWrong', fallback: 'Something went wrong'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<UserWishlistBloc>().add(GetUserWishlistRequest());
                  },
                  icon: const Icon(Icons.refresh),
                  label: Builder(builder: (context) {
                    return Text(context.tr('tryAgain', fallback: 'Try Again'));
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

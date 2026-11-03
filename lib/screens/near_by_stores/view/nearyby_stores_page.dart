import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/screens/near_by_stores/widgets/store_notify_button.dart';
import 'package:hyper_local/screens/near_by_stores/widgets/store_status_helper.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/utils/widgets/recommend_badge.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/helper.dart';
import '../../../config/theme.dart';
import '../../../utils/widgets/custom_refresh_indicator.dart';
import '../../../utils/widgets/custom_textfield.dart';

class NearbyStoresPage extends StatefulWidget {
  const NearbyStoresPage({super.key});

  @override
  State<NearbyStoresPage> createState() => _NearbyStoresPageState();
}

class _NearbyStoresPageState extends State<NearbyStoresPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late NearByStoreBloc _bloc;
  String? _lastLocationIdentifier;
  Timer? _debounceTimer;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _bloc = context.read<NearByStoreBloc>();
    // _bloc = NearByStoreBloc()..add(const FetchNearByStores(perPage: 15, searchQuery: ''));
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer - wait 500ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final searchQuery = _searchController.text.trim();

      // Only search if query has changed
      if (_currentSearchQuery != searchQuery) {
        _currentSearchQuery = searchQuery;
        _performSearch(searchQuery);
      }
    });
  }

  void _performSearch(String searchQuery) {
    // Reset scroll position when searching
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    // Trigger search
    if (!_bloc.isClosed) {
      _bloc.add(FetchNearByStores(perPage: 15, searchQuery: searchQuery));
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _currentSearchQuery = '';
    });
    FocusScope.of(context).unfocus();
    _performSearch('');
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        _bloc.state is NearByStoreLoaded) {
      final state = _bloc.state as NearByStoreLoaded;
      if (!state.hasReachedMax && !_bloc.isClosed) {
        _bloc.add(LoadMoreNearByStores(
          perPage: 15,
          searchQuery: _currentSearchQuery,
        ));
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: true,
      // title: context.tr('nearbyStores', fallback: backgroundColor): Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          context.tr('nearbyStores', fallback: 'Nearby Stores'),
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: isTablet(context) ? 24 : 16.sp),
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(50), child: _buildSearchBar()),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<dynamic>('userLocationBox').listenable(),
        builder: (context, Box<dynamic> box, _) {
          final storedLocation = box.get('user_location');
          final locationIdentifier = storedLocation == null
              ? null
              : '${storedLocation.latitude}_${storedLocation.longitude}_${storedLocation.fullAddress}_${storedLocation.area}_${storedLocation.city}_${storedLocation.pincode}';

          // Refresh stores when location changes
          if (_lastLocationIdentifier != locationIdentifier) {
            _lastLocationIdentifier = locationIdentifier;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_bloc.isClosed) {
                _bloc.add(FetchNearByStores(
                  perPage: 15,
                  searchQuery: _currentSearchQuery,
                ));
              }
            });
          }

          return BlocProvider.value(
            value: _bloc,
            child: CustomRefreshIndicator(
              onRefresh: () async {
                if (!_bloc.isClosed) {
                  _bloc.add(FetchNearByStores(
                    perPage: 15,
                    searchQuery: _currentSearchQuery,
                  ));
                }
              },
              child: BlocBuilder<NearByStoreBloc, NearByStoreState>(
                builder: (context, state) {
                  print(state);
                  if (state is NearByStoreInitial || state is NearByStoreLoading) {
                    return const CustomCircularProgressIndicator();
                  }
                  if (state is NearByStoreFailed) {
                    return NoStorePage(
                      onRetry: () {
                        if (!_bloc.isClosed) {
                          _bloc.add(FetchNearByStores(
                            searchQuery: _currentSearchQuery,
                          ));
                        }
                      },
                    );
                  }
                  if (state is NearByStoreLoaded) {
                    final stores = state.stores.stores;

                    if (stores.isEmpty) {
                      return NoStorePage(
                        onRetry: () {
                          _clearSearch();
                        },
                      );
                    }

                    return StaggeredListAnimator(
                      type: StaggeredListType.listView,
                      shrinkWrap: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 20),
                      children: [
                        ...stores.map((store) => StoreCardBanner(
                              key: Key(store.slug ?? store.id.toString()),
                              store: store,
                              isRecommended: store.isRecommended ?? false,
                              onTap: () {
                                GoRouter.of(context).push(
                                  AppRoutes.nearbyStoreDetails,
                                  extra: {
                                    'store-slug': store.slug,
                                    'store-name': store.name,
                                  },
                                );
                              },
                            )),
                        if (!state.hasReachedMax) const ShimmerStoreCard(),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      margin: const EdgeInsetsGeometry.directional(end: 12, start: 12, bottom: 12),
      child: ValueListenableBuilder(
        valueListenable: _searchController,
        builder: (context, TextEditingValue value, __) {
          return CustomTextFormField(
            controller: _searchController,
            hintText: context.tr('searchForStore'),
            prefixIcon: Icons.search,
            suffixIcon: value.text.isNotEmpty ? Icons.close : null,
            onSuffixIconTap: () {
              if (_searchController.text.isNotEmpty) {
                _clearSearch();
              }
            },
            onChanged: (value) {
              _onSearchChanged();
            },
            onFieldSubmitted: (value) {
              // Immediate search on submit
              _debounceTimer?.cancel();
              _currentSearchQuery = value.trim();
              _performSearch(_currentSearchQuery);
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               STORE CARD WIDGET                              */
/* -------------------------------------------------------------------------- */
class StoreCardBanner extends StatelessWidget {
  final StoreData store;
  final VoidCallback? onTap;
  final bool isRecommended;

  const StoreCardBanner({
    super.key,
    required this.store,
    this.onTap,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final double distance = store.distance ?? 0.0;
    final double rating = double.parse(store.avgStoreRating ?? '0.0');
    final int totalStoreFeedback = store.totalStoreFeedback!;
    final bool isClosed = StoreStatusHelper.isClosed(store, context);
    final String statusText = StoreStatusHelper.getStatusText(store, context);
    final Color statusColor = StoreStatusHelper.getStatusColor(statusText, context);
    log('Store Distance ${distance.toStringAsFixed(1)}');

    final bool isDark = isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(12),
          border: isDark
              ? Border.all(
                  color: isClosed
                      ? Colors.grey.shade800.withValues(alpha: 0.6)
                      : Colors.grey.shade800,
                  width: 0.8,
                )
              : (isClosed
                  ? Border.all(color: Colors.grey.shade300, width: 0.8)
                  : null),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------- Banner + Logo + Rating -------------------
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner (lowered opacity for closed store)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Opacity(
                    opacity: isClosed ? 0.55 : 1.0,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: store.banner?.isNotEmpty == true
                          ? CustomImageContainer(
                              imagePath: store.banner!,
                              fit: BoxFit.cover,
                            )
                          : _gradientPlaceholder(),
                    ),
                  ),
                ),

                if (isRecommended)
                  const PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: RecommendBadge(
                      style: RecommendBadgeStyle.chip,
                    ),
                  ),

                // Circular Logo
                PositionedDirectional(
                  start: 16,
                  bottom: -60,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF222222) : Colors.white,
                      border: Border.all(
                          color: isDark ? const Color(0xFF333333) : Colors.white,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignCenter),
                    ),
                    child: ClipOval(
                      child: Opacity(
                        opacity: isClosed ? 0.75 : 1.0,
                        child: store.logo?.isNotEmpty == true
                            ? CustomImageContainer(
                                imagePath: store.logo!,
                                fit: BoxFit.cover,
                              )
                            : _iconPlaceholder(),
                      ),
                    ),
                  ),
                ),

                // Rating badge (top-right)
                PositionedDirectional(
                  end: 12,
                  bottom: -40,
                  child: Opacity(
                    opacity: isClosed ? 0.75 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(AppTheme.ratingStarIconFilled,
                              size: 16, color: AppTheme.ratingStarColor),
                          const SizedBox(width: 4),
                          Text('${rating.toStringAsFixed(1)}/5 ($totalStoreFeedback)',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiary
                                      .withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ------------------- Store Info -------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name ?? "Unknown Store",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isClosed
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Only show notify me button if store is closed
                      if (store.id != null && isClosed) ...[
                        const SizedBox(width: 8),
                        StoreNotifyButton(store: store),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16,
                          color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.address ?? "No address",
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.green.shade900.withValues(alpha: 0.35)
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: isDark
                              ? Border.all(
                                  color: Colors.green.shade700.withValues(alpha: 0.3),
                                  width: 0.8,
                                )
                              : null,
                        ),
                        child: Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.green.shade300 : Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Store status in info section
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientPlaceholder() => Container(
        decoration: const BoxDecoration(color: AppTheme.primaryColor),
        child: const Center(child: Icon(Icons.store, size: 50, color: Colors.white70)),
      );

  Widget _iconPlaceholder() => Container(
        color: Colors.blue.shade50,
        child: const Icon(Icons.store, size: 28, color: AppTheme.primaryColor),
      );
}

/* -------------------------------------------------------------------------- */
/*                               SHIMMER CARD                                  */
/* -------------------------------------------------------------------------- */
class ShimmerStoreCard extends StatelessWidget {
  const ShimmerStoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 130, width: double.infinity, color: Colors.grey),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 200, height: 18, color: Colors.grey),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 16, height: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Container(height: 13, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Container(width: 60, height: 20, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

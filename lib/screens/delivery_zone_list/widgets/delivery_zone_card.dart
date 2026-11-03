import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/delivery_zone_list/model/delivery_zone_model.dart';
import '../../../config/helper.dart';
import '../../../config/theme.dart';
import '../../../utils/widgets/money_display.dart';
class DeliveryZoneCard extends StatelessWidget {
  final DeliveryZoneData zone;

  const DeliveryZoneCard({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          GoRouter.of(context).push(AppRoutes.deliveryZoneDetail, extra: {'zoneId': zone.id});
        },
        child: Container(
          // elevation: isDark ? 4 : 2,
          decoration: BoxDecoration(
              color: isDarkMode(context) ? Theme.of(context).colorScheme.onSecondary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ]),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  child: Icon(TablerIcons.map_pin_filled, color: AppTheme.primaryColor, size: 18),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: Text(
                                    zone.name!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.tertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatusBadge(context, zone.status!),
                              if (zone.rushDeliveryEnabled == true) ...[
                                const SizedBox(width: 8),
                                _buildRushBadge(context),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Info Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        context: context,
                        icon: TablerIcons.truck_delivery,
                        label: context.tr('deliveryFee', fallback: "Fee"),
                        value: zone.regularDeliveryCharges != null
                            ? MoneyDisplay.format(
                                zone.regularDeliveryCharges,
                                formattedAmount: zone.formattedRegularDeliveryCharges,
                                currencyCode: zone.currencyCode,
                              )
                            : 'N/A',
                        accentColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildInfoCard(
                        context: context,
                        icon: Icons.card_giftcard_rounded,
                        label: context.tr('freeDeliveryAbove', fallback: "Free >"),
                        value: zone.freeDeliveryAmount != null
                            ? MoneyDisplay.format(
                                zone.freeDeliveryAmount,
                                formattedAmount: zone.formattedFreeDeliveryAmount,
                                currencyCode: zone.currencyCode,
                              )
                            : 'N/A',
                        accentColor: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildInfoCard(
                        context: context,
                        icon: Icons.location_on_rounded,
                        label: context.tr('coverageRadius', fallback: "Radius"),
                        value: "${zone.radiusKm} km",
                        accentColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppTheme.successColor.withValues(alpha: 0.2) : AppTheme.successColor.withValues(alpha: 0.1))
            : theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.successColor.withValues(alpha: 0.5) : theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.successColor : theme.colorScheme.onSecondaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            capitalizeFirstLetter(status),
            style: TextStyle(
              color: isActive
                  ? (isDark ? AppTheme.successColor : AppTheme.successColor.withValues(alpha: 0.9))
                  : theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRushBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.warningColor.withValues(alpha: 0.2) : AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: AppTheme.warningColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            context.tr('rush', fallback: "Rush"),
            style: TextStyle(
              color: isDark ? AppTheme.warningColor : AppTheme.warningColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }


}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/routing/app_router.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';

class RegionCard extends StatelessWidget {
  const RegionCard({super.key, required this.region, this.onTap, this.showProviders = true});

  final Region region;
  final void Function()? onTap;
  final bool showProviders;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyText = region.currencyCode?.toUpperCase() ?? 'USD';
    final countriesCount = region.countries?.length ?? 0;
    final autoTaxes = region.automaticTaxes == true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        child: InkWell(
          onTap: onTap ?? () => context.pushRoute(RegionDetailsRoute(regionId: region.id)),
          borderRadius: const BorderRadius.all(Radius.circular(16.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        region.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                if (region.countries != null && region.countries!.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...region.countries!
                                .take(6)
                                .where((c) => c.iso2 != null)
                                .map((c) => ClipRRect(
                                      borderRadius: BorderRadius.circular(2.0),
                                      child: Flag.fromString(
                                        c.iso2!.toUpperCase(),
                                        height: 12,
                                        width: 18,
                                        fit: BoxFit.cover,
                                      ),
                                    )),
                            if (countriesCount > 6)
                              Text(
                                '+${countriesCount - 6}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                ],
                Row(
                  children: [
                    _BadgeTag(
                      label: currencyText,
                      backgroundColor: Colors.blue.shade100.withOpacity(isDark ? 0.15 : 0.6),
                      textColor: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
                    ),
                    const SizedBox(width: 8.0),
                    _BadgeTag(
                      label: countriesCount == 1 ? '1 Country' : '$countriesCount Countries',
                      backgroundColor: Colors.teal.shade100.withOpacity(isDark ? 0.15 : 0.6),
                      textColor: isDark ? Colors.teal.shade300 : Colors.teal.shade800,
                    ),
                    const SizedBox(width: 8.0),
                    _BadgeTag(
                      label: autoTaxes ? 'Auto Tax' : 'Manual Tax',
                      backgroundColor: (autoTaxes ? Colors.purple.shade100 : Colors.orange.shade100).withOpacity(isDark ? 0.15 : 0.6),
                      textColor: autoTaxes
                          ? (isDark ? Colors.purple.shade300 : Colors.purple.shade800)
                          : (isDark ? Colors.orange.shade300 : Colors.orange.shade800),
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
}

class _BadgeTag extends StatelessWidget {
  const _BadgeTag({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
      ),
    );
  }
}

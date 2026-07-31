import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/routing/app_router.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_admin/src/features/promotions/presentation/screens/promotions/components/promotion_rule_type_label.dart';

class PromotionCard extends StatelessWidget {
  const PromotionCard(this.discount,
      {super.key, this.onToggle, this.onDelete, this.onTap, this.onEdit});
  final Promotion discount;
  final void Function()? onToggle;
  final void Function()? onDelete;
  final void Function()? onTap;
  final void Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    const manatee = ColorManager.manatee;
    final smallTextStyle = context.bodySmall;
    final mediumTextStyle = context.bodyMedium;
    final isInactive = discount.status == PromotionStatus.inactive;

    // Define colors for Promotion Type (Vibrant, Harmonies)
    Color typeColor;
    Color typeBgColor;
    String typeText;
    switch (discount.type) {
      case PromotionType.standard:
        typeColor = const Color(0xFFE48629); // Vibrant Afriomarkets Orange
        typeBgColor = const Color(0xFFE48629).withValues(alpha: 0.12);
        typeText = 'Standard %';
        break;
      case PromotionType.buyget:
        typeColor = const Color(0xFF2979FF); // Premium Blue
        typeBgColor = const Color(0xFF2979FF).withValues(alpha: 0.12);
        typeText = 'Buy X Get Y';
        break;
      default:
        typeColor = Colors.teal;
        typeBgColor = Colors.teal.withValues(alpha: 0.12);
        typeText = 'Promotion';
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isInactive
              ? Colors.grey.withValues(alpha: 0.15)
              : typeColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isInactive
                  ? [
                      Theme.of(context).cardColor,
                      Theme.of(context).cardColor.withValues(alpha: 0.9),
                    ]
                  : [
                      typeBgColor.withValues(alpha: 0.05),
                      Theme.of(context).cardColor,
                    ],
            ),
          ),
          child: InkWell(
            onTap: onTap ??
                () => context.pushRoute(PromotionDetailsRoute(discount: discount)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Code Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isInactive
                              ? Colors.grey.withValues(alpha: 0.12)
                              : typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.discount_outlined,
                              size: 16,
                              color: isInactive ? Colors.grey : typeColor,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              discount.code ?? '',
                              style: TextStyle(
                                color: isInactive ? Colors.grey : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // More action button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.03),
                          padding: const EdgeInsets.all(8.0),
                        ),
                        onPressed: () async {
                          await showModalActionSheet<int>(
                              title: 'Manage discount',
                              message: discount.code ?? '',
                              context: context,
                              actions: <SheetAction<int>>[
                                const SheetAction(label: 'Edit', key: 0),
                                discount.status == PromotionStatus.inactive
                                    ? const SheetAction(
                                        label: 'Enable', key: 1)
                                    : const SheetAction(
                                        label: 'Disable', key: 1),
                                const SheetAction(
                                    label: 'Delete',
                                    isDestructiveAction: true,
                                    key: 2),
                              ]).then((value) async {
                            if (value == null) return;
                            switch (value) {
                              case 0:
                                await context
                                    .pushRoute(AddUpdatePromotionRoute(
                                        promotion: discount))
                                    .then((value) {
                                  if (value is Promotion) {
                                    onEdit?.call();
                                  }
                                });
                                break;
                              case 1:
                                onToggle?.call();
                                break;
                              case 2:
                                if (!context.mounted) return;
                                await showOkCancelAlertDialog(
                                        context: context,
                                        title: 'Delete Promotion',
                                        message:
                                            'Are you sure you want to delete this promotion?',
                                        okLabel: 'Yes, delete',
                                        cancelLabel: 'Cancel',
                                        isDestructiveAction: true)
                                    .then((value) async {
                                  if (value == OkCancelResult.ok) {
                                    onDelete?.call();
                                  }
                                });
                                break;
                            }
                          });
                        },
                        icon: const Icon(Icons.more_horiz, size: 20),
                      ),
                    ],
                  ),
                  const Gap(10),
                  // Description
                  if (discount.campaign?.description?.isNotEmpty ?? false) ...[
                    Text(
                      discount.campaign?.description ?? '',
                      style: mediumTextStyle?.copyWith(
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                    const Gap(12),
                  ],
                  // Tags & Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Promotion type tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeBgColor,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: typeColor.withValues(alpha: 0.2),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          typeText,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Redemption Count
                      Row(
                        children: [
                          Icon(
                            Icons.star_border,
                            size: 16,
                            color: Colors.amber.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            'Redemptions: ${discount.campaign?.budget?.limit ?? 0}',
                            style: smallTextStyle?.copyWith(
                              color: manatee,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  // Status & Toggle indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PromotionStatusDot(disabled: isInactive),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: manatee.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:info_popup/info_popup.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/extensions/num_extension.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_admin/src/features/promotions/presentation/screens/promotions/components/promotion_rule_type_label.dart';
import 'package:super_banners/super_banners.dart';

class DiscountDetailsCard extends StatelessWidget {
  const DiscountDetailsCard(this.discount, {super.key, this.toggle});
  final Promotion discount;
  final void Function()? toggle;

  @override
  Widget build(BuildContext context) {
    final disabled = discount.status == PromotionStatus.inactive;
    const manatee = ColorManager.manatee;
    final mediumTextStyle = context.bodyMedium;
    const space = Gap(12);

    final endsAt = discount.campaign?.endsAt;
    final isExpired = endsAt != null && endsAt.isBefore(DateTime.now());

    Widget discountValueText() {
      final appMethod = discount.applicationMethod;
      if (appMethod == null) return const SizedBox.shrink();
      
      final type = appMethod.type; // percentage, fixed
      final value = appMethod.value ?? 0;
      final currency = appMethod.currencyCode ?? 'usd';
      
      String valueText = '';
      Color valueColor = Colors.green;
      String detail = '';
      
      if (type == 'fixed') {
        valueText = value.formatAsPrice(currency);
        valueColor = Colors.orangeAccent;
        detail = ' ${currency.toUpperCase()}';
      } else {
        valueText = value.toString();
        valueColor = Colors.blueAccent;
        detail = ' %';
      }
      
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valueText, style: context.headlineSmall?.copyWith(color: valueColor)),
          if (detail.isNotEmpty) Text(detail.toUpperCase(), style: mediumTextStyle?.copyWith(color: manatee)),
        ],
      );
    }

    String regionsName(Promotion discount) {
      final regionsRule = discount.rules?.where((e) => e.attribute == 'regions').firstOrNull;
      if (regionsRule == null || regionsRule.values.isEmpty) {
        return 'No regions configured';
      }
      return regionsRule.values.map((v) {
        if (v.label != null && v.label!.isNotEmpty) {
          try {
            final reg = jsonDecode(v.label!);
            return reg['name'] ?? reg['id'];
          } catch (_) {}
        }
        return v.value;
      }).join(', ');
    }

    final regionsRule = discount.rules?.where((e) => e.attribute == 'regions').firstOrNull;
    final regionsCount = regionsRule?.values.length ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(discount.code ?? '', style: context.headlineMedium),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: isExpired ? 12.0 : 0.0),
                        child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () async {
                              await showOkCancelAlertDialog(
                                      context: context,
                                      title: disabled ? 'Enable' : 'Disable',
                                      message: 'Are you sure you want to ${disabled ? 'enable' : 'disable'} discount?',
                                      okLabel: 'Yes, ${disabled ? 'enable' : 'disable'}',
                                      isDestructiveAction: true)
                                  .then((value) async {
                                if (value == OkCancelResult.ok) {
                                  toggle?.call();
                                }
                              });
                            },
                            child: PromotionStatusDot(disabled: disabled)),
                      ),
                    ],
                  ),
                  if (discount.campaign?.description?.isNotEmpty ?? false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        space,
                        Text(discount.campaign?.description ?? '', style: mediumTextStyle?.copyWith(color: manatee)),
                      ],
                    ),
                  space,
                  IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              discountValueText(),
                              Text('Discount Amount', style: mediumTextStyle?.copyWith(color: manatee))
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 0),
                        Flexible(
                          child: InfoPopupWidget(
                            arrowTheme: const InfoPopupArrowTheme(
                              arrowDirection: ArrowDirection.up,
                              color: ColorManager.primary,
                            ),
                            contentTheme: InfoPopupContentTheme(
                              infoContainerBackgroundColor: Theme.of(context).appBarTheme.backgroundColor!,
                              infoTextStyle: mediumTextStyle!,
                              contentPadding: const EdgeInsets.all(8),
                              contentBorderRadius: const BorderRadius.all(Radius.circular(4)),
                              infoTextAlign: TextAlign.start,
                            ),
                            contentTitle: regionsName(discount),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(regionsCount.toString(),
                                    style: Theme.of(context).textTheme.bodyLarge),
                                Text('Valid Regions', style: mediumTextStyle.copyWith(color: manatee))
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 0),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0', style: Theme.of(context).textTheme.bodyLarge),
                              Text('Total Redemptions',
                                  style: mediumTextStyle.copyWith(color: manatee),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            if (isExpired)
              CornerBanner(
                bannerColor: Colors.red,
                bannerPosition: CornerBannerPosition.topRight,
                child: Text(
                  'Expired',
                  style: mediumTextStyle.copyWith(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

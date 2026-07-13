import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/extensions/string_extension.dart';

class ShippingOptionCard extends StatelessWidget {
  const ShippingOptionCard(
      {super.key,
      required this.shippingOption,
      this.region,
      this.onEditTap,
      this.onDeleteTap});
  final ShippingOption shippingOption;
  final Region? region;
  final void Function()? onEditTap;
  final void Function()? onDeleteTap;
  @override
  Widget build(BuildContext context) {
    const manatee = ColorManager.manatee;
    final smallTextStyle = context.bodySmall;
    final mediumTextStyle = context.bodyMedium;
    const halfSpace = SizedBox(height: 6.0);
    final currencyCode = region?.currencyCode?.toUpperCase() ?? '';

    String formatAmount(int? amount) {
      if (amount == null) return '';
      return '${(amount / 100).toStringAsFixed(2)} $currencyCode';
    }

    int? getAmount() {
      if (shippingOption.prices != null && shippingOption.prices!.isNotEmpty && currencyCode.isNotEmpty) {
        for (var price in shippingOption.prices!) {
          if (price.currencyCode.toLowerCase() == currencyCode.toLowerCase()) {
            return price.amount;
          }
        }
        return shippingOption.prices!.first.amount;
      }
      return null;
    }

    String getMaxText() {
      String text = '';
      if (shippingOption.rules != null) {
        for (var rule in shippingOption.rules!) {
          if (rule.attribute == 'max_subtotal') {
            final parsedValue = int.tryParse(rule.value?.toString() ?? '');
            text = 'Max. subtotal: ${formatAmount(parsedValue)}';
          }
        }
      }
      if (text.isEmpty) {
        return 'Max. subtotal: N/A';
      }
      return text;
    }

    String getMinText() {
      String text = '';
      if (shippingOption.rules != null) {
        for (var rule in shippingOption.rules!) {
          if (rule.attribute == 'min_subtotal') {
            final parsedValue = int.tryParse(rule.value?.toString() ?? '');
            text = 'Min. subtotal: ${formatAmount(parsedValue)}';
          }
        }
      }
      if (text.isEmpty) {
        return 'Min. subtotal: N/A';
      }
      return text;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Text(shippingOption.name ?? '',
                          style: mediumTextStyle?.copyWith(
                              fontWeight: FontWeight.w500))),
                  IconButton(
                      onPressed: () async {
                        await showModalActionSheet<int>(
                            // title: (shippingOption.isReturn)
                            //     ? 'Manage return shipping option'
                            //     : 'Manage shipping option',
                            message: shippingOption.name,
                            context: context,
                            actions: <SheetAction<int>>[
                              const SheetAction(label: 'Edit', key: 0),
                              const SheetAction(
                                  label: 'Delete',
                                  isDestructiveAction: true,
                                  key: 1),
                            ]).then((value) async {
                          switch (value) {
                            case 0:
                              onEditTap?.call();
                              break;
                            case 1:
                              onDeleteTap?.call();
                              break;
                          }
                        });
                      },
                      icon: const Icon(Icons.more_horiz))
                ],
              ),
              halfSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                        'Flat Rate: ${formatAmount(getAmount())}',
                        style: smallTextStyle?.copyWith(color: manatee)),
                  ),
                ],
              ),
              halfSpace,
              Text('${getMinText()} - ${getMaxText()}',
                  style: smallTextStyle?.copyWith(color: manatee)),
              halfSpace,
            ],
          ),
        ],
      ),
    );
  }
}

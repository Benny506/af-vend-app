import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/extensions/num_extension.dart';
import 'package:medusa_admin/src/core/extensions/medusa_model_extension.dart';

class OrderSummeryCard extends StatelessWidget {
  const OrderSummeryCard({super.key, required this.order, required this.index});
  final Order order;
  final int index;
  @override
  Widget build(BuildContext context) {
    final smallTextStyle = context.bodySmall;
    final mediumTextStyle = context.bodyMedium;
    final item = order.items![index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        children: [
          if (item.thumbnail != null)
          SizedBox(
            height: 50,
            width: 50,
            child: CachedNetworkImage(
              key: ValueKey(item.thumbnail),
              imageUrl: item.thumbnail!,
              placeholder: (context, text) =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              errorWidget: (context, string, error) =>
                  const Icon(Icons.warning_rounded, color: Colors.redAccent),
            ),
          ),
          const SizedBox(width: 6.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    item.title ?? '',
                    style: mediumTextStyle,
                  ),
                ),
                Builder(
                  builder: (context) {
                    String variantDisplayTitle = '';
                    if (item.variant?.title != null && item.variant!.title!.trim().isNotEmpty) {
                      variantDisplayTitle = item.variant!.title!;
                    } else if (item.variantTitle != null && item.variantTitle!.trim().isNotEmpty) {
                      variantDisplayTitle = item.variantTitle!;
                    } else if (item.subtitle != null && item.subtitle!.trim().isNotEmpty) {
                      variantDisplayTitle = item.subtitle!;
                    }
                    if (variantDisplayTitle.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        variantDisplayTitle,
                        style: smallTextStyle,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                    '${item.unitPrice.formatAsPrice(order.currencyCode)} x ${item.quantity}',
                    style: smallTextStyle,
                    maxLines: 1),
                const Divider(height: 5),
                Text(
                    ((item.unitPrice ?? 0) * (item.quantity ?? 1)).formatAsPrice(order.currencyCode),
                    style: mediumTextStyle, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/extensions/medusa_model_extension.dart';
import 'package:medusa_admin/src/core/extensions/num_extension.dart';
import 'package:medusa_admin/src/core/extensions/date_time_extension.dart';
import 'package:medusa_admin/src/features/orders/presentation/screens/orders/components/payment_status_label.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:flex_expansion_tile/flex_expansion_tile.dart';

class OrderPayment extends StatelessWidget {
  const OrderPayment(this.order, {super.key, this.onExpansionChanged, this.onCapturePressed});
  final Order order;
  final void Function(bool)? onExpansionChanged;
  final void Function(String)? onCapturePressed;
  @override
  Widget build(BuildContext context) {
    final refunded = order.refundedTotal > 0;
    const space = Gap(12);
    const halfSpace = Gap(6);
    final tr = context.tr;
    final mediumTextStyle = context.bodyMedium;
    const manatee = ColorManager.manatee;
    final largeTextStyle = context.bodyLarge;
    Widget? getButton() {
      final pId = order.paymentId;
      if (pId != null &&
          (order.paymentStatus == PaymentStatus.authorized ||
              order.paymentStatus == PaymentStatus.requiresAction ||
              order.paymentStatus == PaymentStatus.awaiting)) {
        return TextButton(
          onPressed: () => onCapturePressed?.call(pId),
          child: Text(tr.templatesCapturePayment),
        );
      }
      return null;
    }

    return FlexExpansionTile(
      onExpansionChanged: onExpansionChanged,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(tr.detailsPayment),
      trailing: getButton(),
      childPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                  alignment: Alignment.centerRight,
                  child:
                      PaymentStatusLabel(paymentStatus: order.paymentStatus!)),
              space,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details',
                          style: mediumTextStyle,
                        ),
                        halfSpace,
                        if (order.createdAt != null)
                          Text(
                              'on ${order.createdAt.formatDate()} at ${order.createdAt.formatTime()}',
                              style: mediumTextStyle!.copyWith(color: manatee)),
                      ],
                    ),
                  ),
                  Text(
                      order.paidTotal.formatAsPrice(order.currencyCode) ??
                          '',
                      style: largeTextStyle),
                ],
              ),
              space,
              if (refunded)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 12.0),
                        const Icon(Icons.double_arrow_rounded),
                        Text(
                          tr.detailsRefunded,
                          style: mediumTextStyle,
                        ),
                      ],
                    ),
                    Text(
                        '- ${order.refundedTotal.formatAsPrice(order.currencyCode)}',
                        style: mediumTextStyle),
                  ],
                ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr.detailsTotalPaid, style: largeTextStyle),
              Text(
                  (refunded
                          ? order.refundableAmount
                          : order.paidTotal)
                      .formatAsPrice(order.currencyCode),
                  style: largeTextStyle),
            ],
          ),
        ],
      ),
    );
  }
}

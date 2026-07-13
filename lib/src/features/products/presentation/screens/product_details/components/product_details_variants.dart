import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:medusa_admin/src/core/di/di.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/features/products/data/models/product_variant_req.dart';
import 'package:medusa_admin/src/features/products/presentation/bloc/product_crud/product_crud_bloc.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/routing/app_router.dart';
import 'package:flex_expansion_tile/flex_expansion_tile.dart';

class ProductDetailsVariants extends StatelessWidget {
  const ProductDetailsVariants({super.key, required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final smallTextStyle = context.bodySmall;
    final mediumTextStyle = context.bodyMedium;
    const space = Gap(12);
    return FlexExpansionTile(
      onExpansionChanged: (expanded) async {
        if (expanded && key is GlobalKey) {
          await (key as GlobalKey).currentContext.ensureVisibility();
        }
      },
      controlAffinity: ListTileControlAffinity.leading,
      title: const Text('Variants'),
      trailing: IconButton(
          onPressed: () async {
            await showModalActionSheet<int>(context: context, actions: const <SheetAction<int>>[
              SheetAction(label: 'Add Variants', key: 0),
              SheetAction(label: 'Edit Options', key: 2),
            ]).then((result) async {
              if (result == 0) {
                final added = await context.pushRoute<bool>(
                    ProductAddVariantRoute(
                        productVariantReq:
                            ProductVariantReq(product: product)));
                if (added == true && context.mounted) {
                  context.read<ProductCrudBloc>().add(
                      ProductCrudEvent.loadProductVariants(product.id));
                }
              }
            });
          },
          icon: const Icon(Icons.more_horiz)),
      child: Column(
        children: [
          if (product.options != null)
            ListView.separated(
                separatorBuilder: (_, __) => const Divider(),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: product.options!.length,
                itemBuilder: (context, index) {
                  final option = product.options![index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.title ?? '', style: mediumTextStyle),
                      Wrap(
                        spacing: 8.0,
                        children: option.values
                                ?.map((e) => e.value)
                                .toSet()
                                .map((val) => Chip(
                                    label:
                                        Text(val, style: smallTextStyle)))
                                .toList() ??
                            [],
                      ),
                    ],
                  );
                }),
          space,
          space,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Product Variants (${product.variants?.length ?? ''})',
                      style: mediumTextStyle),
                ],
              ),
              space,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text('Title', style: smallTextStyle)),
                  Flexible(child: Text('SKU', style: smallTextStyle)),
                  Flexible(child: Text('EAN', style: smallTextStyle)),
                  Flexible(child: Text('Inventory', style: smallTextStyle)),
                  Flexible(child: Text('', style: smallTextStyle)),
                ],
              ),
              const Divider(),
              if (product.variants != null)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: product.variants!.length,
                  itemBuilder: (context, index) {
                    final variant = product.variants![index];
                    return Row(
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child:
                              Text(variant.title ?? '-', style: smallTextStyle),
                        )),
                        Expanded(
                            child: Text(variant.sku ?? '-',
                                style: smallTextStyle)),
                        Expanded(
                            child: Text(variant.ean ?? '-',
                                style: smallTextStyle)),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Center(
                                  child: Text(
                                      variant.inventoryQuantity.toString(),
                                      style: smallTextStyle)),
                              IconButton(
                                  onPressed: () async {
                                    await showModalActionSheet<int>(
                                        context: context,
                                        actions: <SheetAction<int>>[
                                          const SheetAction(
                                              label: 'Edit Variant', key: 0),
                                          const SheetAction(
                                              label: 'Delete Variant',
                                              key: 1,
                                              isDestructiveAction: true),
                                        ]).then((result) async {
                                      switch (result) {
                                        case 0:
                                          if (!context.mounted) return;
                                          final updated = await context.pushRoute<bool>(
                                              ProductAddVariantRoute(
                                                  productVariantReq:
                                                      ProductVariantReq(
                                                          product: product,
                                                          productVariant:
                                                              variant)));
                                          if (updated == true && context.mounted) {
                                            context.read<ProductCrudBloc>().add(
                                                ProductCrudEvent.loadProductVariants(product.id));
                                          }
                                          break;
                                        case 1:
                                          final confirm = await showOkCancelAlertDialog(
                                              context: context,
                                              title: 'Delete Variant',
                                              message: 'Are you sure you want to delete this variant?',
                                              okLabel: 'Delete',
                                              isDestructiveAction: true);
                                          if (confirm == OkCancelResult.ok && context.mounted) {
                                            try {
                                              await getIt<MedusaAdminV2>().products.deleteVariant(
                                                  product.id!,
                                                  variant.id!);
                                              if (context.mounted) {
                                                context.read<ProductCrudBloc>().add(
                                                    ProductCrudEvent.loadProductVariants(product.id));
                                              }
                                            } catch (e) {
                                              debugPrint('Error deleting variant: $e');
                                            }
                                          }
                                          break;
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.more_horiz))
                            ],
                          ),
                        )
                      ],
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

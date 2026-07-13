import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:medusa_admin/src/core/di/di.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/extensions/snack_bar_extension.dart';
import 'package:medusa_admin/src/core/extensions/string_extension.dart';
import 'package:medusa_admin/src/core/utils/currency_formatter.dart';

import 'package:medusa_admin/src/core/utils/custom_text_field.dart';
import 'package:medusa_admin/src/core/utils/hide_keyboard.dart';
import 'package:medusa_admin/src/core/utils/labeled_numeric_text_field.dart';
import 'package:medusa_admin/src/features/products/data/models/product_variant_req.dart';
import 'package:medusa_admin/src/features/products/presentation/bloc/product_crud/product_crud_bloc.dart';
import 'package:medusa_admin/src/features/store_details/presentation/bloc/store/store_bloc.dart';
import 'package:medusa_admin/src/features/store_settings/presentation/widgets/countries/country_view.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:medusa_admin_dart_client/src/features/products/data/models/create_product_variant_req.dart';
import 'package:medusa_admin_dart_client/src/features/products/data/models/create_product_variant_price_req.dart';
import 'package:medusa_admin_dart_client/src/features/products/data/models/update_product_variant_req.dart';
import 'package:medusa_admin/src/core/utils/easy_loading.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flex_expansion_tile/flex_expansion_tile.dart';

@RoutePage()
class ProductAddVariantView extends StatefulWidget {
  const ProductAddVariantView(this.productVariantReq, {super.key});
  final ProductVariantReq productVariantReq;

  @override
  State<ProductAddVariantView> createState() => _ProductAddVariantViewState();
}

class _ProductAddVariantViewState extends State<ProductAddVariantView> {
  late Product product;
  late ProductVariant? variant;
  late ProductCrudBloc productCrudBloc;
  List<ProductOption>? get options => productVariantReq.product.options;
  ProductVariantReq get productVariantReq => widget.productVariantReq;
  Map<int, ProductOptionValue> selectedOptionsValue = {};
  bool manageInventory = true;
  bool allowBackorder = false;
  final formKey = GlobalKey<FormState>();
  List<Currency> currencies = [];
  Map<Currency, TextEditingController> currencyCtrlMap =
      <Currency, TextEditingController>{};
  Map<ProductOption, TextEditingController> productOptionCtrlMap =
      <ProductOption, TextEditingController>{};
  Currency defaultCurrency = const Currency();
  final priceCtrl = TextEditingController();
  final metricPriceCtrl = TextEditingController();
  String unitMetric = 'weight';
  bool get updateMode => productVariantReq.productVariant != null;
  final quantityCtrl = TextEditingController();
  final customTitleCtrl = TextEditingController();
  final materialCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final widthCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final lengthCtrl = TextEditingController();
  final midCtrl = TextEditingController();
  final hsCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final skuCtrl = TextEditingController();
  final eanCtrl = TextEditingController();
  final upcCtrl = TextEditingController();
  final barcodeCtrl = TextEditingController();

  final generalKey = GlobalKey();
  final pricingKey = GlobalKey();
  final stockKey = GlobalKey();
  final shippingKey = GlobalKey();

  final generalTileCtrl = FlexExpansionTileController();

  @override
  void initState() {
    productCrudBloc = ProductCrudBloc.instance;
    // Read store currencies from StoreBloc supported_currencies
    final storeState = StoreBloc.instance.state;
    final supportedCurrencies = storeState.mapOrNull(
      stores: (r) => r.response.stores.firstOrNull?.supportedCurrencies,
    );
    final List<Currency> list = [];
    if (supportedCurrencies != null) {
      for (var sc in supportedCurrencies) {
        list.add(Currency(
          code: sc.currencyCode,
          name: sc.currency.name ?? sc.currencyCode.toUpperCase(),
          symbol: sc.currency.symbol ?? sc.currencyCode,
          symbolNative: sc.currency.symbolNative ?? sc.currency.symbol ?? '',
        ));
      }
    }
    currencies = list;
    currencyCtrlMap = {for (var e in currencies) e: TextEditingController()};
    product = productVariantReq.product;
    variant = productVariantReq.productVariant;

    String? defaultCurrencyCode;
    final store = storeState.mapOrNull(stores: (r) => r.response.stores.firstOrNull);
    if (store != null && store.supportedCurrencies != null) {
      for (var sc in store.supportedCurrencies!) {
        if (sc.isDefault) {
          defaultCurrencyCode = sc.currencyCode;
          break;
        }
      }
    }
    defaultCurrencyCode ??= 'usd';

    defaultCurrency = currencies.firstWhere(
      (c) => c.code?.toLowerCase() == defaultCurrencyCode!.toLowerCase(),
      orElse: () => currencies.isNotEmpty ? currencies.first : const Currency(code: 'usd', name: 'US Dollar', symbol: '\$'),
    );

    if (product.options != null) {
      for (var option in product.options!) {
        productOptionCtrlMap[option] = TextEditingController();
      }
    }

    if (updateMode && variant != null) {
      variant!.options?.forEach((optionValue) {
        final option = product.options?.firstWhere((o) => o.id == optionValue.optionId, orElse: () => const ProductOption(id: ''));
        if (option != null && option.id.isNotEmpty) {
          productOptionCtrlMap[option]?.text = optionValue.value;
        }
      });
      final defaultPrice = (variant!.prices ?? []).firstWhere(
        (p) => p.currencyCode?.toLowerCase() == defaultCurrencyCode?.toLowerCase(),
        orElse: () => MoneyAmount(amount: 0, currencyCode: defaultCurrencyCode!, id: ''),
      );
      if (defaultPrice.amount != null) {
        priceCtrl.text = (defaultPrice.amount! / 100).toStringAsFixed(2);
      }
      final meta = variant!.metadata;
      if (meta != null) {
        metricPriceCtrl.text = meta['metric_price']?.toString() ?? '0';
        unitMetric = meta['unit_metric']?.toString() ?? 'weight';
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    productCrudBloc.close();
    quantityCtrl.dispose();
    customTitleCtrl.dispose();
    materialCtrl.dispose();
    heightCtrl.dispose();
    widthCtrl.dispose();
    weightCtrl.dispose();
    lengthCtrl.dispose();
    midCtrl.dispose();
    hsCtrl.dispose();
    countryCtrl.dispose();
    skuCtrl.dispose();
    eanCtrl.dispose();
    upcCtrl.dispose();
    barcodeCtrl.dispose();
    priceCtrl.dispose();
    metricPriceCtrl.dispose();
    productOptionCtrlMap.forEach((key, value) => value.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const manatee = ColorManager.manatee;
    final smallTextStyle = context.bodySmall;
    final mediumTextStyle = context.bodyMedium;
    final largeTextStyle = context.bodyLarge;
    const space = Gap(12);
    return BlocListener<ProductCrudBloc, ProductCrudState>(
      bloc: productCrudBloc,
      listener: (context, state) {
        state.maybeWhen(
          loading: (_) => loading(),
          updated: (_) {
            dismissLoading();
            context.showSnackBar('Attributes updated');
            context.router.popForced();
          },
          error: (_) {
            context.showSnackBar('Error updating attributes');
            dismissLoading();
          },
          orElse: () => dismissLoading(),
        );
      },
      child: PopScope(
        canPop: updateMode || !shouldShowWarning(),
        onPopInvoked: (val) async {
          if (val) return;
          await showOkCancelAlertDialog(
            context: context,
            title: 'Discard changes',
            message: 'Are you sure you want to discard changes?',
            okLabel: 'Discard',
            isDestructiveAction: true,
          ).then((result) {
            if (result == OkCancelResult.ok) {
              if (!context.mounted) return;
              context.router.pop();
            }
          });
        },
        child: HideKeyboard(
          child: Scaffold(
            appBar: AppBar(
              leading: const CloseButton(),
              title: Text(updateMode ? 'Update Attributes' : 'Create Variant'),
              actions: [
                TextButton(
                    onPressed: () async => await save(context),
                    child: const Text('Save')),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      FlexExpansionTile(
                        key: generalKey,
                        onExpansionChanged: (expanded) async {
                          if (expanded) {
                            await generalKey.currentContext.ensureVisibility();
                          }
                        },
                        initiallyExpanded: true,
                        controller: generalTileCtrl,
                        title: const Text('General'),
                        child: Column(
                          children: [
                            Text(
                                'Configure the general information for this variant.',
                                style:
                                    smallTextStyle?.copyWith(color: manatee)),
                            space,
                            LabeledTextField(
                              label: 'Custom title',
                              controller: customTitleCtrl,
                              hintText: 'Green / XL',
                            ),
                            LabeledTextField(
                              label: 'Material',
                              controller: materialCtrl,
                              hintText: '80% wool, 20% cotton',
                            ),
                            const Divider(),
                            Row(
                              children: [
                                Text('Options', style: largeTextStyle),
                              ],
                            ),
                            space,
                            if (options != null && !updateMode)
                              ListView.separated(
                                shrinkWrap: true,
                                itemCount: options!.length,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final currentOption = options![index];
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(currentOption.title ?? '',
                                              style: mediumTextStyle),
                                          Text(' *',
                                              style: mediumTextStyle?.copyWith(
                                                  color: Colors.red)),
                                        ],
                                      ),
                                      const Gap(6.0),
                                      if (currentOption.values != null)
                                        DropdownButtonFormField(
                                          style: context.bodyMedium,
                                          validator: (val) {
                                            if (val == null) {
                                              return 'Field is required';
                                            }
                                            return null;
                                          },
                                          items: currentOption.values!
                                              .map((e) => DropdownMenuItem(
                                                  value: e,
                                                  child: Text(e.value)))
                                              .toList(),
                                          hint: const Text('Choose an option'),
                                          onChanged: (value) {
                                            if (value != null) {
                                              selectedOptionsValue[index] =
                                                  value;
                                            }
                                          },
                                        ),
                                    ],
                                  );
                                },
                                separatorBuilder: (_, __) => space,
                              ),
                            if (options != null && updateMode)
                              ListView.separated(
                                shrinkWrap: true,
                                itemCount: options!.length,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final currentOption = options![index];
                                  final textCtrl =
                                      productOptionCtrlMap[currentOption];
                                  return LabeledTextField(
                                    label: currentOption.title ?? '',
                                    required: true,
                                    controller: textCtrl,
                                  );
                                },
                                separatorBuilder: (_, __) => space,
                              ),
                            space,
                          ],
                        ),
                      ),
                      space,
                      FlexExpansionTile(
                        key: pricingKey,
                        onExpansionChanged: (expanded) async {
                          if (expanded) {
                            await pricingKey.currentContext.ensureVisibility();
                          }
                        },
                        title: const Text('Pricing'),
                        childPadding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 4.0),
                        child: Column(
                          children: [
                            Text('Configure the pricing for this variant.',
                                style:
                                    smallTextStyle?.copyWith(color: manatee)),
                            space,
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(12.0)),
                                color: Theme.of(context)
                                    .scaffoldBackgroundColor,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Text(
                                            defaultCurrency.code
                                                    ?.toUpperCase() ??
                                                '',
                                            style: mediumTextStyle),
                                        space,
                                        Expanded(
                                            child: Text(
                                                defaultCurrency.name ?? '',
                                                style: mediumTextStyle
                                                    ?.copyWith(
                                                        color:
                                                            manatee)))
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: TextField(
                                      controller: priceCtrl,
                                      textDirection:
                                          TextDirection.rtl,
                                      keyboardType:
                                          const TextInputType
                                              .numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                        hintTextDirection:
                                            TextDirection.rtl,
                                        prefixIcon: Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    left: 10),
                                            child: Text(
                                                defaultCurrency.symbol ??
                                                    '',
                                                style: mediumTextStyle
                                                    ?.copyWith(
                                                        color:
                                                            manatee))),
                                        prefixIconConstraints:
                                            const BoxConstraints(
                                                minWidth: 0,
                                                minHeight: 0),
                                        hintText: '-',
                                        isDense: true,
                                        border:
                                            const OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.all(
                                                  Radius.circular(
                                                      4.0)),
                                        ),
                                      ),
                                      style: smallTextStyle,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            space,
                            LabeledNumericTextField(
                              controller: metricPriceCtrl,
                              label: 'Metric Price',
                            ),
                            space,
                            Row(
                              children: [
                                Text('Unit Metric', style: mediumTextStyle),
                              ],
                            ),
                            const Gap(6.0),
                            DropdownButtonFormField<String>(
                              value: unitMetric,
                              style: context.bodyMedium,
                              items: const [
                                DropdownMenuItem(
                                    value: 'weight',
                                    child: Text('Weight | Kilogram (kg)')),
                                DropdownMenuItem(
                                    value: 'volume',
                                    child: Text('Volume')),
                              ],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                  if (value != null) {
                                    setState(() => unitMetric = value);
                                  }
                              },
                            ),
                          ],
                        ),
                      ),
                      space,
                      FlexExpansionTile(
                        title: const Text('Stock & Inventory'),
                        key: stockKey,
                        onExpansionChanged: (expanded) async {
                          if (expanded) {
                            await stockKey.currentContext.ensureVisibility();
                          }
                        },
                        child: Column(
                          children: [
                            Text(
                                'Configure the inventory and stock for this variant.',
                                style:
                                    smallTextStyle?.copyWith(color: manatee)),
                            space,
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Manage inventory',
                                  style: largeTextStyle),
                              subtitle: Text(
                                  'When checked Medusa will regulate the inventory when orders and returns are made.',
                                  style:
                                      smallTextStyle?.copyWith(color: manatee)),
                              value: manageInventory,
                              onChanged: (val) =>
                                  setState(() => manageInventory = val),
                              activeColor: Theme.of(context).platform == TargetPlatform.iOS
                                  ? ColorManager.primary
                                  : null,
                            ),
                            space,
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Allow backorders',
                                  style: largeTextStyle),
                              subtitle: Text(
                                  'When checked the product will be available for purchase despite the product being sold out',
                                  style:
                                      smallTextStyle?.copyWith(color: manatee)),
                              value: allowBackorder,
                              onChanged: (val) =>
                                  setState(() => allowBackorder = val),
                              activeColor: Theme.of(context).platform == TargetPlatform.iOS
                                  ? ColorManager.primary
                                  : null,
                            ),
                            space,
                            LabeledTextField(
                              label: 'Stock keeping unit (SKU)',
                              controller: TextEditingController(),
                              hintText: 'SUN-G, JK1234...',
                            ),
                            LabeledNumericTextField(
                              controller: quantityCtrl,
                              label: 'Quantity in stock',
                            ),
                            space,
                            LabeledTextField(
                              label: 'EAN (Barcode)',
                              controller: eanCtrl,
                              hintText: '123456789123...',
                            ),
                            LabeledTextField(
                              label: 'UPC (Barcode)',
                              controller: upcCtrl,
                              hintText: '023456789104',
                            ),
                            LabeledTextField(
                              label: 'Barcode',
                              controller: barcodeCtrl,
                              hintText: '123456789104...',
                            ),
                          ],
                        ),
                      ),
                      space,
                      FlexExpansionTile(
                        title: const Text('Shipping'),
                        key: shippingKey,
                        onExpansionChanged: (expanded) async {
                          if (expanded) {
                            await shippingKey.currentContext.ensureVisibility();
                          }
                        },
                        child: Column(
                          children: [
                            Text(
                                'Shipping information can be required depending on your shipping provider, and whether or not you are shipping internationally.',
                                style:
                                    smallTextStyle?.copyWith(color: manatee)),
                            space,
                            Row(
                              children: [
                                Text('Dimensions', style: largeTextStyle),
                              ],
                            ),
                            space,
                            Text(
                                'Configure to calculate the most accurate shipping rates.',
                                style:
                                    smallTextStyle?.copyWith(color: manatee)),
                            space,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: LabeledNumericTextField(
                                      controller: widthCtrl, label: 'Width'),
                                ),
                                space,
                                Flexible(
                                  child: LabeledNumericTextField(
                                      controller: lengthCtrl, label: 'Length'),
                                ),
                              ],
                            ),
                            space,
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: LabeledNumericTextField(
                                      controller: heightCtrl, label: 'Height'),
                                ),
                                space,
                                Flexible(
                                  child: LabeledNumericTextField(
                                      controller: weightCtrl, label: 'Weight'),
                                ),
                              ],
                            ),
                            space,
                            space,
                            Row(
                              children: [
                                Text('Customs', style: largeTextStyle),
                              ],
                            ),
                            space,
                            Text(
                                'Configure if you are shipping internationally.',
                                style:
                                    smallTextStyle?.copyWith(color: manatee)),
                            space,
                            LabeledTextField(
                              label: 'MID Code',
                              controller: midCtrl,
                              hintText: 'XDSKLAD9999...',
                            ),
                            LabeledTextField(
                              label: 'HS Code',
                              controller: hsCtrl,
                              hintText: 'BDJSK39277W...',
                            ),
                            LabeledTextField(
                              readOnly: true,
                              onTap: () async {
                                final result = await showBarModalBottomSheet(
                                    context: context,
                                    backgroundColor:
                                        context.theme.scaffoldBackgroundColor,
                                    overlayStyle: context
                                        .theme.appBarTheme.systemOverlayStyle,
                                    builder: (context) =>
                                        const SelectCountryView());
                                if (result is List<Country>) {
                                  countryCtrl.text =
                                      result.first.displayOnStore;
                                  setState(() {});
                                }
                              },
                              label: 'Country of origin',
                              controller: countryCtrl,
                              decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                hintText: 'Choose a country',
                                suffixIcon: countryCtrl.text.isEmpty
                                    ? const Icon(
                                        Icons.keyboard_arrow_down_outlined)
                                    : IconButton(
                                        onPressed: () {
                                          countryCtrl.clear();
                                          setState(() {});
                                        },
                                        icon: const Icon(CupertinoIcons
                                            .clear_circled_solid)),
                                filled: true,
                                fillColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(4.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool shouldShowWarning() {
    if (customTitleCtrl.text.removeAllWhitespace.isNotEmpty ||
        materialCtrl.text.removeAllWhitespace.isNotEmpty ||
        selectedOptionsValue.isNotEmpty ||
        skuCtrl.text.removeAllWhitespace.isNotEmpty ||
        quantityCtrl.text.removeAllWhitespace.isNotEmpty ||
        eanCtrl.text.removeAllWhitespace.isNotEmpty ||
        upcCtrl.text.removeAllWhitespace.isNotEmpty ||
        barcodeCtrl.text.removeAllWhitespace.isNotEmpty ||
        widthCtrl.text.removeAllWhitespace.isNotEmpty ||
        lengthCtrl.text.removeAllWhitespace.isNotEmpty ||
        heightCtrl.text.removeAllWhitespace.isNotEmpty ||
        weightCtrl.text.removeAllWhitespace.isNotEmpty ||
        midCtrl.text.removeAllWhitespace.isNotEmpty ||
        hsCtrl.text.removeAllWhitespace.isNotEmpty ||
        countryCtrl.text.removeAllWhitespace.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> save(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      generalTileCtrl.expand();
      return;
    }
    String variantTitle = '';
    final List<ProductOptionValue> variantOptions = [];
    final Map<String, String> optionsMap = {};

    if (customTitleCtrl.text.removeAllWhitespace.isNotEmpty) {
      variantTitle = customTitleCtrl.text;
    } else {
      selectedOptionsValue.forEach((key, value) {
        variantOptions.add(value);
        if (variantTitle.isEmpty) {
          variantTitle = value.value;
        } else {
          variantTitle = '$variantTitle / ${value.value}';
        }
      });
    }

    if (updateMode) {
      productOptionCtrlMap.forEach((option, ctrl) {
        if (ctrl.text.isNotEmpty) {
          optionsMap[option.id!] = ctrl.text;
          variantOptions.add(ProductOptionValue(
            id: '',
            value: ctrl.text,
            optionId: option.id,
          ));
        }
      });
    } else {
      selectedOptionsValue.forEach((index, value) {
        final option = options![index];
        optionsMap[option.id!] = value.value;
      });
    }

    final pricesList = <CreateProductVariantPriceReq>[];
    final amountParsed = double.tryParse(priceCtrl.text.replaceAll(',', '').replaceAll(' ', ''));
    if (amountParsed != null) {
      pricesList.add(CreateProductVariantPriceReq(
        currencyCode: defaultCurrency.code!,
        amount: (amountParsed * 100).toInt(),
      ));
    } else {
      pricesList.add(CreateProductVariantPriceReq(
        currencyCode: defaultCurrency.code ?? 'usd',
        amount: 0,
      ));
    }

    final metadata = <String, dynamic>{};
    final mPrice = double.tryParse(metricPriceCtrl.text);
    if (mPrice != null) {
      metadata['metric_price'] = mPrice;
    }
    metadata['unit_metric'] = unitMetric;

    EasyLoading.show();

    try {
      if (updateMode) {
        await getIt<MedusaAdminV2>().products.updateVariant(
          product.id!,
          variant!.id!,
          UpdateProductVariantReq(
            title: variantTitle,
            sku: skuCtrl.text.isEmpty ? null : skuCtrl.text,
            ean: eanCtrl.text.isEmpty ? null : eanCtrl.text,
            upc: upcCtrl.text.isEmpty ? null : upcCtrl.text,
            barcode: barcodeCtrl.text.isEmpty ? null : barcodeCtrl.text,
            hsCode: hsCtrl.text.isEmpty ? null : hsCtrl.text,
            midCode: midCtrl.text.isEmpty ? null : midCtrl.text,
            allowBackorder: allowBackorder,
            manageInventory: manageInventory,
            weight: weightCtrl.text.isEmpty ? null : weightCtrl.text,
            length: lengthCtrl.text.isEmpty ? null : lengthCtrl.text,
            height: heightCtrl.text.isEmpty ? null : heightCtrl.text,
            width: widthCtrl.text.isEmpty ? null : widthCtrl.text,
            originCountry: countryCtrl.text.isEmpty ? null : countryCtrl.text,
            material: materialCtrl.text.isEmpty ? null : materialCtrl.text,
            metadata: metadata.isNotEmpty ? metadata : null,
            prices: pricesList,
            options: optionsMap,
          ),
        );
        EasyLoading.dismiss();
        if (context.mounted) {
          context.showSnackBar('Variant updated successfully!');
          context.router.popForced(true);
        }
      } else {
        await getIt<MedusaAdminV2>().products.createVariant(
          product.id!,
          CreateProductVariantReq(
            title: variantTitle,
            sku: skuCtrl.text.isEmpty ? null : skuCtrl.text,
            ean: eanCtrl.text.isEmpty ? null : eanCtrl.text,
            upc: upcCtrl.text.isEmpty ? null : upcCtrl.text,
            barcode: barcodeCtrl.text.isEmpty ? null : barcodeCtrl.text,
            hsCode: hsCtrl.text.isEmpty ? null : hsCtrl.text,
            midCode: midCtrl.text.isEmpty ? null : midCtrl.text,
            allowBackorder: allowBackorder,
            manageInventory: manageInventory,
            weight: weightCtrl.text.isEmpty ? null : weightCtrl.text,
            length: lengthCtrl.text.isEmpty ? null : lengthCtrl.text,
            height: heightCtrl.text.isEmpty ? null : heightCtrl.text,
            width: widthCtrl.text.isEmpty ? null : widthCtrl.text,
            originCountry: countryCtrl.text.isEmpty ? null : countryCtrl.text,
            material: materialCtrl.text.isEmpty ? null : materialCtrl.text,
            metadata: metadata.isNotEmpty ? metadata : null,
            prices: pricesList,
            options: optionsMap,
          ),
        );
        EasyLoading.dismiss();
        if (context.mounted) {
          context.showSnackBar('Variant created successfully!');
          context.router.popForced(true);
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('Error saving variant: $e');
      if (context.mounted) {
        context.showSnackBar('Error saving variant: $e');
      }
    }
  }
}

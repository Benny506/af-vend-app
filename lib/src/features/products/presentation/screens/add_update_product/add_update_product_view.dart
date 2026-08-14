import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flex_expansion_tile/flex_expansion_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:medusa_admin/src/core/extensions/snack_bar_extension.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/utils/custom_text_field.dart';
import 'package:medusa_admin/src/core/utils/easy_loading.dart';
import 'package:medusa_admin/src/core/utils/hide_keyboard.dart';
import 'package:medusa_admin/src/core/utils/upload_files_cubit/upload_files_cubit.dart';
import 'package:medusa_admin/src/features/products/data/models/update_product_req.dart';
import 'package:medusa_admin/src/features/products/presentation/bloc/product_crud/product_crud_bloc.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_admin_dart_client/src/features/products/data/models/create_product_option_req.dart';
import 'package:medusa_admin_dart_client/src/features/products/data/models/create_product_variant_req.dart';
import 'package:medusa_admin_dart_client/src/features/products/data/models/create_product_variant_price_req.dart';
import 'package:medusa_admin/src/core/utils/file_use_case/upload_use_case.dart';
import 'package:medusa_admin/src/core/utils/image_picker_helper.dart';
import 'package:medusa_admin/src/core/di/di.dart';

import 'components/index.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:medusa_admin/src/features/store_details/presentation/bloc/store/store_bloc.dart';

@RoutePage()
class AddUpdateProductView extends StatefulWidget {
  const AddUpdateProductView({super.key, this.updateProductReq});

  final UpdateProductRequest? updateProductReq;

  @override
  State<AddUpdateProductView> createState() => _AddUpdateProductViewState();
}

class _AddUpdateProductViewState extends State<AddUpdateProductView> {
  // List<ImageData> imagesToDelete = [];
  List<File> images = [];
  File? thumbnailImage;
  Product? product;

  bool get updateMode => widget.updateProductReq != null;
  late ProductCrudBloc productCrudBloc;
  late UploadFilesCubit uploadImagesCubit;
  late UploadFilesCubit uploadThumbnailCubit;
  final keyForm = GlobalKey<FormState>();
  final generalTileCtrl = FlexExpansionTileController();
  final organizeTileCtrl = FlexExpansionTileController();
  final variantTileCtrl = FlexExpansionTileController();
  final attributeTileCtrl = FlexExpansionTileController();
  final thumbnailTileCtrl = FlexExpansionTileController();
  final mediaTileCtrl = FlexExpansionTileController();

  // Simple Mode configuration
  bool simpleMode = true;
  final simpleTitleCtrl = TextEditingController();
  final simpleDescriptionCtrl = TextEditingController();
  final simplePriceCtrl = TextEditingController();
  final simpleStockCtrl = TextEditingController();
  ProductStatus simpleStatus = ProductStatus.draft;
  List<Currency> currencies = [];
  Currency? selectedCurrency;

  @override
  void initState() {
    productCrudBloc = ProductCrudBloc.instance;
    uploadImagesCubit = UploadFilesCubit.instance;
    uploadThumbnailCubit = UploadFilesCubit.instance;
    simpleMode = !updateMode;

    // Load store currencies from StoreBloc
    final storeState = StoreBloc.instance.state;
    final supportedCurrencies = storeState.mapOrNull(
      stores: (r) => r.response.stores.firstOrNull?.supportedCurrencies,
    );
    final List<Currency> list = [];
    if (supportedCurrencies != null) {
      for (var sc in supportedCurrencies) {
        list.add(Currency(
          code: sc.currencyCode,
          name: sc.currency?.name ?? sc.currencyCode.toUpperCase(),
          symbol: sc.currency?.symbol ?? sc.currencyCode,
          symbolNative: sc.currency?.symbolNative ?? sc.currency?.symbol ?? '',
        ));
      }
    }
    currencies = list;

    final store = storeState.mapOrNull(stores: (r) => r.response.stores.firstOrNull);
    if (store != null && store.supportedCurrencies != null) {
      for (var sc in store.supportedCurrencies!) {
        if (sc.isDefault) {
          selectedCurrency = Currency(
            code: sc.currencyCode,
            name: sc.currency?.name ?? sc.currencyCode.toUpperCase(),
            symbol: sc.currency?.symbol ?? sc.currencyCode,
            symbolNative: sc.currency?.symbolNative ?? sc.currency?.symbol ?? '',
          );
          break;
        }
      }
    }
    if (selectedCurrency == null && currencies.isNotEmpty) {
      selectedCurrency = currencies.first;
    }

    // Initialise with a blank product when creating so copyWith never returns null
    product = widget.updateProductReq?.product ??
        const Product(
          id: '',
          title: '',
          handle: '',
          isGiftcard: false,
          status: ProductStatus.draft,
          discountable: true,
        );
    Future.delayed(350.milliseconds).then((value) {
      switch (widget.updateProductReq?.number) {
        case 1:
          generalTileCtrl.expand();
          break;
        case 2:
          organizeTileCtrl.expand();
          break;
        case 3:
          variantTileCtrl.expand();
          break;
        case 4:
          attributeTileCtrl.expand();
          break;
        case 5:
          thumbnailTileCtrl.expand();
          break;
        case 6:
          mediaTileCtrl.expand();
          break;
        default:
          break;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    productCrudBloc.close();
    uploadImagesCubit.close();
    uploadThumbnailCubit.close();
    simpleTitleCtrl.dispose();
    simpleDescriptionCtrl.dispose();
    simplePriceCtrl.dispose();
    simpleStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // You can not be a good person until you know how much
    // evil you contain within you

    const space = Gap(12);
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductCrudBloc, ProductCrudState>(
          bloc: productCrudBloc,
          listener: (context, state) {
            state.maybeWhen(
              loading: (_) => loading(),
              product: (product) {
                dismissLoading();
                context.showSnackBar('Product Created');
                context.maybePop(product);
              },
              updated: (product) {
                dismissLoading();
                context.showSnackBar('Product Updated');
                context.maybePop(product);
              },
              error: (failure) {
                dismissLoading();
                context.showSnackBar(failure.toSnackBarString());
              },
              orElse: () => dismissLoading(),
            );
          },
        ),
        BlocListener<UploadFilesCubit, UploadFilesState>(
          bloc: uploadImagesCubit,
          listener: (context, state) {
            state.mapOrNull(
              uploading: (_) {
                loading();
              },
              uploaded: (state) {
                // dismissLoading();
                // final newImages = List<ImageData>.from(product?.images);
                // for (var url in state.urls) {
                //   newImages.add(ImageData(url: url));
                // }
                // product = product?.copyWith(images: newImages);
                // context.showSnackBar('Images uploaded');
              },
              error: (state) {
                dismissLoading();
                context.showSnackBar(state.failure.toSnackBarString());
              },
            );
          },
        ),
        BlocListener<UploadFilesCubit, UploadFilesState>(
          bloc: uploadThumbnailCubit,
          listener: (context, state) {
            state.maybeWhen(
              uploading: () => loading(),
              uploaded: (urls) {
                dismissLoading();
                product = product?.copyWith(thumbnail: urls.first);
                context.showSnackBar('Thumbnail uploaded');
              },
              error: (failure) {
                dismissLoading();
                context.showSnackBar(failure.toSnackBarString());
              },
              orElse: () {},
            );
          },
        ),
      ],
      child: PopScope(
        onPopInvoked: (val) => deleteTempImages(),
        child: HideKeyboard(
          child: Scaffold(
            appBar: AppBar(
              systemOverlayStyle: context.defaultSystemUiOverlayStyle,
              leading: const CloseButton(),
              title: updateMode
                  ? const Text('Update Product')
                  : const Text('New Product'),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () async {
                      if (!keyForm.currentState!.validate()) {
                        if (!simpleMode) {
                          generalTileCtrl.expand();
                        }
                        return;
                      }
                      keyForm.currentState!.save();
                      context.unfocus();
                      if (updateMode) {
                        await updateProduct();
                      } else {
                        await createProduct();
                      }
                    },
                    child: Text(
                      updateMode ? 'Save' : 'Publish',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 10.0),
                  child: Form(
                    key: keyForm,
                    child: Column(
                      children: [
                        if (!updateMode) ...[
                          // Mode toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.isDark ? const Color(0xFF1E2616) : const Color(0xFFF1F5ED),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => simpleMode = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: simpleMode
                                            ? const Color(0xFF344F16)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Simple Form',
                                        style: TextStyle(
                                          color: simpleMode ? Colors.white : (context.isDark ? Colors.grey : Colors.black87),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => simpleMode = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !simpleMode
                                            ? const Color(0xFF344F16)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Advanced Details',
                                        style: TextStyle(
                                          color: !simpleMode ? Colors.white : (context.isDark ? Colors.grey : Colors.black87),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          space,
                        ],
                        if (simpleMode) ...[
                          // 1. General Info Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: context.isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            ),
                            color: context.isDark ? const Color(0xFF181F10) : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product Info',
                                    style: GoogleFonts.comfortaa(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.isDark ? const Color(0xFFF0EAD6) : const Color(0xFF1A1400),
                                    ),
                                  ),
                                  const Gap(16),
                                  LabeledTextField(
                                    label: 'Product Name',
                                    hintText: 'e.g. Afriomarkets Organic Coffee',
                                    controller: simpleTitleCtrl,
                                    required: true,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Product Name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const Gap(12),
                                  LabeledTextField(
                                    label: 'Description',
                                    hintText: 'Write a few lines about the product...',
                                    controller: simpleDescriptionCtrl,
                                    maxLines: 4,
                                    minLines: 3,
                                  ),
                                  const Gap(16),
                                  DropdownButtonFormField<ProductStatus>(
                                    value: simpleStatus,
                                    style: context.bodyMedium,
                                    decoration: InputDecoration(
                                      labelText: 'Publish Status',
                                      labelStyle: context.bodyMedium?.copyWith(color: ColorManager.manatee),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: context.isDark ? Colors.white24 : Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(color: Color(0xFF344F16)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: context.isDark ? const Color(0xFF131A0B) : Colors.grey.shade50,
                                    ),
                                    items: ProductStatus.values
                                        .map((e) => DropdownMenuItem<ProductStatus>(
                                              value: e,
                                              child: Text(e.name.capitalize),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => simpleStatus = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          space,

                          // 2. Pricing & Stock Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: context.isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            ),
                            color: context.isDark ? const Color(0xFF181F10) : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pricing & Stock',
                                    style: GoogleFonts.comfortaa(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.isDark ? const Color(0xFFF0EAD6) : const Color(0xFF1A1400),
                                    ),
                                  ),
                                  const Gap(16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: LabeledTextField(
                                          label: 'Price',
                                          hintText: '0.00',
                                          controller: simplePriceCtrl,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          required: true,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            if (double.tryParse(value) == null) {
                                              return 'Invalid price';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Currency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                            const Gap(6),
                                            BlocBuilder<StoreBloc, StoreState>(
                                              builder: (context, storeState) {
                                                final supportedCurrencies = storeState.mapOrNull(
                                                  stores: (r) => r.response.stores.firstOrNull?.supportedCurrencies,
                                                );
                                                final List<Currency> list = [];
                                                if (supportedCurrencies != null) {
                                                  for (var sc in supportedCurrencies) {
                                                    list.add(Currency(
                                                      code: sc.currencyCode,
                                                      name: sc.currency?.name ?? sc.currencyCode.toUpperCase(),
                                                      symbol: sc.currency?.symbol ?? sc.currencyCode,
                                                      symbolNative: sc.currency?.symbolNative ?? sc.currency?.symbol ?? '',
                                                    ));
                                                  }
                                                }
                                                if (list.isEmpty) {
                                                  list.add(const Currency(code: 'usd', name: 'US Dollar', symbol: '\$', symbolNative: '\$'));
                                                }

                                                // Safely set/update selectedCurrency
                                                if (selectedCurrency == null || !list.any((c) => c.code == selectedCurrency!.code)) {
                                                  final store = storeState.mapOrNull(stores: (r) => r.response.stores.firstOrNull);
                                                  Currency? defaultCurrency;
                                                  if (store != null && store.supportedCurrencies != null) {
                                                    for (var sc in store.supportedCurrencies!) {
                                                      if (sc.isDefault) {
                                                        defaultCurrency = Currency(
                                                          code: sc.currencyCode,
                                                          name: sc.currency?.name ?? sc.currencyCode.toUpperCase(),
                                                          symbol: sc.currency?.symbol ?? sc.currencyCode,
                                                          symbolNative: sc.currency?.symbolNative ?? sc.currency?.symbol ?? '',
                                                        );
                                                        break;
                                                      }
                                                    }
                                                  }
                                                  selectedCurrency = defaultCurrency ?? list.first;
                                                }

                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: context.isDark ? Colors.white24 : Colors.grey.shade300),
                                                    borderRadius: BorderRadius.circular(12),
                                                    color: context.isDark ? const Color(0xFF131A0B) : Colors.grey.shade50,
                                                  ),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<Currency>(
                                                      value: selectedCurrency,
                                                      isExpanded: true,
                                                      dropdownColor: context.theme.scaffoldBackgroundColor,
                                                      onChanged: (Currency? val) {
                                                        if (val != null) {
                                                          setState(() => selectedCurrency = val);
                                                        }
                                                      },
                                                      items: list.map((c) {
                                                        return DropdownMenuItem<Currency>(
                                                          value: c,
                                                          child: Text(c.code?.toUpperCase() ?? ''),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(16),
                                  LabeledTextField(
                                    label: 'Inventory Stock Level',
                                    hintText: 'e.g. 50',
                                    controller: simpleStockCtrl,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                                        return 'Must be an integer';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          space,

                          // 3. Product Photos Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: context.isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            ),
                            color: context.isDark ? const Color(0xFF181F10) : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product Photos',
                                    style: GoogleFonts.comfortaa(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.isDark ? const Color(0xFFF0EAD6) : const Color(0xFF1A1400),
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    'Upload photos of your product. The first photo will be used as the main thumbnail.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ColorManager.manatee,
                                    ),
                                  ),
                                  const Gap(16),
                                  if (images.isNotEmpty) ...[
                                    SizedBox(
                                      height: 120,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: images.length + 1,
                                        separatorBuilder: (_, __) => const Gap(10),
                                        itemBuilder: (context, index) {
                                          if (index == images.length) {
                                            return GestureDetector(
                                              onTap: () => _pickGalleryImages(),
                                              child: Container(
                                                width: 100,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: const Color(0xFF344F16).withOpacity(0.5),
                                                    width: 1.5,
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF344F16), size: 28),
                                                ),
                                              ),
                                            );
                                          }
                                          
                                          final file = images[index];
                                          final isThumbnail = index == 0;
                                          return Stack(
                                            children: [
                                              Container(
                                                width: 100,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  image: DecorationImage(
                                                    image: FileImage(file),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              if (isThumbnail)
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF344F16),
                                                      borderRadius: BorderRadius.only(
                                                        bottomLeft: Radius.circular(12),
                                                        bottomRight: Radius.circular(12),
                                                      ),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      'Thumbnail',
                                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      images.removeAt(index);
                                                      if (isThumbnail) {
                                                        thumbnailImage = images.isNotEmpty ? images.first : null;
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ] else ...[
                                    GestureDetector(
                                      onTap: () => _pickGalleryImages(),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 32),
                                        decoration: BoxDecoration(
                                          color: context.isDark ? const Color(0xFF131A0B) : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF344F16).withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF344F16)),
                                            const Gap(10),
                                            Text(
                                              'Tap to select images',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: context.isDark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            const Gap(4),
                                            Text(
                                              'PNG, JPG, JPEG supported',
                                              style: TextStyle(fontSize: 11, color: ColorManager.manatee),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // Advanced Mode (expansion tiles)
                          ProductGeneralInformation(
                              controller: generalTileCtrl,
                              product: product,
                              onSaved: (product) {
                                this.product = this.product?.copyWith(
                                      title: product.title,
                                      subtitle: product.subtitle,
                                      handle: product.handle,
                                      material: product.material,
                                      description: product.description,
                                      discountable: product.discountable,
                                      status: product.status,
                                    );
                              }),
                          space,
                          ProductOrganize(
                            controller: organizeTileCtrl,
                            updateMode: updateMode,
                            product: product,
                            onSaved: (product) {
                              this.product = this.product?.copyWith(
                                    collection: product.collection,
                                    tags: product.tags,
                                    type: product.type,
                                    salesChannels: product.salesChannels,
                                  );
                              setState(() {});
                            },
                          ),
                          space,
                          ProductVariants(
                            product: product,
                            controller: variantTileCtrl,
                            onSaved: (product) {
                              this.product = this.product?.copyWith(
                                    options: product.options,
                                    variants: product.variants,
                                  );
                            },
                          ),
                          space,
                          ProductAttributes(
                            controller: attributeTileCtrl,
                            product: product,
                            onSaved: (product) {
                              this.product = this.product?.copyWith(
                                    width: product?.width,
                                    length: product?.length,
                                    height: product?.height,
                                    weight: product?.weight,
                                    midCode: product?.midCode,
                                    hsCode: product?.hsCode,
                                    originCountry: product?.originCountry,
                                  );
                            },
                          ),
                          space,
                          ProductThumbnail(
                            controller: thumbnailTileCtrl,
                            updateMode: updateMode,
                            product: product,
                            thumbnail: thumbnailImage,
                            onChanged: (thumbnail) {
                              thumbnailImage = thumbnail;
                              if (thumbnail == null) {
                                product = product?.copyWith(thumbnail: null);
                              }
                              setState(() {});
                            },
                          ),
                          space,
                          ProductMedia(
                            controller: mediaTileCtrl,
                            product: product,
                            updateMode: updateMode,
                            onMediaChanged: (images) {
                              this.images = images;
                            },
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickGalleryImages() async {
    try {
      final picked = await ImagePickerHelper.instance.multipleImagePicker();
      if (picked.isNotEmpty) {
        setState(() {
          images.addAll(picked);
          if (thumbnailImage == null) {
            thumbnailImage = images.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void deleteTempImages() {
    if (kIsWeb) return;
    try {
      final imagesToDelete = List<File>.from(images);
      images.clear();
      if (imagesToDelete.isNotEmpty) {
        for (var file in imagesToDelete) {
          file.deleteSync();
        }
      }
      final thumbnailToDelete = thumbnailImage;
      thumbnailImage = null;
      if (thumbnailToDelete != null) {
        thumbnailToDelete.deleteSync();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<List<String>> _uploadFiles(List<File> filesToUpload) async {
    if (filesToUpload.isEmpty) return [];
    
    final formData = FormData();
    for (final file in filesToUpload) {
      if (kIsWeb) {
        final bytes = ImagePickerHelper.webBytesCache[file.path];
        if (bytes != null) {
          formData.files.add(MapEntry(
            'files',
            MultipartFile.fromBytes(
              bytes,
              filename: file.path.split('/').last,
            ),
          ));
        }
      } else {
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ));
      }
    }

    final result = await getIt<UploadUseCase>()(formData);
    return result.when(
      (uploadedFiles) => uploadedFiles.map((e) => e.url ?? '').where((url) => url.isNotEmpty).toList(),
      (error) {
        debugPrint('Upload error: $error');
        throw error;
      },
    );
  }

  Future<void> createProduct() async {
    EasyLoading.show(status: 'Creating product...');
    try {
      String? thumbnailUrl;
      if (thumbnailImage != null) {
        EasyLoading.show(status: 'Uploading thumbnail...');
        final uploaded = await _uploadFiles([thumbnailImage!]);
        if (uploaded.isNotEmpty) {
          thumbnailUrl = uploaded.first;
        }
      }

      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        EasyLoading.show(status: 'Uploading images...');
        imageUrls = await _uploadFiles(images);
      }

      EasyLoading.show(status: 'Creating product...');

      final List<CreateProductOptionReq> finalOptions;
      final List<CreateProductVariantReq> finalVariants;

      if (simpleMode) {
        final title = simpleTitleCtrl.text.trim();
        final description = simpleDescriptionCtrl.text.isEmpty ? null : simpleDescriptionCtrl.text.trim();
        final status = simpleStatus.name;

        // Pricing
        final priceText = simplePriceCtrl.text.trim();
        final priceDouble = double.tryParse(priceText) ?? 0.0;
        final currencyCode = selectedCurrency?.code ?? 'usd';
        final formatter = NumberFormat.simpleCurrency(name: currencyCode.toUpperCase());
        final priceAmount = (priceDouble * pow(10, formatter.decimalDigits ?? 2)).round();

        // Stock
        final stockText = simpleStockCtrl.text.trim();
        final stockInt = int.tryParse(stockText);

        finalOptions = [
          const CreateProductOptionReq(
            title: 'Size',
            values: ['Default Size'],
          )
        ];

        finalVariants = [
          CreateProductVariantReq(
            title: 'Default Variant',
            prices: [
              CreateProductVariantPriceReq(
                currencyCode: currencyCode,
                amount: priceAmount,
              )
            ],
            options: const {
              'Size': 'Default Size',
            },
            manageInventory: stockInt != null,
            metadata: stockInt != null ? {
              'inventory_quantity': stockInt,
            } : null,
          )
        ];

        productCrudBloc.add(ProductCrudEvent.create(CreateProductReq(
          title: title,
          description: description,
          status: status,
          thumbnail: thumbnailUrl,
          images: imageUrls,
          options: finalOptions,
          variants: finalVariants,
          discountable: true,
          isGiftcard: false,
        )));
      } else {
        // Advanced Mode
        if (product?.options == null || product!.options!.isEmpty) {
          finalOptions = [
            const CreateProductOptionReq(
              title: 'Size',
              values: ['Default Size'],
            )
          ];
        } else {
          finalOptions = product!.options!.map((e) => CreateProductOptionReq(
            title: e.title ?? '',
            values: e.values?.map((val) => val.value ?? '').toList() ?? [],
          )).toList();
        }

        if (product?.variants == null || product!.variants!.isEmpty) {
          finalVariants = [
            const CreateProductVariantReq(
              title: 'Default Variant',
              prices: [],
              options: {
                'Size': 'Default Size',
              },
            )
          ];
        } else {
          finalVariants = product!.variants!.map((e) => CreateProductVariantReq(
            title: e.title ?? '',
            sku: e.sku,
            barcode: e.barcode,
            ean: e.ean,
            upc: e.upc,
            prices: e.prices?.map((p) => CreateProductVariantPriceReq(
              currencyCode: p.currencyCode ?? '',
              amount: p.amount?.toInt() ?? 0,
            )).toList() ?? [],
            allowBackorder: e.allowBackorder,
            manageInventory: e.manageInventory,
            weight: e.weight?.toString(),
            height: e.height?.toString(),
            width: e.width?.toString(),
            length: e.length?.toString(),
            hsCode: e.hsCode?.toString(),
            originCountry: e.originCountry,
            midCode: e.midCode?.toString(),
            material: e.material,
            metadata: e.metadata,
          )).toList();
        }

        productCrudBloc.add(ProductCrudEvent.create(CreateProductReq(
          title: product?.title ?? '',
          subtitle: product?.subtitle,
          description: product?.description,
          handle: product?.handle,
          isGiftcard: product?.isGiftcard,
          discountable: product?.discountable,
          thumbnail: thumbnailUrl,
          status: product?.status?.name,
          images: imageUrls,
          options: finalOptions,
          variants: finalVariants,
          weight: product?.weight?.toString(),
          height: product?.height?.toString(),
          width: product?.width?.toString(),
          length: product?.length?.toString(),
          hsCode: product?.hsCode?.toString(),
          originCountry: product?.originCountry,
          midCode: product?.midCode?.toString(),
          material: product?.material,
        )));
      }
    } catch (e) {
      EasyLoading.dismiss();
      context.showSnackBar('Failed to upload files: $e');
    }
  }

  Future<void> updateProduct() async {
    EasyLoading.show(status: 'Updating product...');
    try {
      String? thumbnailUrl;
      if (thumbnailImage != null) {
        EasyLoading.show(status: 'Uploading thumbnail...');
        final uploaded = await _uploadFiles([thumbnailImage!]);
        if (uploaded.isNotEmpty) {
          thumbnailUrl = uploaded.first;
        }
      }

      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        EasyLoading.show(status: 'Uploading images...');
        imageUrls = await _uploadFiles(images);
      }

      EasyLoading.show(status: 'Updating product...');
      final originalProduct = widget.updateProductReq!.product;

      final List<String> finalImages = originalProduct.images?.map((e) => e.url ?? '').where((u) => u.isNotEmpty).toList() ?? [];
      finalImages.addAll(imageUrls);

      productCrudBloc.add(ProductCrudEvent.update(
        widget.updateProductReq!.product.id,
        UpdateProductReq(
          title: originalProduct.title == product!.title ? null : product!.title,
          subtitle: originalProduct.subtitle == product!.subtitle ? null : product!.subtitle,
          handle: originalProduct.handle == product!.handle ? null : product!.handle,
          material: originalProduct.material == product!.material ? null : product!.material,
          description: originalProduct.description == product!.description ? null : product!.description,
          discountable: product!.discountable,
          tags: product!.tags?.map((e) => {'id': e.id ?? '', 'value': e.value ?? ''}).toList(),
          typeId: product!.type?.id,
          salesChannels:
              product!.salesChannels?.map((e) => {'id': e.id ?? ''}).toList(),
          variants: product!.variants?.map((e) => {
            if (e.id != null) 'id': e.id,
            'title': e.title,
            'sku': e.sku,
            'barcode': e.barcode,
            'ean': e.ean,
            'upc': e.upc,
            'allow_backorder': e.allowBackorder,
            'manage_inventory': e.manageInventory,
            'weight': e.weight?.toString(),
            'height': e.height?.toString(),
            'width': e.width?.toString(),
            'length': e.length?.toString(),
            'hs_code': e.hsCode,
            'origin_country': e.originCountry,
            'mid_code': e.midCode,
            'material': e.material,
            'metadata': e.metadata,
            'prices': e.prices?.map((p) => {
              'currency_code': p.currencyCode,
              'amount': p.amount?.toInt(),
            }).toList(),
          }).toList(),
          width: originalProduct.width == product!.width ? null : product!.width?.toString(),
          length: originalProduct.length == product!.length ? null : product!.length?.toString(),
          height: originalProduct.height == product!.height ? null : product!.height?.toString(),
          weight: originalProduct.weight == product!.weight ? null : product!.weight?.toString(),
          midCode: originalProduct.midCode == product!.midCode ? null : product!.midCode,
          hsCode: originalProduct.hsCode == product!.hsCode ? null : originalProduct.hsCode,
          originCountry:
              originalProduct.originCountry == product!.originCountry ? null : product!.originCountry,
          thumbnail: thumbnailUrl ?? (originalProduct.thumbnail == product!.thumbnail ? null : product!.thumbnail),
          collectionId: originalProduct.collectionId == product!.collection?.id
              ? null
              : product!.collection?.id,
          images: finalImages,
          status: originalProduct.status == product!.status
              ? null
              : ProductStatus.values.firstWhere(
                  (e) => e.name == product!.status?.name,
                  orElse: () => ProductStatus.draft,
                ),
        ),
      ));
    } catch (e) {
      EasyLoading.dismiss();
      context.showSnackBar('Failed to upload files: $e');
    }
  }
}

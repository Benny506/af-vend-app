import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flex_expansion_tile/flex_expansion_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:medusa_admin/src/core/extensions/snack_bar_extension.dart';
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

  @override
  void initState() {
    productCrudBloc = ProductCrudBloc.instance;
    uploadImagesCubit = UploadFilesCubit.instance;
    uploadThumbnailCubit = UploadFilesCubit.instance;
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
                        generalTileCtrl.expand();
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

      final List<CreateProductVariantReq> finalVariants;
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

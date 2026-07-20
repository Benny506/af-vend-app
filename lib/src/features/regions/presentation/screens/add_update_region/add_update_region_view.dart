import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:medusa_admin/src/core/extensions/snack_bar_extension.dart';
import 'package:medusa_admin/src/core/extensions/string_extension.dart';
import 'package:medusa_admin/src/features/regions/presentation/bloc/region_crud/region_crud_bloc.dart';
import 'package:medusa_admin/src/core/utils/custom_text_field.dart';
import 'package:medusa_admin/src/core/utils/easy_loading.dart';
import 'package:medusa_admin/src/core/utils/hide_keyboard.dart';
import 'package:medusa_admin/src/features/regions/data/models/select_country_req.dart';
import 'package:medusa_admin/src/features/payment_providers/presentation/cubits/payment_providers/payment_providers_cubit.dart';
import 'package:medusa_admin/src/features/fulfillment_providers/presentation/bloc/fulfillment_providers_bloc.dart';
import 'package:medusa_admin/src/features/store_details/presentation/bloc/store/store_bloc.dart';
import 'package:medusa_admin/src/features/store_settings/presentation/widgets/countries/country_view.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flex_expansion_tile/flex_expansion_tile.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';

@RoutePage()
class AddUpdateRegionView extends StatefulWidget {
  const AddUpdateRegionView({super.key, this.region});
  final Region? region;

  @override
  State<AddUpdateRegionView> createState() => _AddUpdateRegionViewState();
}

class _AddUpdateRegionViewState extends State<AddUpdateRegionView> {
  bool get updateMode => region != null;
  Region? get region => widget.region;
  
  late RegionCrudBloc regionCrudBloc;
  late PaymentProvidersCubit paymentProvidersCubit;
  late FulfillmentProvidersBloc fulfillmentProvidersBloc;

  final titleCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  
  List<Country> selectedCountries = [];
  List<String> selectedPaymentProviders = [];
  List<String> selectedFulfillmentProviders = [];
  Currency? selectedCurrency;
  
  final providersExpansionKey = GlobalKey();
  List<Currency>? currencies;

  @override
  void initState() {
    regionCrudBloc = RegionCrudBloc.instance;
    paymentProvidersCubit = PaymentProvidersCubit.instance..fetchPaymentProviders();
    fulfillmentProvidersBloc = FulfillmentProvidersBloc.instance..add(const FulfillmentProvidersEvent.load());

    final supportedCurrencies = context.read<StoreBloc>().state.mapOrNull(store: (_) => _.store.supportedCurrencies);
    currencies = supportedCurrencies?.map((e) => e.currency).toList();

    if (updateMode) {
      titleCtrl.text = region!.name;
      selectedCountries = region!.countries ?? [];
      
      final payProvs = region!.metadata?['payment_providers'];
      if (payProvs is List) {
        selectedPaymentProviders = payProvs
            .map((e) => e is Map ? (e['id']?.toString() ?? '') : e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        selectedPaymentProviders = [];
      }
      
      final fulProvs = region!.metadata?['fulfillment_providers'];
      if (fulProvs is List) {
        selectedFulfillmentProviders = fulProvs
            .map((e) => e is Map ? (e['id']?.toString() ?? '') : e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        selectedFulfillmentProviders = [];
      }

      selectedCurrency = currencies
          ?.where((element) => element.code == region?.currencyCode)
          .firstOrNull;
    }
    super.initState();
  }

  @override
  void dispose() {
    regionCrudBloc.close();
    paymentProvidersCubit.close();
    fulfillmentProvidersBloc.close();
    titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color manatee = ColorManager.manatee;
    final smallTextStyle = context.bodySmall;
    final mediumTextStyle = context.bodyMedium;
    const space = Gap(12);
    const halfSpace = Gap(6);
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      borderSide: BorderSide(color: Colors.grey),
    );
    return BlocListener<RegionCrudBloc, RegionCrudState>(
      bloc: regionCrudBloc,
      listener: (context, state) {
        state.maybeWhen(
          loading: () => loading(),
          error: (error) {
            dismissLoading();
            context.showSnackBar(error.toSnackBarString());
          },
          region: (_) {
            dismissLoading();
            context.showSnackBar(updateMode ? 'Region updated' : 'Region added');
            context.maybePop(true);
          },
          orElse: () => dismissLoading(),
        );
      },
      child: HideKeyboard(
        child: Scaffold(
          appBar: AppBar(
            title: updateMode ? const Text('Update Region') : const Text('Add Region'),
            actions: [
              TextButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    if (selectedCurrency == null) {
                      context.showSnackBar('Please choose a currency');
                      return;
                    }
                    context.unfocus();
                    var countriesIso = selectedCountries.map((c) => c.iso2).toList();

                    if (updateMode) {
                      regionCrudBloc.add(RegionCrudEvent.update(
                        region!.id,
                        UpdateRegionReq(
                          name: titleCtrl.text,
                          currencyCode: selectedCurrency!.code,
                          countries: countriesIso,
                          paymentProviders: selectedPaymentProviders,
                          metadata: {
                            'fulfillment_providers': selectedFulfillmentProviders,
                          },
                        ),
                      ));
                    } else {
                      regionCrudBloc.add(RegionCrudEvent.create(
                        CreateRegionReq(
                          name: titleCtrl.text,
                          currencyCode: selectedCurrency!.code!,
                          paymentProviders: selectedPaymentProviders,
                          countries: countriesIso,
                          metadata: {
                            'fulfillment_providers': selectedFulfillmentProviders,
                          },
                        ),
                      ));
                    }
                  },
                  child: updateMode ? const Text('Update') : const Text('Create'))
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    FlexExpansionTile(
                      title: const Text('Details'),
                      initiallyExpanded: true,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text('Add the region details.',
                                      style: smallTextStyle!.copyWith(color: manatee))),
                            ],
                          ),
                          space,
                          LabeledTextField(
                            label: 'Title',
                            controller: titleCtrl,
                            required: true,
                            hintText: 'Europe',
                            validator: (val) {
                              if (val == null || val.removeAllWhitespace.isEmpty) {
                                return 'Field required';
                              }
                              return null;
                            },
                          ),
                          Row(
                            children: [
                              Text('Currency', style: mediumTextStyle),
                              Text('*', style: mediumTextStyle!.copyWith(color: Colors.red)),
                            ],
                          ),
                          halfSpace,
                          DropdownButtonFormField<Currency>(
                            style: context.bodyMedium,
                            validator: (val) {
                              if (val == null) {
                                return 'Field is required';
                              }
                              return null;
                            },
                            items: currencies
                                ?.map((e) => DropdownMenuItem(
                                    value: e, child: Text(e.name ?? '')))
                                .toList(),
                            hint: const Text('Choose currency'),
                            value: selectedCurrency,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedCurrency = value;
                                });
                              }
                            },
                            decoration: InputDecoration(
                                enabledBorder: border,
                                isDense: true,
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                border: border,
                                errorBorder: border),
                          ),
                          space,
                          LabeledTextField(
                            label: 'Countries',
                            controller: null,
                            readOnly: true,
                            required: true,
                            validator: (val) {
                              if (selectedCountries.isEmpty) {
                                return 'Select at least one country';
                              }
                              return null;
                            },
                            onTap: () async {
                              final result = await showBarModalBottomSheet(
                                  context: context,
                                  overlayStyle: context.theme.appBarTheme.systemOverlayStyle,
                                  backgroundColor: context.theme.scaffoldBackgroundColor,
                                  builder: (context) => SelectCountryView(
                                          selectCountryReq: SelectCountryReq(
                                        disabledCountriesIso2: [],
                                        multipleSelect: true,
                                        selectedCountries: [...selectedCountries],
                                      )));
                              if (result is List<Country>) {
                                setState(() {
                                  selectedCountries = result;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).scaffoldBackgroundColor,
                              hintText: selectedCountries.isNotEmpty
                                  ? 'Countries'
                                  : 'Choose countries',
                              suffixIcon: selectedCountries.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedCountries.clear();
                                        });
                                      },
                                      icon: const Icon(CupertinoIcons.clear_circled_solid))
                                  : const Icon(Icons.arrow_drop_down_outlined),
                              prefixIconConstraints: const BoxConstraints(minWidth: 48 * 1.5),
                              prefixIcon: selectedCountries.isNotEmpty
                                  ? Chip(
                                      label: Text(selectedCountries.length.toString()),
                                      labelStyle: smallTextStyle,
                                      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                                      side: const BorderSide(color: Colors.transparent),
                                    )
                                  : null,
                              enabledBorder: border,
                              border: border,
                            ),
                          ),
                          space,
                        ],
                      ),
                    ),
                    space,
                    FlexExpansionTile(
                      key: providersExpansionKey,
                      title: const Text('Providers'),
                      initiallyExpanded: true,
                      onExpansionChanged: (expanded) async {
                        if (expanded) {
                          await providersExpansionKey.currentContext.ensureVisibility();
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      'Add which fulfillment and payment providers should be available in this region.',
                                      style: smallTextStyle.copyWith(color: manatee))),
                            ],
                          ),
                          space,
                          Row(
                            children: [
                              Text('Payment Providers', style: mediumTextStyle),
                              Text('*', style: mediumTextStyle.copyWith(color: Colors.red)),
                            ],
                          ),
                          halfSpace,
                          BlocBuilder<PaymentProvidersCubit, PaymentProvidersState>(
                            bloc: paymentProvidersCubit,
                            builder: (context, state) {
                              return state.maybeWhen(
                                loading: () => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator.adaptive(),
                                  ),
                                ),
                                paymentProviders: (providers) {
                                  if (providers.isEmpty) {
                                    return const Text('No payment providers available');
                                  }
                                  return Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: providers.map((provider) {
                                      final isSelected = selectedPaymentProviders.contains(provider.id);
                                      return FilterChip(
                                        label: Text(provider.id?.toUpperCase() ?? ''),
                                        selected: isSelected,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            if (selected) {
                                              selectedPaymentProviders.add(provider.id!);
                                            } else {
                                              selectedPaymentProviders.remove(provider.id!);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                                error: (failure) => Text(failure.message ?? ''),
                                orElse: () => const SizedBox.shrink(),
                              );
                            },
                          ),
                          space,
                          Row(
                            children: [
                              Text('Fulfillment Providers', style: mediumTextStyle),
                              Text('*', style: mediumTextStyle.copyWith(color: Colors.red)),
                            ],
                          ),
                          halfSpace,
                          BlocBuilder<FulfillmentProvidersBloc, FulfillmentProvidersState>(
                            bloc: fulfillmentProvidersBloc,
                            builder: (context, state) {
                              return state.maybeWhen(
                                loading: () => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator.adaptive(),
                                  ),
                                ),
                                fulfillmentProviders: (response) {
                                  final providers = response.fulfillmentProviders ?? [];
                                  if (providers.isEmpty) {
                                    return const Text('No fulfillment providers available');
                                  }
                                  return Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: providers.map((provider) {
                                      final isSelected = selectedFulfillmentProviders.contains(provider.id);
                                      return FilterChip(
                                        label: Text(provider.id?.toUpperCase() ?? ''),
                                        selected: isSelected,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            if (selected) {
                                              selectedFulfillmentProviders.add(provider.id!);
                                            } else {
                                              selectedFulfillmentProviders.remove(provider.id!);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                                error: (failure) => Text(failure.message ?? ''),
                                orElse: () => const SizedBox.shrink(),
                              );
                            },
                          ),
                          space,
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
    );
  }
}

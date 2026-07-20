import 'dart:io';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flex_expansion_tile/flex_expansion_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:flag/flag.dart';

import 'package:info_popup/info_popup.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/extensions/snack_bar_extension.dart';
import 'package:medusa_admin/src/core/extensions/string_extension.dart';
import 'package:medusa_admin/src/core/utils/easy_loading.dart';
import 'package:medusa_admin/src/features/currencies/presentation/cubits/currencies/currencies_cubit.dart';
import 'package:medusa_admin/src/features/regions/data/models/select_country_req.dart';
import 'package:medusa_admin/src/features/regions/presentation/bloc/region_crud/region_crud_bloc.dart';

import 'package:medusa_admin/src/core/utils/medusa_sliver_app_bar.dart';
import 'package:medusa_admin/src/features/store_details/presentation/screens/store_details/store_details_fab.dart';
import 'package:medusa_admin/src/features/store_settings/presentation/widgets/countries/components/countries.dart';
import 'package:medusa_admin/src/features/store_settings/presentation/widgets/countries/country_view.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_admin/src/core/routing/app_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'components/index.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';

@RoutePage()
class RegionDetailsView extends StatefulWidget {
  const RegionDetailsView(this.regionId, {super.key});

  final String regionId;

  @override
  State<RegionDetailsView> createState() => _RegionDetailsViewState();
}

class _RegionDetailsViewState extends State<RegionDetailsView> {
  late RegionCrudBloc regionCrudBloc;
  late RegionCrudBloc regionUpdateBloc;

  // late final PricePreferencesBloc pricePreferencesBloc;
  List<Country> selectedCountries = [];

  @override
  void initState() {
    regionCrudBloc = RegionCrudBloc.instance;
    regionUpdateBloc = RegionCrudBloc.instance;
    regionCrudBloc.add(RegionCrudEvent.load(widget.regionId));
    super.initState();
  }

  @override
  void dispose() {
    regionCrudBloc.close();
    regionUpdateBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const manatee = ColorManager.manatee;
    final smallTextStyle = context.bodySmall;
    final mediumTextStyle = context.bodyMedium;
    final largeTextStyle = context.bodyLarge;
    const space = Gap(12);
    const halfSpace = Gap(6);
    return BlocConsumer<RegionCrudBloc, RegionCrudState>(
      bloc: regionCrudBloc,
      listener: (context, state) {
        state.mapOrNull(
          deleted: (_) {
            context.showSnackBar('Region deleted');
            context.maybePop();
          },
        );
      },
      builder: (context, state) {
        final regionName = state.maybeWhen(region: (region) => region.name, orElse: () => 'Region');
        final region = state.mapOrNull(region: (region) => region.region);
        return BlocListener<RegionCrudBloc, RegionCrudState>(
          bloc: regionUpdateBloc,
          listener: (context, state) {
            state.whenOrNull(
              loading: () {
                loading();
              },
              error: (message) {
                context.showSnackBar(message.toSnackBarString());
                dismissLoading();
              },
              region: (region) {
                dismissLoading();
                regionCrudBloc.add(RegionCrudEvent.load(region.id));
                context.showSnackBar('Region updated');
                selectedCountries.clear();
                setState(() {});
              },
            );
          },
          child: Scaffold(
            floatingActionButton: selectedCountries.isNotEmpty
                ? StoreDetailsFab(
                    currenciesCount: selectedCountries.length,
                    onClear: () {
                      selectedCountries.clear();
                      setState(() {});
                    },
                    onRemove: () async {
                      if (region == null) {
                        return;
                      }
                      final should = await shouldRemove(selectedCountries.length);
                      if (!should) {
                        return;
                      }
                      final newCountries = region.countries!
                          .where((element) => !selectedCountries.contains(element))
                          .toList();
                      regionUpdateBloc.add(
                        RegionCrudEvent.update(
                          region.id,
                          UpdateRegionReq(
                            countries: newCountries.map((e) => e.iso2).toList(),
                          ),
                        ),
                      );
                    },
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                MedusaSliverAppBar(
                  title: Text(regionName),
                  actions: [
                    IconButton(
                        icon: const Icon(Icons.more_horiz_outlined),
                        onPressed: () async {
                          if (region == null) {
                            return;
                          }
                          await showModalActionSheet<int>(
                              title: 'Manage $regionName region',
                              context: context,
                              actions: <SheetAction<int>>[
                                const SheetAction(label: 'Edit', key: 0),
                                const SheetAction(
                                    label: 'Delete', isDestructiveAction: true, key: 1),
                              ]).then((result) async {
                            switch (result) {
                              case 0:
                                if (!context.mounted) return;
                                context.pushRoute(AddUpdateRegionRoute(region: region));
                                break;
                              case 1:
                                if (!context.mounted) return;
                                await showTextAnswerDialog(
                                  keyword: region.name,
                                  hintText: region.name,
                                  context: context,
                                  title: 'Delete region?',
                                  message:
                                      'Are you sure you want to delete this region?\n Type the name "${region.name}" to confirm ',
                                  okLabel: 'Yes, confirm',
                                  retryTitle: 'Wrong name',
                                  retryMessage:
                                      'Make sure to type the region name "${region.name}" to confirm deletion',
                                  isDestructiveAction: true,
                                ).then((value) async {
                                  if (value) {
                                    regionCrudBloc.add(RegionCrudEvent.delete(widget.regionId));
                                  }
                                });
                                break;
                            }
                          });
                        })
                  ],
                ),
              ],
              body: state.maybeWhen(
                region: (region) {
                  return ListView(
                    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    children: [
                      const SizedBox(height: 6.0),
                      FlexExpansionTile(
                        initiallyExpanded: true,
                        trailing: TextButton.icon(
                            onPressed: () {
                              context.pushRoute(AddUpdateRegionRoute(region: region));
                            },
                            icon: const Icon(LucideIcons.squarePen, size: 16),
                            label: const Text('Edit')),
                        title: const Text('Region Overview'),
                        childPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.5,
                          children: [
                            OverviewGridTile(
                              title: 'Currency',
                              value: region.currencyCode?.toUpperCase() ?? '-',
                              icon: Icons.payments_outlined,
                              iconColor: Colors.blue.shade600,
                            ),
                            OverviewGridTile(
                              title: 'Automatic Taxes',
                              value: region.automaticTaxes == true ? 'Enabled' : 'Disabled',
                              icon: Icons.percent_outlined,
                              iconColor: Colors.purple.shade600,
                            ),
                            OverviewGridTile(
                              title: 'Default Tax Rate',
                              value: getTaxRateText(region),
                              icon: Icons.receipt_long_outlined,
                              iconColor: Colors.teal.shade600,
                            ),
                            OverviewGridTile(
                              title: 'Payment Providers',
                              value: getPaymentProviders(region),
                              icon: Icons.credit_card_outlined,
                              iconColor: Colors.indigo.shade600,
                            ),
                          ],
                        ),
                      ),
                      space,
                      if (region.countries != null && region.countries!.isNotEmpty)
                        FlexExpansionTile(
                          initiallyExpanded: true,
                          title: const Text('Countries'),
                          trailing: TextButton.icon(
                              onPressed: () async {
                                final result = await showBarModalBottomSheet<List<Country>?>(
                                    context: context,
                                    overlayStyle: context.theme.appBarTheme.systemOverlayStyle,
                                    backgroundColor: context.theme.scaffoldBackgroundColor,
                                    builder: (context) => SelectCountryView(
                                            selectCountryReq: SelectCountryReq(
                                          disabledCountriesIso2:
                                              region.countries!.map((e) => e.iso2).toList(),
                                          multipleSelect: true,
                                          selectedCountries: [...selectedCountries],
                                        )));
                                if (result is List<Country>) {
                                  regionUpdateBloc.add(
                                    RegionCrudEvent.update(
                                        region.id,
                                        UpdateRegionReq(
                                          countries: [
                                            ...region.countries ?? <Country>[],
                                            ...result,
                                          ].map((e) => e.iso2).toList(),
                                        )),
                                  );
                                }
                              },
                              label: const Text('Add Countries'),
                              icon: const Icon(LucideIcons.plus, size: 16)),
                          childPadding:
                              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                          child: Column(
                            children: region.countries!.map((currency) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: InkWell(
                                  borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                                  onTap: () {
                                    final isSelected = selectedCountries.contains(currency);
                                    if (isSelected) {
                                      selectedCountries
                                          .removeWhere((element) => element.name == currency.name);
                                    } else {
                                      selectedCountries.add(currency);
                                    }
                                    setState(() {});
                                  },
                                  child: CheckboxListTile(
                                    tileColor: context.theme.scaffoldBackgroundColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    value: selectedCountries.contains(currency),
                                    onChanged: (bool? value) {
                                      if (value == null) return;
                                      if (!value) {
                                        selectedCountries.removeWhere(
                                            (element) => element.name == currency.name);
                                      } else {
                                        selectedCountries.add(currency);
                                      }
                                      setState(() {});
                                    },
                                    title: Row(
                                      children: [
                                        if (currency.iso2 != null) ...[
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(2.0),
                                            child: Flag.fromString(
                                              currency.iso2!.toUpperCase(),
                                              height: 12,
                                              width: 18,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 10.0),
                                        ],
                                        Expanded(
                                          child: Text(
                                            currency.name,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          currency.iso2.toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      space,
                      FlexExpansionTile(
                        initiallyExpanded: true,
                        title: const Text('Tax Rates & Rules'),
                        childPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Default Tax Rate'),
                              subtitle: const Text('Standard tax rate applied to products'),
                              trailing: Chip(
                                label: Text(getTaxRateText(region)),
                                backgroundColor: Colors.teal.shade100,
                                labelStyle: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (region.metadata?['tax_rates'] != null &&
                                (region.metadata?['tax_rates'] as List).isNotEmpty) ...[
                              const Divider(),
                              ...(region.metadata?['tax_rates'] as List).map((rateItem) {
                                if (rateItem is! Map) return const SizedBox.shrink();
                                final rateVal = rateItem['rate'] ?? 0;
                                final rateName = rateItem['name'] ?? 'Tax Rate';
                                final rateCode = rateItem['code'] ?? 'N/A';
                                return ListTile(
                                  title: Text(rateName),
                                  subtitle: Text('Code: $rateCode'),
                                  trailing: Chip(
                                    label: Text('$rateVal%'),
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                      space,
                      FlexExpansionTile(
                        initiallyExpanded: true,
                        title: const Text('Providers'),
                        childPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.payment_outlined, color: Colors.blue.shade600),
                              title: const Text('Payment Providers'),
                              subtitle: Text(
                                getPaymentProviders(region),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Icon(Icons.local_shipping_outlined, color: Colors.indigo.shade600),
                              title: const Text('Fulfillment Providers'),
                              subtitle: Text(
                                getFulfillmentProviders(region),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      space,
                      FlexExpansionTile(
                        initiallyExpanded: true,
                        title: const Text('Shipping Options'),
                        child: ShippingOptionsList(region),
                      ),
                      space,
                      FlexExpansionTile(
                        initiallyExpanded: true,
                        title: const Text('Return Shipping Options'),
                        child: ShippingOptionsList(region, isReturn: true),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
                error: (_) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error loading region', style: largeTextStyle),
                      TextButton(
                          onPressed: () =>
                              regionCrudBloc.add(RegionCrudEvent.load(widget.regionId)),
                          child: const Text('Retry'))
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> shouldRemove(int count) async => await showTextAnswerDialog(
        context: context,
        title: 'Are you sure?',
        message:
            'You are about to remove $count country from the region. This action cannot be undone.\nPlease type Remove to confirm:',
        okLabel: 'Remove',
        isDestructiveAction: true,
        keyword: 'Remove',
        retryMessage: 'Please type Remove to confirm',
        retryTitle: 'Wrong input',
      ).then((value) => value);

  String getCountriesText(Region region) {
    if (region.countries?.isEmpty ?? true) {
      return 'No countries configured';
    }
    if (region.countries!.length > 4) {
      String result = '';
      region.countries!.take(4).forEach((element) {
        if (result.isEmpty) {
          result = element.name;
        } else {
          result = '$result, ${element.name}';
        }
      });
      result = '$result +${region.countries!.length - 4}';
      return result;
    } else {
      String result = '';
      for (var element in region.countries!) {
        if (result.isEmpty) {
          result = element.name;
        } else {
          result = '$result, ${element.name}';
        }
      }
      return result;
    }
  }

  String getAllCountriesText(Region region) {
    if (region.countries?.isEmpty ?? true) {
      return 'No countries configured';
    }

    String result = '';
    for (var element in region.countries!) {
      if (result.isEmpty) {
        result = element.name;
      } else {
        result = '$result, ${element.name}';
      }
    }
    return result;
  }

  String getPaymentProviders(Region region) {
    final providers = region.metadata?['payment_providers'];
    if (providers is List && providers.isNotEmpty) {
      return providers
          .map((p) => p is Map ? (p['id'] ?? '') : p.toString())
          .join(', ')
          .toUpperCase();
    }
    return 'None';
  }

  String getFulfillmentProviders(Region region) {
    final providers = region.metadata?['fulfillment_providers'];
    if (providers is List && providers.isNotEmpty) {
      return providers
          .map((p) => p is Map ? (p['id'] ?? '') : p.toString())
          .join(', ')
          .toUpperCase();
    }
    return 'None';
  }

  String getTaxRateText(Region region) {
    final taxRate = region.metadata?['tax_rate'];
    if (taxRate != null) {
      return '$taxRate%';
    }
    return '0%';
  }
}

class OverviewGridTile extends StatelessWidget {
  const OverviewGridTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      fontSize: 14,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}


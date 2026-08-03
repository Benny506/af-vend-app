import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/di/di.dart';
import 'package:medusa_admin/src/core/extensions/medusa_model_extension.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';

@RoutePage()
class AddUpdatePickupRequestView extends StatefulWidget {
  const AddUpdatePickupRequestView({super.key, this.pickupRequest});
  final Map<String, dynamic>? pickupRequest;

  @override
  State<AddUpdatePickupRequestView> createState() => _AddUpdatePickupRequestViewState();
}

class _AddUpdatePickupRequestViewState extends State<AddUpdatePickupRequestView> {
  final supabase = Supabase.instance.client;
  final formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> logisticsOrgs = [];
  List<Map<String, dynamic>> regions = [];
  List<Order> availableOrders = [];

  String? selectedLogisticsOrgId;
  String? selectedRegionId;
  List<String> selectedOrderIds = [];

  bool isLoadingLogistics = true;
  bool isLoadingRegions = true;
  bool isLoadingOrders = false;
  bool isSaving = false;

  bool get isEdit => widget.pickupRequest != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final req = widget.pickupRequest!;
      selectedLogisticsOrgId = req['logistics_org_id']?.toString();
      selectedRegionId = req['region_id']?.toString();

      final rawOrderIds = req['order_ids'];
      if (rawOrderIds is List) {
        selectedOrderIds = rawOrderIds.map((e) => e.toString()).toList();
      } else if (rawOrderIds is String) {
        try {
          final decoded = jsonDecode(rawOrderIds);
          if (decoded is List) {
            selectedOrderIds = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }
    _fetchLogisticsOrgs();
    _fetchRegions();
  }

  Future<void> _fetchLogisticsOrgs() async {
    try {
      final response = await supabase.from('logistics_orgs').select('*');
      if (mounted) {
        setState(() {
          logisticsOrgs = List<Map<String, dynamic>>.from(response);
          isLoadingLogistics = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingLogistics = false);
    }
  }

  Future<void> _fetchRegions() async {
    try {
      final response = await supabase.from('region').select('*');
      if (mounted) {
        setState(() {
          regions = List<Map<String, dynamic>>.from(response);
          isLoadingRegions = false;
        });
        if (selectedRegionId != null) {
          _fetchOrdersForRegion(selectedRegionId!);
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingRegions = false);
    }
  }

  Future<void> _fetchOrdersForRegion(String regionId) async {
    setState(() {
      isLoadingOrders = true;
      if (!isEdit) {
        selectedOrderIds.clear();
      }
      availableOrders.clear();
    });

    try {
      final response = await getIt<MedusaAdminV2>().orders.list(
        queryParameters: {
          'region_id': regionId,
          'limit': 50,
        },
      );
      if (mounted) {
        setState(() {
          availableOrders = response.orders ?? [];
          isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingOrders = false);
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one order.')),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      final currentUser = supabase.auth.currentUser;
      final payload = {
        'logistics_org_id': selectedLogisticsOrgId,
        'region_id': selectedRegionId,
        'order_ids': selectedOrderIds,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isEdit) {
        await supabase
            .from('pickup_requests')
            .update(payload)
            .eq('id', widget.pickupRequest!['id']);
      } else {
        payload['status'] = 'pending';
        payload['confirm_payment'] = false;
        payload['vendor_id'] = currentUser?.id;
        payload['created_at'] = DateTime.now().toIso8601String();
        await supabase.from('pickup_requests').insert(payload);
      }

      if (mounted) {
        context.maybePop(true);
      }
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save pickup request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(isEdit ? 'Edit Pickup Request' : 'New Pickup Request'),
        actions: [
          TextButton.icon(
            onPressed: isSaving ? null : _save,
            icon: isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                : const Icon(Icons.check, color: Color(0xFFE48629)),
            label: Text(
              'Save',
              style: TextStyle(
                color: isSaving ? Colors.grey : const Color(0xFFE48629),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: formKey,
            child: ListView(
              children: [
                // Selection Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Organization & Region', style: context.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const Gap(12),

                        // Logistics selection
                        Text('Logistics Organization', style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const Gap(6),
                        isLoadingLogistics
                            ? const Center(child: CircularProgressIndicator.adaptive())
                            : DropdownButtonFormField<String>(
                                style: context.bodyMedium,
                                decoration: InputDecoration(
                                  enabledBorder: border,
                                  border: border,
                                  prefixIcon: const Icon(CupertinoIcons.building_2_fill),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                validator: (val) => val == null ? 'Field is required' : null,
                                hint: const Text('Select Logistics Organization'),
                                value: selectedLogisticsOrgId,
                                items: logisticsOrgs.map((org) {
                                  return DropdownMenuItem<String>(
                                    value: org['id']?.toString(),
                                    child: Text(org['name']?.toString() ?? 'Unknown'),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => selectedLogisticsOrgId = val),
                              ),
                        const Gap(16),

                        // Region selection
                        Text('Region', style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const Gap(6),
                        isLoadingRegions
                            ? const Center(child: CircularProgressIndicator.adaptive())
                            : DropdownButtonFormField<String>(
                                style: context.bodyMedium,
                                decoration: InputDecoration(
                                  enabledBorder: border,
                                  border: border,
                                  prefixIcon: const Icon(CupertinoIcons.globe),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                validator: (val) => val == null ? 'Field is required' : null,
                                hint: const Text('Select Region'),
                                value: selectedRegionId,
                                items: regions.map((reg) {
                                  return DropdownMenuItem<String>(
                                    value: reg['id']?.toString(),
                                    child: Text(reg['name']?.toString() ?? 'Unknown'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => selectedRegionId = val);
                                  if (val != null) _fetchOrdersForRegion(val);
                                },
                              ),
                      ],
                    ),
                  ),
                ),
                const Gap(16),

                // Order Picker Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Orders for Pickup (${selectedOrderIds.length})',
                              style: context.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (isLoadingOrders)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const Gap(12),
                        selectedRegionId == null
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text('Please select a region to view pending orders.', style: TextStyle(color: Colors.grey)),
                              )
                            : isLoadingOrders
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: CircularProgressIndicator.adaptive(),
                                    ),
                                  )
                                : availableOrders.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text('No orders found for this region.'),
                                      )
                                    : Column(
                                        children: availableOrders.map((order) {
                                          final isSelected = selectedOrderIds.contains(order.id);
                                          final customer = order.customerName;
                                          final total = order.total != null
                                              ? '${(order.total! / 100).toStringAsFixed(2)} ${order.currencyCode.toUpperCase()}'
                                              : 'N/A';

                                          return CheckboxListTile(
                                            value: isSelected,
                                            activeColor: const Color(0xFFE48629),
                                            title: Text('Order #${order.displayId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text('Customer: $customer\nTotal: $total'),
                                            onChanged: (checked) {
                                              setState(() {
                                                if (checked == true) {
                                                  selectedOrderIds.add(order.id);
                                                } else {
                                                  selectedOrderIds.remove(order.id);
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

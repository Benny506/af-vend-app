import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/routing/app_router.dart';
import 'package:medusa_admin/src/features/dashboard/presentation/widgets/drawer_widget.dart';

@RoutePage()
class DeliveriesView extends StatefulWidget {
  const DeliveriesView({super.key, this.isNested = false});
  final bool isNested;

  @override
  State<DeliveriesView> createState() => _DeliveriesViewState();
}

class _DeliveriesViewState extends State<DeliveriesView> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> deliveries = [];
  List<Map<String, dynamic>> filteredDeliveries = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        supabase.from('deliveries').select('*').order('created_at', ascending: false),
        supabase.from('region').select('id, name'),
      ]);

      final rawDeliveries = List<Map<String, dynamic>>.from(results[0]);
      final rawRegions = List<Map<String, dynamic>>.from(results[1]);

      final regionMap = {for (var r in rawRegions) r['id']?.toString(): r['name']?.toString()};

      for (var del in rawDeliveries) {
        final regId = del['region_id']?.toString();
        del['resolved_region_name'] = regionMap[regId] ?? 'N/A';
      }

      if (mounted) {
        setState(() {
          deliveries = rawDeliveries;
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading deliveries: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredDeliveries = deliveries.where((del) {
        final matchesStatus = selectedStatus == 'All' ||
            (del['status']?.toString().toLowerCase() == selectedStatus.toLowerCase());

        final driverName = del['driver_name']?.toString().toLowerCase() ?? '';
        final vehicleInfo = del['vehicle_info']?.toString().toLowerCase() ?? '';
        final regionName = (del['resolved_region_name'] ?? '')?.toString().toLowerCase() ?? '';
        final status = del['status']?.toString().toLowerCase() ?? '';

        final matchesSearch = searchQuery.isEmpty ||
            driverName.contains(searchQuery.toLowerCase()) ||
            vehicleInfo.contains(searchQuery.toLowerCase()) ||
            regionName.contains(searchQuery.toLowerCase()) ||
            status.contains(searchQuery.toLowerCase());

        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNested) {
      return _buildContent(context);
    }

    return Scaffold(
      drawer: null,
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDeliveries,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.pushRoute(AddUpdateDeliveryRoute());
          if (result == true) {
            _fetchDeliveries();
          }
        },
        backgroundColor: const Color(0xFFE48629),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final smallTextStyle = context.bodySmall;
    final mediumTextStyle = context.bodyMedium;
    final manatee = ColorManager.manatee;

    return Column(
      children: [
        // Search and Status Filters
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              CupertinoSearchTextField(
                style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
                placeholder: 'Search by driver, vehicle, region...',
                onChanged: (val) {
                  searchQuery = val;
                  _applyFilters();
                },
              ),
              const Gap(8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Pending', 'Ongoing', 'Completed'].map((status) {
                    final isSelected = selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedStatus = status;
                              _applyFilters();
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : filteredDeliveries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                          const Gap(16),
                          Text('No deliveries found', style: context.bodyLarge),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      itemCount: filteredDeliveries.length,
                      separatorBuilder: (context, index) => const Gap(10),
                      itemBuilder: (context, index) {
                        final delivery = filteredDeliveries[index];
                        final status = delivery['status']?.toString().toUpperCase() ?? 'PENDING';
                        final driverName = delivery['driver_name']?.toString() ?? 'No Driver assigned';
                        final regionName = delivery['resolved_region_name']?.toString() ?? 'N/A';
                        final deliveryMode = delivery['delivery_mode']?.toString() ?? 'N/A';
                        final routeCategory = delivery['route_category']?.toString().toUpperCase() ?? 'URBAN';
                        final rawOrderIds = delivery['order_ids'];
                        int orderCount = 0;
                        if (rawOrderIds is List) {
                          orderCount = rawOrderIds.length;
                        } else if (rawOrderIds is String) {
                          try {
                            final decoded = jsonDecode(rawOrderIds);
                            if (decoded is List) orderCount = decoded.length;
                          } catch (_) {}
                        }

                        DateTime? createdAt;
                        if (delivery['created_at'] != null) {
                          createdAt = DateTime.tryParse(delivery['created_at'].toString());
                        }
                        final dateString = createdAt != null
                            ? DateFormat.yMMMd().format(createdAt)
                            : 'N/A';

                        // Determine status badge colors
                        Color statusColor;
                        Color statusBgColor;
                        if (status == 'COMPLETED') {
                          statusColor = Colors.green;
                          statusBgColor = Colors.green.withValues(alpha: 0.12);
                        } else if (status == 'ONGOING') {
                          statusColor = Colors.blue;
                          statusBgColor = Colors.blue.withValues(alpha: 0.12);
                        } else {
                          statusColor = Colors.orange;
                          statusBgColor = Colors.orange.withValues(alpha: 0.12);
                        }

                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(
                              color: statusColor.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.0),
                            onTap: () async {
                              final result = await context.pushRoute(
                                DeliveriesDetailsRoute(deliveryId: delivery['id'].toString()),
                              );
                              if (result == true) {
                                _fetchDeliveries();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusBgColor,
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        dateString,
                                        style: smallTextStyle?.copyWith(color: manatee),
                                      ),
                                    ],
                                  ),
                                  const Gap(12),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        driverName,
                                        style: context.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Gap(8),
                                  Row(
                                    children: [
                                      const Icon(CupertinoIcons.location, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(regionName, style: mediumTextStyle?.copyWith(color: manatee)),
                                      const Spacer(),
                                      const Icon(CupertinoIcons.shopping_cart, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('$orderCount Order(s)', style: mediumTextStyle?.copyWith(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const Divider(height: 24, thickness: 0.8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Mode: $deliveryMode  •  Route: $routeCategory',
                                        style: smallTextStyle?.copyWith(color: manatee),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: manatee.withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

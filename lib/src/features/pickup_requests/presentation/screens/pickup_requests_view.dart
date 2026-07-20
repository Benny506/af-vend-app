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
class PickupRequestsView extends StatefulWidget {
  const PickupRequestsView({super.key});

  @override
  State<PickupRequestsView> createState() => _PickupRequestsViewState();
}

class _PickupRequestsViewState extends State<PickupRequestsView> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pickupRequests = [];
  List<Map<String, dynamic>> filteredRequests = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchPickupRequests();
  }

  Future<void> _fetchPickupRequests() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        supabase.from('pickup_requests').select('*').order('created_at', ascending: false),
        supabase.from('region').select('id, name'),
        supabase.from('logistics_orgs').select('id, name'),
      ]);

      final rawRequests = List<Map<String, dynamic>>.from(results[0]);
      final rawRegions = List<Map<String, dynamic>>.from(results[1]);
      final rawLogistics = List<Map<String, dynamic>>.from(results[2]);

      final regionMap = {for (var r in rawRegions) r['id']?.toString(): r['name']?.toString()};
      final logisticsMap = {for (var l in rawLogistics) l['id']?.toString(): l['name']?.toString()};

      for (var req in rawRequests) {
        final regId = req['region_id']?.toString();
        final logId = req['logistics_org_id']?.toString();
        req['resolved_region_name'] = regionMap[regId] ?? 'Unknown Region';
        req['resolved_logistics_name'] = logisticsMap[logId] ?? 'Unknown Logistics';
      }

      if (mounted) {
        setState(() {
          pickupRequests = rawRequests;
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pickup requests: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredRequests = pickupRequests.where((req) {
        final matchesStatus = selectedStatus == 'All' ||
            (req['status']?.toString().toLowerCase() == selectedStatus.toLowerCase());

        final logisticsName = (req['resolved_logistics_name'] ?? '')?.toString().toLowerCase() ?? '';
        final regionName = (req['resolved_region_name'] ?? '')?.toString().toLowerCase() ?? '';
        final status = req['status']?.toString().toLowerCase() ?? '';
        
        final matchesSearch = searchQuery.isEmpty ||
            logisticsName.contains(searchQuery.toLowerCase()) ||
            regionName.contains(searchQuery.toLowerCase()) ||
            status.contains(searchQuery.toLowerCase());

        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final smallTextStyle = context.bodySmall;
    final mediumTextStyle = context.bodyMedium;
    final manatee = ColorManager.manatee;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Pickup Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPickupRequests,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.pushRoute(AddUpdatePickupRequestRoute());
          if (result == true) {
            _fetchPickupRequests();
          }
        },
        backgroundColor: const Color(0xFFE48629),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Status Filters
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  CupertinoSearchTextField(
                    style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
                    placeholder: 'Search by logistics, region...',
                    onChanged: (val) {
                      searchQuery = val;
                      _applyFilters();
                    },
                  ),
                  const Gap(8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Pending', 'Processed', 'Packaged'].map((status) {
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
                  : filteredRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.cube_box, size: 64, color: Colors.grey),
                              const Gap(16),
                              Text('No pickup requests found', style: context.bodyLarge),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          itemCount: filteredRequests.length,
                          separatorBuilder: (context, index) => const Gap(10),
                          itemBuilder: (context, index) {
                            final request = filteredRequests[index];
                            final status = request['status']?.toString().toUpperCase() ?? 'PENDING';
                            final regionName = request['resolved_region_name']?.toString() ?? 'Unknown Region';
                            final logisticsName = request['resolved_logistics_name']?.toString() ?? 'Unknown Logistics';
                            final rawOrderIds = request['order_ids'];
                            int orderCount = 0;
                            if (rawOrderIds is List) {
                              orderCount = rawOrderIds.length;
                            } else if (rawOrderIds is String) {
                              try {
                                final decoded = jsonDecode(rawOrderIds);
                                if (decoded is List) orderCount = decoded.length;
                              } catch (_) {}
                            }
                            final confirmPayment = request['confirm_payment'] as bool? ?? false;
                            
                            DateTime? createdAt;
                            if (request['created_at'] != null) {
                              createdAt = DateTime.tryParse(request['created_at'].toString());
                            }
                            final dateString = createdAt != null
                                ? DateFormat.yMMMd().format(createdAt)
                                : 'N/A';

                            // Determine status badge colors
                            Color statusColor;
                            Color statusBgColor;
                            if (status == 'PACKAGED') {
                              statusColor = Colors.green;
                              statusBgColor = Colors.green.withValues(alpha: 0.12);
                            } else if (status == 'PROCESSED') {
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
                                    PickupRequestsDetailsRoute(requestId: request['id'] as String),
                                  );
                                  if (result == true) {
                                    _fetchPickupRequests();
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
                                      Text(
                                        logisticsName,
                                        style: context.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const Gap(6),
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
                                          Row(
                                            children: [
                                              Icon(
                                                confirmPayment
                                                    ? CupertinoIcons.check_mark_circled_solid
                                                    : CupertinoIcons.circle,
                                                size: 16,
                                                color: confirmPayment ? Colors.green : Colors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                confirmPayment ? 'Payment Confirmed' : 'Awaiting Payment Confirmation',
                                                style: smallTextStyle?.copyWith(
                                                  color: confirmPayment ? Colors.green : manatee,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
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
        ),
      ),
    );
  }
}

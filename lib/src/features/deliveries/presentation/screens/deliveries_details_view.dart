import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medusa_admin/src/core/constants/colors.dart';
import 'package:medusa_admin/src/core/extensions/text_style_extension.dart';
import 'package:medusa_admin/src/core/extensions/medusa_model_extension.dart';
import 'package:medusa_admin/src/core/routing/app_router.dart';
import 'package:medusa_admin/src/features/orders/domain/usecases/order/order_details_use_case.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';

@RoutePage()
class DeliveriesDetailsView extends StatefulWidget {
  const DeliveriesDetailsView({super.key, required this.deliveryId});
  final String deliveryId;

  @override
  State<DeliveriesDetailsView> createState() => _DeliveriesDetailsViewState();
}

class _DeliveriesDetailsViewState extends State<DeliveriesDetailsView> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? delivery;
  List<Order> orders = [];
  bool isLoading = true;
  bool isLoadingOrders = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryDetails();
  }

  Future<void> _fetchDeliveryDetails() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('deliveries')
          .select('*')
          .eq('id', widget.deliveryId)
          .single();

      final regId = response['region_id']?.toString();
      if (regId != null && regId.isNotEmpty) {
        try {
          final regRes = await supabase.from('region').select('name').eq('id', regId).maybeSingle();
          if (regRes != null) {
            response['resolved_region_name'] = regRes['name']?.toString() ?? 'N/A';
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          delivery = response;
          isLoading = false;
        });
        _fetchOrders();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingOrders = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load delivery details: $e')),
        );
      }
    }
  }

  List<String> _parseOrderIds(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  Future<void> _fetchOrders() async {
    final del = delivery;
    if (del == null) return;

    final orderIds = _parseOrderIds(del['order_ids']);
    if (orderIds.isEmpty) {
      setState(() => isLoadingOrders = false);
      return;
    }

    setState(() => isLoadingOrders = true);
    try {
      final fetchedOrders = <Order>[];
      for (final id in orderIds) {
        final result = await OrderCrudUseCase.instance.retrieveOrder(id: id);
        result.when(
          (order) => fetchedOrders.add(order),
          (error) => debugPrint('Error fetching order $id: $error'),
        );
      }
      if (mounted) {
        setState(() {
          orders = fetchedOrders;
          isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingOrders = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final del = delivery;
    if (del == null) return;

    setState(() => isUpdating = true);
    try {
      await supabase
          .from('deliveries')
          .update({'status': newStatus.toLowerCase()})
          .eq('id', del['id']);

      setState(() {
        del['status'] = newStatus.toLowerCase();
        isUpdating = false;
      });
    } catch (e) {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _deleteDelivery() async {
    final del = delivery;
    if (del == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Delivery'),
        content: const Text('Are you sure you want to delete this delivery?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isUpdating = true);
      try {
        await supabase.from('deliveries').delete().eq('id', del['id']);
        if (mounted) {
          context.maybePop(true);
        }
      } catch (e) {
        setState(() => isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete delivery: $e')),
        );
      }
    }
  }

  void _callDriver(String phone) async {
    if (phone.isEmpty || phone == 'N/A') return;
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildProcessTimeline(String currentStatus) {
    final steps = ['PENDING', 'ONGOING', 'COMPLETED'];
    final normalized = currentStatus.toUpperCase();
    int currentStepIndex = steps.indexOf(normalized);
    if (currentStepIndex < 0) currentStepIndex = 0;

    return Card(
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
              children: [
                const Icon(CupertinoIcons.square_stack_3d_up, size: 20, color: Color(0xFFE48629)),
                const Gap(8),
                Text(
                  'Delivery Process Timeline',
                  style: context.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: List.generate(steps.length, (index) {
                final isPassed = index <= currentStepIndex;
                final isCurrent = index == currentStepIndex;
                final stepTitle = steps[index];

                Color stepColor;
                if (isCurrent) {
                  stepColor = const Color(0xFFE48629);
                } else if (isPassed) {
                  stepColor = Colors.green;
                } else {
                  stepColor = Colors.grey.shade400;
                }

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: stepColor.withValues(alpha: 0.15),
                                border: Border.all(color: stepColor, width: 2),
                              ),
                              child: Center(
                                child: isPassed && !isCurrent
                                    ? Icon(Icons.check, size: 16, color: stepColor)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: stepColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const Gap(6),
                            Text(
                              stepTitle,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? stepColor : ColorManager.manatee,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < currentStepIndex ? Colors.green : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || delivery == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Details')),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final del = delivery!;
    final manatee = ColorManager.manatee;
    final smallTextStyle = context.bodySmall;
    final status = del['status']?.toString().toUpperCase() ?? 'PENDING';
    final regionName = del['resolved_region_name']?.toString() ?? 'N/A';
    final driverName = del['driver_name']?.toString() ?? 'N/A';
    final driverPhone = del['driver_phone']?.toString() ?? 'N/A';
    final vehicleInfo = del['vehicle_info']?.toString() ?? 'N/A';
    final deliveryMode = del['delivery_mode']?.toString() ?? 'Standard';
    final routeCategory = del['route_category']?.toString().toUpperCase() ?? 'URBAN';

    DateTime? createdAt;
    if (del['created_at'] != null) {
      createdAt = DateTime.tryParse(del['created_at'].toString());
    }
    final dateString = createdAt != null ? DateFormat.yMMMd().add_jm().format(createdAt) : 'N/A';

    Color statusColor;
    if (status == 'COMPLETED') {
      statusColor = Colors.green;
    } else if (status == 'ONGOING') {
      statusColor = Colors.blue;
    } else {
      statusColor = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Details'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil_circle, color: Color(0xFFE48629)),
            tooltip: 'Edit Delivery',
            onPressed: () async {
              final updated = await context.pushRoute(
                AddUpdateDeliveryRoute(delivery: del),
              );
              if (updated == true) {
                _fetchDeliveryDetails();
              }
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.trash, color: Colors.red),
            tooltip: 'Delete Delivery',
            onPressed: _deleteDelivery,
          ),
        ],
      ),
      body: SafeArea(
        child: isUpdating
            ? const Center(child: CircularProgressIndicator.adaptive())
            : RefreshIndicator(
                onRefresh: _fetchDeliveryDetails,
                child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  children: [
                    // Status & Action Header Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Delivery Status', style: smallTextStyle?.copyWith(color: manatee)),
                                    const Gap(4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        status,
                                        style: context.bodyMedium?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                DropdownButtonHideUnderline(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                    ),
                                    child: DropdownButton<String>(
                                      value: status == 'PENDING'
                                          ? 'Pending'
                                          : status == 'ONGOING'
                                              ? 'Ongoing'
                                              : 'Completed',
                                      onChanged: (val) {
                                        if (val != null) _updateStatus(val);
                                      },
                                      items: ['Pending', 'Ongoing', 'Completed']
                                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(12),

                    // Process Timeline
                    _buildProcessTimeline(status),
                    const Gap(12),

                    // Driver Details Card
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
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0x22E48629),
                                  child: Icon(CupertinoIcons.person_fill, color: Color(0xFFE48629)),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Driver', style: smallTextStyle?.copyWith(color: manatee)),
                                      Text(driverName, style: context.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                if (driverPhone.isNotEmpty && driverPhone != 'N/A')
                                  IconButton.filledTonal(
                                    icon: const Icon(CupertinoIcons.phone_fill, color: Colors.green),
                                    onPressed: () => _callDriver(driverPhone),
                                  ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Vehicle Info', style: smallTextStyle?.copyWith(color: manatee)),
                                      const Gap(2),
                                      Text(vehicleInfo, style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Phone', style: smallTextStyle?.copyWith(color: manatee)),
                                      const Gap(2),
                                      Text(driverPhone, style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Delivery Mode', style: smallTextStyle?.copyWith(color: manatee)),
                                      const Gap(4),
                                      Chip(
                                        label: Text(deliveryMode, style: const TextStyle(fontSize: 12)),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Route Category', style: smallTextStyle?.copyWith(color: manatee)),
                                      const Gap(4),
                                      Chip(
                                        label: Text(routeCategory, style: const TextStyle(fontSize: 12)),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Region', style: smallTextStyle?.copyWith(color: manatee)),
                                    const Gap(2),
                                    Text(regionName, style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Date Created', style: smallTextStyle?.copyWith(color: manatee)),
                                    const Gap(2),
                                    Text(dateString, style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(16),

                    // Associated orders
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Associated Orders (${orders.length})',
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
                    const Gap(8),
                    isLoadingOrders
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          )
                        : orders.isEmpty
                            ? Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Center(
                                    child: Text('No orders associated with this delivery.'),
                                  ),
                                ),
                              )
                            : Column(
                                children: orders.map((order) {
                                  final total = order.total != null
                                      ? '${(order.total! / 100).toStringAsFixed(2)} ${order.currencyCode.toUpperCase()}'
                                      : 'N/A';
                                  final customer = order.customerName;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                                    ),
                                    child: ListTile(
                                      onTap: () {
                                        context.pushRoute(OrderDetailsRoute(orderId: order.id));
                                      },
                                      leading: const CircleAvatar(
                                        backgroundColor: Color(0x15000000),
                                        child: Icon(Icons.local_shipping, color: Color(0xFFE48629)),
                                      ),
                                      title: Text('Order #${order.displayId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Customer: $customer\nPayment: ${order.paymentStatus?.name.toUpperCase()}'),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(total, style: context.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                          const Gap(4),
                                          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                  ],
                ),
              ),
      ),
    );
  }
}

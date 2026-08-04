import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:medusa_admin/src/core/extensions/context_extension.dart';
import 'package:medusa_admin/src/core/routing/app_router.dart';
import 'package:medusa_admin/src/features/orders/presentation/bloc/orders/orders_bloc.dart';
import 'package:medusa_admin/src/features/orders/presentation/bloc/orders_filter/orders_filter_bloc.dart';
import 'package:medusa_admin/src/features/products/presentation/cubits/products_filter/products_filter_cubit.dart';

@RoutePage()
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrdersBloc>(
          create: (_) => OrdersBloc.instance,
        ),
        BlocProvider<OrdersFilterBloc>(
          create: (_) => OrdersFilterBloc.instance,
        ),
        BlocProvider<ProductsFilterCubit>(
          create: (_) => ProductsFilterCubit.instance,
        ),
      ],
      child: AutoTabsRouter(
        homeIndex: 0,
        routes: const [
          DashboardOverviewRoute(),
          OrdersRoute(),
          ProductsRoute(),
          PickupRequestsDeliveriesRoute(),
        ],
        transitionBuilder: (context, child, animation) => child,
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
          
          Widget buildTabItem({
            required int index,
            required IconData icon,
            required String label,
          }) {
            final isSelected = tabsRouter.activeIndex == index;
            final color = isSelected ? const Color(0xFFE48629) : Colors.grey.shade500;
            
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => tabsRouter.setActiveIndex(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: context.systemUiOverlayNoAppBarStyle,
              child: child,
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                height: 64,
                decoration: BoxDecoration(
                  color: context.theme.bottomNavigationBarTheme.backgroundColor ?? 
                      (context.isDark ? const Color(0xFF131A0B) : Colors.white),
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  border: Border.all(
                    color: context.isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildTabItem(index: 0, icon: Icons.dashboard_outlined, label: 'Dashboard'),
                    buildTabItem(index: 1, icon: Icons.shopping_bag_outlined, label: 'Orders'),
                    
                    // Curved center FAB container with donut cutout
                    Container(
                      transform: Matrix4.translationValues(0, -12, 0),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4.0),
                      child: FloatingActionButton(
                        onPressed: () => _showQuickCreateBottomSheet(context),
                        backgroundColor: const Color(0xFF344F16),
                        elevation: 3,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.add, color: Colors.white, size: 24),
                      ),
                    ),

                    buildTabItem(index: 2, icon: Icons.sell_outlined, label: 'Products'),
                    buildTabItem(index: 3, icon: Icons.local_shipping_outlined, label: 'Logistics'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showQuickCreateBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Gap(20),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
                const Gap(16),
                _QuickActionTile(
                  title: 'Create Product',
                  subtitle: 'Add a new product to your catalog',
                  icon: Icons.add_photo_alternate_outlined,
                  color: const Color(0xFFE48629),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushRoute(AddUpdateProductRoute());
                  },
                ),
                const Gap(12),
                _QuickActionTile(
                  title: 'New Pickup Request',
                  subtitle: 'Request pickup for packaged items',
                  icon: CupertinoIcons.cube_box,
                  color: const Color(0xFF344F16),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushRoute(AddUpdatePickupRequestRoute());
                  },
                ),
                const Gap(12),
                _QuickActionTile(
                  title: 'New Delivery',
                  subtitle: 'Create a delivery run for a driver',
                  icon: Icons.local_shipping_outlined,
                  color: Colors.blue.shade600,
                  onTap: () {
                    Navigator.pop(context);
                    context.pushRoute(AddUpdateDeliveryRoute());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../inventory/data/models/inventory_item.dart';
import '../../../rentals/presentation/cubit/rental_cubit.dart';
import '../../../rentals/presentation/cubit/rental_state.dart';
import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_state.dart';
// Routes
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../rentals/presentation/screens/rentals_list_screen.dart';
import '../../../rentals/presentation/widgets/create_rental_bottom_sheet.dart';
import '../../../rentals/presentation/screens/revenue_report_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'المخزني',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'لإدارة المعدات والمقاولات',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('نظرة عامة على النشاط'),
                  const SizedBox(height: 16),
                  _buildStatsCards(context),
                  const SizedBox(height: 32),
                  _sectionTitle('الوصول السريع'),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF422712),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: BlocBuilder<RentalCubit, RentalState>(
                builder: (context, state) {
                  int activeCount = 0;
                  if (state is RentalLoaded) {
                    activeCount = state.rentals.where((r) => r.isActive).length;
                  }
                  return _StatCard(
                    title: 'تأجيرات نشطة',
                    value: activeCount.toString(),
                    subtitle: 'عمليات جارية الآن',
                    icon: Icons.sync,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RentalsListScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: BlocBuilder<InventoryCubit, InventoryState>(
                builder: (context, state) {
                  List<InventoryItem> items = [];
                  int outOfStockCount = 0;
                  if (state is InventoryLoaded) {
                    items = state.items;
                    outOfStockCount = items
                        .where((i) => i.availableQty == 0)
                        .length;
                  }

                  return _StatCard(
                    title: 'النواقص (الصفرية)',
                    value: outOfStockCount.toString(),
                    subtitle: 'أصناف غير متوفرة حالياً',
                    icon: Icons.error_outline_rounded,
                    color: outOfStockCount > 0 ? Colors.red : Colors.teal,
                    onTap: () {
                      if (items.any((i) => i.availableQty < i.totalQty)) {
                        _showLowStockDetails(context, items);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('جميع المعدات متوفرة في المخزن'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<RentalCubit, RentalState>(
          builder: (context, state) {
            double totalRevenue = 0;
            if (state is RentalLoaded) {
              totalRevenue = state.rentals
                  .where((r) => !r.isActive && r.endDate != null)
                  .fold(
                    0.0,
                    (sum, r) =>
                        sum + r.calculateTotalDue(r.endDate ?? DateTime.now()),
                  );
            }
            return _StatCard(
              title: 'إجمالي الإيرادات',
              value: '${totalRevenue.toStringAsFixed(0)} ج',
              subtitle: 'الأرباح المحققة عبر التاريخ',
              icon: Icons.auto_graph,
              color: const Color(0xFF388E3C), // Green shade 700
              fullWidth: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RevenueReportScreen(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _QuickActionCard(
          title: 'تأجير جديد',
          subtitle: 'بدء عقد تأجير لمقاول جديد',
          icon: Icons.add_shopping_cart,
          color: const Color(0xFF553117),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const CreateRentalBottomSheet(),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'المخزن',
                subtitle: 'إدارة المعدات',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF8D5B32),
                compact: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionCard(
                title: 'السجل ج',
                subtitle: 'العمليات السابقة',
                icon: Icons.history_edu,
                color: const Color(0xFFD4A373),
                compact: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RentalsListScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLowStockDetails(BuildContext context, List<InventoryItem> items) {
    // Correct logic: Show everything that is NOT in full stock, sorted by least available
    final missingItems = items
        .where((i) => i.availableQty < i.totalQty)
        .toList();
    missingItems.sort((a, b) {
      final ratioA = a.totalQty > 0 ? a.availableQty / a.totalQty : 0.0;
      final ratioB = b.totalQty > 0 ? b.availableQty / b.totalQty : 0.0;
      return ratioA.compareTo(ratioB);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: Color(0xFF553117)),
                      SizedBox(width: 8),
                      Text(
                        'جرد النواقص والخوارج',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF422712),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'قائمة بجميع المعدات الموجودة لدى المستأجرين حالياً',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: missingItems.isEmpty
                  ? const Center(child: Text('المخزن مكتمل حالياً'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: missingItems.length,
                      itemBuilder: (context, index) {
                        final item = missingItems[index];
                        final outQty = item.totalQty - item.availableQty;
                        final isCritical = item.availableQty == 0;
                        final ratio = item.totalQty > 0
                            ? item.availableQty / item.totalQty
                            : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isCritical
                                ? Colors.red.withOpacity(0.02)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCritical
                                  ? Colors.red.shade100
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCritical
                                        ? Colors.red.shade900
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  'الفئة: ${item.category}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'بره: $outQty',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: isCritical
                                            ? Colors.red
                                            : Colors.blueGrey,
                                      ),
                                    ),
                                    Text(
                                      'متاح: ${item.availableQty}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 4,
                                    backgroundColor: Colors.grey.shade100,
                                    color: isCritical
                                        ? Colors.red
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إغلاق'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InventoryScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF553117),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إدارة المخزن'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool fullWidth;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle = '',
    required this.icon,
    required this.color,
    this.fullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    if (fullWidth)
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: compact ? 24 : 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: compact ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: compact ? 10 : 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

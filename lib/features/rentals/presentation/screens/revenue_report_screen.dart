import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl/intl.dart' as intl;

import '../cubit/rental_cubit.dart';
import '../cubit/rental_state.dart';
import 'transaction_details_screen.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    _dateRange = DateTimeRange(start: start, end: end);
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقارير الإيرادات')),
      body: BlocBuilder<RentalCubit, RentalState>(
        builder: (context, state) {
          if (state is RentalLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RentalLoaded) {
            final allRentals = state.rentals;

            // Filter Logic
            // We consider 'closed' rentals for revenue.
            // Check if endDate falls within range.
            final filteredRentals = allRentals.where((r) {
              if (r.isActive || r.endDate == null) return false;
              if (_dateRange == null) return true;

              final end = r.endDate!;
              // Normalize dates to ignore time for fairer comparison
              final dStart = DateTime(
                _dateRange!.start.year,
                _dateRange!.start.month,
                _dateRange!.start.day,
              );
              final dEnd = DateTime(
                _dateRange!.end.year,
                _dateRange!.end.month,
                _dateRange!.end.day,
                23,
                59,
                59,
              );

              return end.isAfter(dStart.subtract(const Duration(seconds: 1))) &&
                  end.isBefore(dEnd.add(const Duration(seconds: 1)));
            }).toList();

            // Sort by Date Descending
            filteredRentals.sort((a, b) => b.endDate!.compareTo(a.endDate!));

            final totalRevenue = filteredRentals.fold(
              0.0,
              (sum, r) =>
                  sum + r.calculateTotalDue(r.endDate ?? DateTime.now()),
            );
            final totalCount = filteredRentals.length;

            return Column(
              children: [
                // Filter Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dateRange == null
                              ? 'كل الفترة'
                              : '${intl.DateFormat('yyyy-MM-dd').format(_dateRange!.start)}  إلى  ${intl.DateFormat('yyyy-MM-dd').format(_dateRange!.end)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickDateRange,
                        child: const Text('تغيير الفترة'),
                      ),
                    ],
                  ),
                ),

                // Summary Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _SummaryCard(
                        title: 'الإجمالي',
                        value: '${totalRevenue.toStringAsFixed(1)} ج.م',
                        color: Colors.green,
                        icon: Icons.attach_money,
                      ),
                      const SizedBox(width: 16),
                      _SummaryCard(
                        title: 'العمليات',
                        value: '$totalCount',
                        color: Colors.blue,
                        icon: Icons.receipt_long,
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // List
                Expanded(
                  child: filteredRentals.isEmpty
                      ? const Center(
                          child: Text('لا يوجد عمليات في هذه الفترة'),
                        )
                      : ListView.builder(
                          itemCount: filteredRentals.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final rental = filteredRentals[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TransactionDetailsScreen(
                                        transaction: rental,
                                      ),
                                    ),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.withOpacity(
                                    0.1,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(
                                  rental.tenantName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  intl.DateFormat(
                                    'yyyy-MM-dd hh:mm a',
                                  ).format(rental.endDate!),
                                ),
                                trailing: Text(
                                  '${rental.calculateTotalDue(rental.endDate ?? DateTime.now()).toStringAsFixed(1)} ج.م',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32), // green[800]
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
          return const Center(child: Text('حدث خطأ'));
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

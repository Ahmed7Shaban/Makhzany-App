import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/rental_cubit.dart';
import '../cubit/rental_state.dart';
import '../../data/models/rental_transaction_model.dart';
import 'transaction_details_screen.dart';
import 'closed_rental_receipt_screen.dart';
import '../../../tenants/data/models/tenant_model.dart';
import '../../../../core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;

class RentalsListScreen extends StatefulWidget {
  const RentalsListScreen({super.key});

  @override
  State<RentalsListScreen> createState() => _RentalsListScreenState();
}

class _RentalsListScreenState extends State<RentalsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'التأجيرات والسجل',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearchExpanded) {
                    _searchController.clear();
                  }
                  _isSearchExpanded = !_isSearchExpanded;
                });
              },
            ),
            IconButton(
              icon: Icon(
                Icons.calendar_month,
                color: _selectedDateRange != null ? Colors.orange : null,
              ),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _selectedDateRange,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF553117),
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) {
                  setState(() => _selectedDateRange = range);
                }
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              50 +
                  (_isSearchExpanded ? 60 : 0) +
                  (_selectedDateRange != null ? 50 : 0),
            ),
            child: Column(
              children: [
                if (_isSearchExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(width: 2, color: Colors.white30),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        obscureText: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        cursorColor: Colors.orange,
                        decoration: const InputDecoration(
                          hintText: 'ابحث باسم العميل أو الصنف...',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          suffixIcon: Icon(
                            Icons.search,
                            color: Colors.orange,
                            size: 24,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                if (_selectedDateRange != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(
                            'من ${intl.DateFormat('MM-dd').format(_selectedDateRange!.start)} إلى ${intl.DateFormat('MM-dd').format(_selectedDateRange!.end)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.orange.shade800,
                          onDeleted: () =>
                              setState(() => _selectedDateRange = null),
                          deleteIconColor: Colors.white,
                        ),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text(
                            'مسح الكل',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                const TabBar(
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  indicatorColor: Colors.orange,
                  tabs: [
                    Tab(text: 'الحالية (نشطة)'),
                    Tab(text: 'السجل (منتهية)'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<RentalCubit, RentalState>(
          builder: (context, state) {
            if (state is RentalLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is RentalLoaded) {
              final rawQuery = _searchController.text.toLowerCase().trim();
              final queryParts = rawQuery
                  .split(' ')
                  .where((p) => p.isNotEmpty)
                  .toList();

              final filteredRentals = state.rentals.where((r) {
                bool matchesSearch = true;
                if (queryParts.isNotEmpty) {
                  final tenantText =
                      '${r.tenantName} ${r.tenantPhone ?? ""} ${r.tenantAddress ?? ""}'
                          .toLowerCase();
                  final itemsText = r.items
                      .map((i) => i.itemName)
                      .join(' ')
                      .toLowerCase();
                  final fullText = '$tenantText $itemsText';
                  matchesSearch = queryParts.every(
                    (part) => fullText.contains(part),
                  );
                }

                bool matchesDate = true;
                if (_selectedDateRange != null) {
                  final start = _selectedDateRange!.start;
                  final end = _selectedDateRange!.end.add(
                    const Duration(days: 1),
                  );
                  matchesDate =
                      r.startDate.isAfter(start) && r.startDate.isBefore(end);
                }

                return matchesSearch && matchesDate;
              }).toList();

              final activeRentals = filteredRentals
                  .where((r) => r.isActive)
                  .toList();
              final closedRentals = filteredRentals
                  .where((r) => !r.isActive)
                  .toList();

              return TabBarView(
                children: [
                  _RentalsList(
                    key: const PageStorageKey('active_rentals'),
                    rentals: activeRentals,
                    canDelete: false,
                  ),
                  _RentalsList(
                    key: const PageStorageKey('closed_rentals'),
                    rentals: closedRentals,
                    canDelete: true,
                  ),
                ],
              );
            } else if (state is RentalError) {
              return Center(child: Text('خطأ: ${state.message}'));
            }
            return Container();
          },
        ),
      ),
    );
  }
}

class _RentalsList extends StatelessWidget {
  final List<RentalTransaction> rentals;
  final bool canDelete;
  const _RentalsList({
    super.key,
    required this.rentals,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    if (rentals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Color(0xFFEEEEEE)),
            SizedBox(height: 16),
            Text(
              'لا توجد نتائج مطابقة',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF757575),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        final activeItemsCount = rental.items
            .where((i) => i.status == 'Active')
            .length;
        final totalPaid = rental.payments.fold(0.0, (s, p) => s + p.amount);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 20,
                bottom: 20,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: rental.isActive ? Colors.green : Colors.grey,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    if (rental.isActive) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TransactionDetailsScreen(transaction: rental),
                        ),
                      );
                    } else {
                      final tenantBox = Hive.box<Tenant>(HiveBoxes.tenantsBox);
                      final tenant = tenantBox.get(rental.tenantId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClosedRentalReceiptScreen(
                            transaction: rental,
                            tenant: tenant,
                          ),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: rental.isActive
                                ? Colors.green.withOpacity(0.08)
                                : Colors.grey.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            rental.isActive ? Icons.engineering : Icons.history,
                            color: rental.isActive
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rental.tenantName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF422712),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: rental.isActive
                                          ? Colors.green.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      rental.isActive ? 'نشط' : 'مغلق',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: rental.isActive
                                            ? Colors.green.shade800
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (rental.tenantPhone != null &&
                                  rental.tenantPhone!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    rental.tenantPhone!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _infoLabel(
                                    Icons.widgets_outlined,
                                    '$activeItemsCount أصناف',
                                  ),
                                  const SizedBox(width: 12),
                                  _infoLabel(
                                    Icons.calendar_today,
                                    intl.DateFormat(
                                      'MM-dd',
                                    ).format(rental.startDate),
                                  ),
                                  const SizedBox(width: 12),
                                  _infoLabel(
                                    Icons.payments_outlined,
                                    '${totalPaid.toInt()} ج',
                                    color: Colors.green.shade600,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (canDelete)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 22,
                            ),
                            onPressed: () => _confirmDelete(context, rental),
                          ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade300,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoLabel(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color ?? Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color ?? Colors.grey[600],
            fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, RentalTransaction rental) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'حذف السجل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف سجل العميل "${rental.tenantName}" نهائياً؟ لا يمكن التراجع عن هذه الخطوة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              context.read<RentalCubit>().deleteRental(rental.id);
              Navigator.pop(ctx);
            },
            child: const Text(
              'حذف نهائي',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

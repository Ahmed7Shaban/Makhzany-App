import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/rental_cubit.dart';
import '../cubit/rental_state.dart';
import 'package:intl/intl.dart' as intl;
import '../widgets/rentals_list_view.dart';

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
                  RentalsListView(
                    key: const PageStorageKey('active_rentals'),
                    rentals: activeRentals,
                    canDelete: false,
                  ),
                  RentalsListView(
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

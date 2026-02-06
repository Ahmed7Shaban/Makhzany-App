import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/rental_transaction_model.dart';
import '../../data/models/rental_item.dart';

class ActiveItemsTab extends StatelessWidget {
  final RentalTransaction transaction;
  final List<RentalItem> items;
  final Function(RentalItem) onReturn;

  const ActiveItemsTab({
    super.key,
    required this.transaction,
    required this.items,
    required this.onReturn,
  });

  String _getDayName(DateTime date) {
    const shortDays = {
      DateTime.monday: 'اثنين',
      DateTime.tuesday: 'ثلاثاء',
      DateTime.wednesday: 'أربعاء',
      DateTime.thursday: 'خميس',
      DateTime.friday: 'جمعة',
      DateTime.saturday: 'سبت',
      DateTime.sunday: 'أحد',
    };
    return shortDays[date.weekday] ?? '';
  }

  String _formatFullDate(DateTime date) {
    return '${_getDayName(date)}، ${intl.DateFormat('yyyy-MM-dd').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text("لا توجد مديونية نشطة حالياً"));
    }
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        DateTime? effStart;
        if (transaction.lastSettlementDate != null &&
            transaction.lastSettlementDate!.isAfter(item.startDate)) {
          effStart = transaction.lastSettlementDate;
        }

        final breakdown = item.calculateDetailedDays(
          DateTime.now(),
          excludeFridays: transaction.discountFridays,
          alternativeStartDate: effStart,
        );
        final totalItemPrice =
            item.quantity * item.priceAtMoment * breakdown.chargeableDays;

        final isNewAddition = item.startDate.isAfter(transaction.startDate);

        return Card(
          elevation: isNewAddition ? 6 : 4,
          margin: const EdgeInsets.only(bottom: 16),
          color: isNewAddition ? const Color(0xFFF0F7FF) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isNewAddition
                ? BorderSide(color: Colors.blue.shade300, width: 2)
                : BorderSide.none,
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF553117),
                        ),
                      ),
                    ),
                    if (isNewAddition)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          'إضافة جديدة',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('الكمية: ${item.quantity}'),
                        const SizedBox(width: 15),
                        const Icon(
                          Icons.sell_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('السعر: ${item.priceAtMoment} ج'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'تاريخ الاستلام: ${_formatFullDate(item.startDate)}',
                          style: TextStyle(
                            color: isNewAddition
                                ? Colors.indigo.shade700
                                : Colors.black87,
                            fontWeight: isNewAddition
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Text(
                  '${totalItemPrice.toStringAsFixed(1)} ج',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _breakdownChip(
                      '${breakdown.totalDays} يوم',
                      Icons.timer,
                      Colors.blueGrey,
                    ),
                    if (transaction.discountFridays && breakdown.fridays > 0)
                      _breakdownChip(
                        '${breakdown.fridays} جمعة (خصم)',
                        Icons.event_busy,
                        Colors.redAccent,
                      ),
                    _breakdownChip(
                      'صافي: ${breakdown.chargeableDays} يوم',
                      Icons.calculate,
                      Colors.brown,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.assignment_return,
                        color: Colors.orange,
                      ),
                      onPressed: () => onReturn(item),
                      tooltip: 'إرجاع الصنف',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _breakdownChip(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

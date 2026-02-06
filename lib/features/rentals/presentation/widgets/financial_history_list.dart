import 'package:flutter/material.dart';
import '../../data/models/rental_transaction_model.dart';
import '../../data/models/financial_record_model.dart';
import '../../data/models/payment_log_model.dart';
import 'package:intl/intl.dart' as intl;

class FinancialHistoryList extends StatelessWidget {
  final RentalTransaction transaction;

  const FinancialHistoryList({super.key, required this.transaction});

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
    final List<dynamic> history = [
      ...transaction.invoices,
      ...transaction.payments,
    ];
    history.sort((a, b) {
      DateTime da = a is FinancialRecord ? a.date : (a as PaymentLog).date;
      DateTime db = b is FinancialRecord ? b.date : (b as PaymentLog).date;
      return db.compareTo(da);
    });

    if (history.isEmpty) return const Text('لا يوجد سجل مالي حالياً');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (ctx, idx) {
        final item = history[idx];
        final isInvoice = item is FinancialRecord;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isInvoice ? Icons.description_outlined : Icons.monetization_on,
              color: isInvoice ? Colors.blueGrey : Colors.green,
            ),
            title: Text(isInvoice ? 'تصفية مستخلص' : 'تحصيل نقدية'),
            subtitle: Text(_formatFullDate(isInvoice ? item.date : item.date)),
            trailing: Text(
              '${isInvoice ? '+' : '-'}${item.amount} ج',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isInvoice ? Colors.black : Colors.green[700],
              ),
            ),
          ),
        );
      },
    );
  }
}

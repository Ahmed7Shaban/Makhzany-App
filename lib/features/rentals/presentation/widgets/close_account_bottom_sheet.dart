import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/rental_transaction_model.dart';
import '../cubit/rental_cubit.dart';

class CloseAccountBottomSheet extends StatefulWidget {
  final RentalTransaction transaction;

  const CloseAccountBottomSheet({super.key, required this.transaction});

  @override
  State<CloseAccountBottomSheet> createState() =>
      _CloseAccountBottomSheetState();
}

class _CloseAccountBottomSheetState extends State<CloseAccountBottomSheet> {
  DateTime closeDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final unbilled = t.calculateUnbilledAmount(closeDate);
    final totalInvoiced = t.invoices.fold(0.0, (s, i) => s + i.amount);
    final totalPaid = t.payments.fold(0.0, (s, p) => s + p.amount);
    final finalBalance = (unbilled + totalInvoiced) - totalPaid;
    final totalFridays = t.calculateTotalUnbilledFridays(closeDate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_gmailerrorred, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'إغلاق الحساب نهائياً',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'سيتم حساب كل المديونية المتبقية، وإرجاع جميع المعدات للمخزن، وإيقاف العداد نهائياً لهذا العميل.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Text(
            'اختر تاريخ الإغلاق:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: closeDate,
                firstDate: t.lastSettlementDate ?? t.startDate,
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => closeDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade100),
                borderRadius: BorderRadius.circular(10),
                color: Colors.red.shade50.withOpacity(0.3),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    intl.DateFormat('yyyy-MM-dd').format(closeDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: t.discountFridays
                  ? Colors.orange.shade50
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: t.discountFridays
                    ? Colors.orange.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: SwitchListTile(
              activeColor: Colors.orange.shade800,
              title: Text(
                'خصم أيام الجمعة من الحساب الجديد',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: t.discountFridays
                      ? Colors.orange.shade900
                      : Colors.grey.shade700,
                ),
              ),
              subtitle: Text(
                t.discountFridays
                    ? 'سيتم استبعاد أيام الجمعة من المديونية الحالية'
                    : 'سيتم احتساب فترة الإغلاق بالكامل بدون خصم',
                style: const TextStyle(fontSize: 10),
              ),
              secondary: Icon(
                Icons.event_busy,
                color: t.discountFridays ? Colors.orange : Colors.grey,
              ),
              value: t.discountFridays,
              onChanged: (v) => setState(() => t.discountFridays = v),
            ),
          ),
          const SizedBox(height: 24),
          _infoRow(
            'تاريخ بداية التعاقد:',
            intl.DateFormat('yyyy-MM-dd').format(t.startDate),
          ),
          if (t.lastSettlementDate != null)
            _infoRow(
              'آخر تصفية كانت في:',
              intl.DateFormat('yyyy-MM-dd').format(t.lastSettlementDate!),
            ),
          _infoRow('عدد التصفيات السابقة:', '${t.invoices.length} مرات'),
          const Divider(height: 32),
          if (t.discountFridays && totalFridays > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_busy,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تم خصم $totalFridays يوم جمعة من المديونية الحالية',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _infoRow(
            'إجمالي الفواتير (حتى التاريخ المختار):',
            '${(unbilled + totalInvoiced).toStringAsFixed(1)} ج',
          ),
          _infoRow(
            'إجمالي المدفوعات:',
            '${totalPaid.toStringAsFixed(1)} ج',
            color: Colors.green,
          ),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المبلغ المطلوب للتقفيل:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  '${finalBalance.toStringAsFixed(1)} ج',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                context.read<RentalCubit>().closeRental(t, closeDate);
                Navigator.pop(context);
              },
              child: const Text(
                'تأكيد الإغلاق الصافي وتصفية الحساب',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

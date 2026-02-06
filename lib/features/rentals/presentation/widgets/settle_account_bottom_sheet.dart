import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/rental_transaction_model.dart';
import '../cubit/rental_cubit.dart';

class SettleAccountBottomSheet extends StatefulWidget {
  final RentalTransaction transaction;

  const SettleAccountBottomSheet({super.key, required this.transaction});

  @override
  State<SettleAccountBottomSheet> createState() =>
      _SettleAccountBottomSheetState();
}

class _SettleAccountBottomSheetState extends State<SettleAccountBottomSheet> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final activeItems = t.items.where((i) => i.status == 'Active').toList();
    double previewTotal = 0;
    List<Widget> calculationList = [];

    for (var item in activeItems) {
      DateTime? effStart;
      if (t.lastSettlementDate != null &&
          t.lastSettlementDate!.isAfter(item.startDate)) {
        effStart = t.lastSettlementDate;
      }
      final b = item.calculateDetailedDays(
        selectedDate,
        excludeFridays: t.discountFridays,
        alternativeStartDate: effStart,
      );
      final itemTotal = item.quantity * item.priceAtMoment * b.chargeableDays;
      previewTotal += itemTotal;

      calculationList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${item.quantity} قطعة × ${item.priceAtMoment} ج',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      '${b.chargeableDays} يوم',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (t.discountFridays && b.fridays > 0)
                      Text(
                        '(-${b.fridays} جمعة)',
                        style: const TextStyle(fontSize: 9, color: Colors.red),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${itemTotal.toStringAsFixed(1)} ج',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'معاينة التصفية (المستخلص)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'اختر تاريخ التصفية:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final fDate = (t.lastSettlementDate ?? t.startDate);
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate:
                    fDate.isBefore(
                      DateTime.now().subtract(const Duration(days: 3650)),
                    )
                    ? fDate
                    : DateTime.now().subtract(const Duration(days: 3650)),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => selectedDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.brown.shade200),
                borderRadius: BorderRadius.circular(10),
                color: Colors.brown.shade50.withOpacity(0.3),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.brown),
                  const SizedBox(width: 10),
                  Text(
                    intl.DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
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
                'خصم أيام الجمعة من الحساب',
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
                    ? 'سيتم استبعاد أيام الجمعة من التكلفة'
                    : 'سيتم احتساب جميع الأيام كأيام عمل',
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
          const SizedBox(height: 20),
          const Text(
            'تفاصيل الحساب:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (calculationList.isEmpty)
                    const Center(child: Text('لا توجد أصناف نشطة للتصفية'))
                  else
                    ...calculationList,
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.brown.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'إجمالي مبلغ التصفية:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${previewTotal.toStringAsFixed(1)} ج',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: previewTotal < 0
                  ? null
                  : () {
                      context.read<RentalCubit>().settleAccount(
                        t.id,
                        selectedDate,
                      );
                      Navigator.pop(context);
                    },
              child: const Text(
                'تأكيد وحفظ التصفية',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

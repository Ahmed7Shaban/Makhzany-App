import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/rental_item.dart';
import '../../data/models/rental_transaction_model.dart';
import '../cubit/rental_cubit.dart';

class ReturnItemBottomSheet extends StatefulWidget {
  final RentalTransaction transaction;
  final RentalItem item;

  const ReturnItemBottomSheet({
    super.key,
    required this.transaction,
    required this.item,
  });

  @override
  State<ReturnItemBottomSheet> createState() => _ReturnItemBottomSheetState();
}

class _ReturnItemBottomSheetState extends State<ReturnItemBottomSheet> {
  late double qty;
  DateTime selectedDate = DateTime.now();
  static const primaryBrown = Color(0xFF553117);

  @override
  void initState() {
    super.initState();
    qty = widget.item.quantity.toDouble();
  }

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

  Widget _rowInfo(
    String label,
    String val,
    IconData icon, {
    Color? color,
    bool isEditable = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700),
        ),
        const Spacer(),
        Text(
          val,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        if (isEditable) ...[
          const SizedBox(width: 4),
          const Icon(Icons.edit, size: 14, color: Colors.grey),
        ],
      ],
    );
  }

  Widget _statItem(String val, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color ?? Colors.blueGrey.shade900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = widget.item.calculateDetailedDays(
      selectedDate,
      excludeFridays: widget.transaction.discountFridays,
    );
    final estimatedCost =
        qty * widget.item.priceAtMoment * breakdown.chargeableDays;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'إرجاع: ${widget.item.itemName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBrown,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          // Period Info Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: Column(
              children: [
                _rowInfo(
                  'تاريخ الاستلام:',
                  _formatFullDate(widget.item.startDate),
                  Icons.login,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.blueGrey),
                ),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate:
                          widget.item.startDate.isBefore(
                            DateTime.now().subtract(const Duration(days: 3650)),
                          )
                          ? widget.item.startDate
                          : DateTime.now().subtract(const Duration(days: 3650)),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: _rowInfo(
                    'تاريخ الإرجاع:',
                    _formatFullDate(selectedDate),
                    Icons.logout,
                    color: Colors.blue.shade700,
                    isEditable: true,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('${breakdown.totalDays} يوم', 'الفترة الكلية'),
                    if (widget.transaction.discountFridays)
                      _statItem(
                        '${breakdown.fridays} يوم',
                        'خصم جمعة',
                        color: Colors.orange.shade800,
                      ),
                    _statItem(
                      '${breakdown.chargeableDays} يوم',
                      'أيام الدفع',
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الكمية المسترجعة:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${qty.toInt()} من ${widget.item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryBrown,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: qty,
            min: 1,
            max: widget.item.quantity.toDouble(),
            divisions: widget.item.quantity > 1 ? widget.item.quantity - 1 : 1,
            activeColor: primaryBrown,
            onChanged: (v) => setState(() => qty = v),
          ),
          const SizedBox(height: 16),
          // Cost Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حساب القطع في هذه الفترة:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                      ),
                    ),
                    Text(
                      '${qty.toInt()} قطعة × ${widget.item.priceAtMoment} ج × ${breakdown.chargeableDays} يوم',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  '${estimatedCost.toStringAsFixed(1)} ج',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                context.read<RentalCubit>().returnItemsPartial(
                  widget.transaction.id,
                  widget.item,
                  qty.toInt(),
                  selectedDate,
                );
                Navigator.pop(context);
              },
              child: const Text(
                'تأكيد وإرجاع للمخزن',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/rental_transaction_model.dart';
import '../../data/models/rental_item.dart';
import '../../data/models/payment_log_model.dart';
import '../../data/models/financial_record_model.dart';
import '../cubit/rental_cubit.dart';
import '../cubit/rental_state.dart';
import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_state.dart';

import '../../../tenants/presentation/cubit/tenant_cubit.dart';
import '../../../tenants/presentation/cubit/tenant_state.dart';
import '../../../tenants/data/models/tenant_model.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final RentalTransaction transaction;
  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  final Color primaryBrown = const Color(0xFF553117);

  // --- UI Helpers ---

  void _showReturnBottomSheet(RentalItem item) {
    double qty = item.quantity.toDouble();
    DateTime selectedDate = DateTime.now();
    final t = widget.transaction;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final breakdown = item.calculateDetailedDays(
            selectedDate,
            excludeFridays: t.discountFridays,
          );
          final estimatedCost =
              qty * item.priceAtMoment * breakdown.chargeableDays;

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
                        'إرجاع: ${item.itemName}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
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
                        _formatFullDate(item.startDate),
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
                                item.startDate.isBefore(
                                  DateTime.now().subtract(
                                    const Duration(days: 3650),
                                  ),
                                )
                                ? item.startDate
                                : DateTime.now().subtract(
                                    const Duration(days: 3650),
                                  ),
                            lastDate: DateTime(2100),
                          );
                          if (date != null)
                            setSheetState(() => selectedDate = date);
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
                          _statItem(
                            '${breakdown.totalDays} يوم',
                            'الفترة الكلية',
                          ),
                          if (t.discountFridays)
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
                    Text(
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
                        '${qty.toInt()} من ${item.quantity}',
                        style: TextStyle(
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
                  max: item.quantity.toDouble(),
                  divisions: item.quantity > 1 ? item.quantity - 1 : 1,
                  activeColor: primaryBrown,
                  onChanged: (v) => setSheetState(() => qty = v),
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
                            '${qty.toInt()} قطعة × ${item.priceAtMoment} ج × ${breakdown.chargeableDays} يوم',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
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
                        item,
                        qty.toInt(),
                        selectedDate,
                      );
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'تأكيد وإرجاع للمخزن',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
        Text(label, style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
      ],
    );
  }

  void _showAddItemsBottomSheet() {
    context.read<InventoryCubit>().loadInventory();
    final Map<String, int> selectedQtys = {};
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryBrown.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_shopping_cart, color: primaryBrown),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة عُهدة جديدة',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF422712),
                            ),
                          ),
                          Text(
                            'اختر المعدات الإضافية التي استلمها العميل الآن',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<InventoryCubit, InventoryState>(
                  builder: (context, state) {
                    if (state is! InventoryLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final availableItems = state.items
                        .where((i) => i.availableQty > 0)
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text(
                          'تاريخ الاستلام الإضافي:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null)
                              setSheetState(() => selectedDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  size: 20,
                                  color: Colors.blueGrey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  intl.DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'قائمة المعدات المتاحة:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...availableItems.map((item) {
                          final currentQty = selectedQtys[item.id] ?? 0;
                          final isPicked = currentQty > 0;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isPicked
                                  ? primaryBrown.withOpacity(0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPicked
                                    ? primaryBrown
                                    : Colors.grey.shade200,
                                width: isPicked ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: isPicked
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'متاح: ${item.availableQty} | بسعر: ${item.pricePerDay} ج',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPicked)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => setSheetState(() {
                                        if (currentQty > 0)
                                          selectedQtys[item.id] =
                                              currentQty - 1;
                                      }),
                                    ),
                                  if (isPicked)
                                    Text(
                                      '$currentQty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle,
                                      color: currentQty < item.availableQty
                                          ? primaryBrown
                                          : Colors.grey.shade300,
                                    ),
                                    onPressed: currentQty < item.availableQty
                                        ? () => setSheetState(() {
                                            selectedQtys[item.id] =
                                                currentQty + 1;
                                          })
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: selectedQtys.values.every((v) => v == 0)
                        ? null
                        : () {
                            final List<RentalItem> newItems = [];
                            final inventoryState = context
                                .read<InventoryCubit>()
                                .state;
                            if (inventoryState is InventoryLoaded) {
                              selectedQtys.forEach((id, q) {
                                if (q > 0) {
                                  final inv = inventoryState.items.firstWhere(
                                    (i) => i.id == id,
                                  );
                                  newItems.add(
                                    RentalItem(
                                      itemId: inv.id,
                                      itemName: inv.name,
                                      quantity: q,
                                      priceAtMoment: inv.pricePerDay,
                                      startDate: selectedDate,
                                      status: 'Active',
                                    ),
                                  );
                                }
                              });
                              context.read<RentalCubit>().addExtraItems(
                                widget.transaction.id,
                                newItems,
                              );
                              Navigator.pop(ctx);
                            }
                          },
                    child: const Text(
                      'إضافة المعدات المحددة للفاتورة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettleBottomSheet(RentalTransaction t) {
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final activeItems = t.items
              .where((i) => i.status == 'Active')
              .toList();
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
            final itemTotal =
                item.quantity * item.priceAtMoment * b.chargeableDays;
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
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
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
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.red,
                              ),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
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
                    if (date != null) setSheetState(() => selectedDate = date);
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
                    onChanged: (v) =>
                        setSheetState(() => t.discountFridays = v),
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
                          const Center(
                            child: Text('لا توجد أصناف نشطة للتصفية'),
                          )
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
                              widget.transaction.id,
                              selectedDate,
                            );
                            Navigator.pop(ctx);
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
        },
      ),
    );
  }

  void _addPayment() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تسجيل دفعة نقدية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'قيمة المبلغ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  final amount = double.tryParse(amountCtrl.text) ?? 0;
                  if (amount > 0) {
                    context.read<RentalCubit>().addPayment(
                      widget.transaction.id,
                      PaymentLog(
                        amount: amount,
                        date: DateTime.now(),
                        note: noteCtrl.text,
                      ),
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('حفظ الدفعة'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReceipt(RentalTransaction t) async {
    final tenantState = context.read<TenantCubit>().state;
    Tenant? tenant;
    if (tenantState is TenantLoaded) {
      tenant = tenantState.tenants
          .where((ten) => ten.id == t.tenantId)
          .firstOrNull;
    }

    // 1. Capture Summary Part (Current Active Items + Totals)
    final summaryBytes = await screenshotController.captureFromWidget(
      ReceiptPartWidget(
        transaction: t,
        mode: ReceiptPartMode.summary,
        tenant: tenant,
      ),
      context: context,
      delay: const Duration(milliseconds: 500),
    );

    // 2. Capture History Part (Payments + Returns + Settlements)
    final historyBytes = await screenshotController.captureFromWidget(
      ReceiptPartWidget(
        transaction: t,
        mode: ReceiptPartMode.history,
        tenant: tenant,
      ),
      context: context,
      delay: const Duration(milliseconds: 500),
    );

    final directory = await getApplicationDocumentsDirectory();
    final summaryFile = await File(
      '${directory.path}/summary_${t.id}.png',
    ).create();
    await summaryFile.writeAsBytes(summaryBytes);

    final historyFile = await File(
      '${directory.path}/history_${t.id}.png',
    ).create();
    await historyFile.writeAsBytes(historyBytes);

    await Share.shareXFiles([
      XFile(summaryFile.path),
      XFile(historyFile.path),
    ], text: t.tenantName);
  }

  void _showCloseAccountBottomSheet(RentalTransaction t) {
    if (!t.isActive) return;

    DateTime closeDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
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
                    Icon(
                      Icons.report_gmailerrorred,
                      color: Colors.red,
                      size: 28,
                    ),
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
                    if (date != null) setSheetState(() => closeDate = date);
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
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.red,
                          size: 20,
                        ),
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
                    onChanged: (v) =>
                        setSheetState(() => t.discountFridays = v),
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
                      Navigator.pop(ctx);
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
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RentalCubit, RentalState>(
      builder: (context, state) {
        RentalTransaction? t;
        if (state is RentalLoaded) {
          t = state.rentals
              .where((r) => r.id == widget.transaction.id)
              .firstOrNull;
        }
        final currentTx = t ?? widget.transaction;

        final activeItems = currentTx.items
            .where((i) => i.status == 'Active')
            .toList();
        final returnedItems = currentTx.items
            .where((i) => i.status == 'Returned')
            .toList();

        final unbilled = currentTx.calculateUnbilledAmount(DateTime.now());
        final totalInvoiced = currentTx.invoices.fold(
          0.0,
          (s, i) => s + i.amount,
        );
        final totalDue = unbilled + totalInvoiced;
        final totalPaid = currentTx.payments.fold(0.0, (s, p) => s + p.amount);
        final balance = totalDue - totalPaid;

        final tenantState = context.watch<TenantCubit>().state;
        Tenant? tenant;
        if (tenantState is TenantLoaded) {
          tenant = tenantState.tenants
              .where((ten) => ten.id == currentTx.tenantId)
              .firstOrNull;
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: primaryBrown,
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentTx.tenantName),
                  Text(
                    '${activeItems.length} صنف نشط',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareReceipt(currentTx),
                ),
                IconButton(
                  icon: const Icon(Icons.post_add),
                  onPressed: _showAddItemsBottomSheet,
                ),
              ],
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'النشط'),
                  Tab(text: 'المرتجع'),
                  Tab(text: 'الماليات'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildActiveTab(currentTx, activeItems),
                _buildReturnedTab(returnedItems),
                _buildFinancialsTab(
                  currentTx,
                  unbilled,
                  totalInvoiced,
                  totalDue,
                  totalPaid,
                  balance,
                  tenant: tenant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab(RentalTransaction t, List<RentalItem> items) {
    if (items.isEmpty)
      return const Center(child: Text("لا توجد مديونية نشطة حالياً"));
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        DateTime? effStart;
        if (t.lastSettlementDate != null &&
            t.lastSettlementDate!.isAfter(item.startDate)) {
          effStart = t.lastSettlementDate;
        }

        final breakdown = item.calculateDetailedDays(
          DateTime.now(),
          excludeFridays: t.discountFridays,
          alternativeStartDate: effStart,
        );
        final totalItemPrice =
            item.quantity * item.priceAtMoment * breakdown.chargeableDays;

        final isNewAddition = item.startDate.isAfter(t.startDate);

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
                    if (t.discountFridays && breakdown.fridays > 0)
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
                      onPressed: () => _showReturnBottomSheet(item),
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

  Widget _buildReturnedTab(List<RentalItem> items) {
    if (items.isEmpty) return const Center(child: Text("سجل المرتجعات فارغ"));
    final t = widget.transaction;

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        final breakdown = item.calculateDetailedDays(
          item.returnDate ?? DateTime.now(),
          excludeFridays: t.discountFridays,
        );
        final totalItemCost =
            item.quantity * item.priceAtMoment * breakdown.chargeableDays;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 15,
                bottom: 15,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.assignment_return,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryBrown,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'تم الإرجاع',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _returnedInfoBox(
                            'تاريخ الاستلام',
                            _formatFullDate(item.startDate),
                            Icons.login_outlined,
                          ),
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey.shade200,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Expanded(
                          child: _returnedInfoBox(
                            'تاريخ الإرجاع',
                            _formatFullDate(item.returnDate ?? DateTime.now()),
                            Icons.logout_outlined,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'التفاصيل: ${item.quantity} قطعة × ${breakdown.chargeableDays} يوم',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (t.discountFridays && breakdown.fridays > 0)
                              Text(
                                '(تم استبعاد ${breakdown.fridays} جمعة من الحساب)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '${totalItemCost.toStringAsFixed(1)} ج',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
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

  Widget _returnedInfoBox(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialsTab(
    RentalTransaction t,
    double unbilled,
    double invoiced,
    double total,
    double paid,
    double bal, {
    Tenant? tenant,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Internal Client Info (For user only)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 16,
                      color: Colors.blueGrey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'بيانات العميل (خاصة بك)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _internalInfoRow(
                  Icons.phone,
                  'رقم الهاتف:',
                  (tenant?.phoneNumber ?? t.tenantPhone) ?? 'غير مسجل',
                ),
                const SizedBox(height: 10),
                _internalInfoRow(
                  Icons.location_on,
                  'العنوان:',
                  (tenant?.address ?? t.tenantAddress) ?? 'غير مسجل',
                ),
                const SizedBox(height: 10),
                _internalInfoRow(
                  Icons.description,
                  'الوصف:',
                  tenant?.notes ?? 'لا توجد ملاحظات',
                ),
                const SizedBox(height: 10),
                _internalInfoRow(
                  Icons.badge,
                  'حالة البطاقة:',
                  tenant?.hasIdCard == true
                      ? 'صورة البطاقة متوفرة'
                      : 'لا توجد صورة بطاقة',
                  valueColor: tenant?.hasIdCard == true
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditTenantBottomSheet(tenant, t),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: Text(
                      'تعديل الملف الشخصي للعميل',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBrown,
                      side: BorderSide(color: primaryBrown.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. Balance Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bal > 0
                    ? [Colors.red.shade800, Colors.red.shade600]
                    : [Colors.teal.shade800, Colors.teal.shade600],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (bal > 0 ? Colors.red : Colors.teal).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'الرصيد المتبقي (الصافي)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${bal.toStringAsFixed(1)} ج',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        bal > 0
                            ? Icons.info_outline
                            : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bal > 0 ? 'مديونية مستحقة' : 'الحساب خالص',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Breakdown Section
          Text(
            'تفاصيل المديونية:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _financialItemRow(
                  'مديونية الفترة الحالية (غير مفوترة)',
                  unbilled,
                  Colors.orange.shade800,
                  Icons.trending_up,
                  subtitle: t.discountFridays ? 'تاريخ التصفية القادم' : null,
                ),
                if (t.discountFridays)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 54,
                      left: 16,
                      bottom: 12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 12,
                            color: Colors.orange.shade900,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'المستبعد: ${t.calculateTotalUnbilledFridays(DateTime.now())} يوم جمعة',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 1),
                _financialItemRow(
                  'مستخلصات سابقة (فواتير)',
                  invoiced,
                  Colors.blueGrey.shade700,
                  Icons.history_edu,
                ),
                const Divider(height: 1),
                _financialItemRow(
                  'إجمالي المديونية المستحقة',
                  total,
                  primaryBrown,
                  Icons.account_balance_wallet,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Payment Summary
          Text(
            'حالة الدفع:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجمالي ما تم دفعه',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${paid.toStringAsFixed(1)} ج',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'النسبة المحصلة',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      total > 0
                          ? '${((paid / total) * 100).toStringAsFixed(0)}%'
                          : '0%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 4. Quick Actions
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  Icons.add_card,
                  'دفع مبلغ',
                  Colors.green.shade700,
                  _addPayment,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(
                  Icons.assignment_turned_in,
                  'تصفية فترة',
                  Colors.blueGrey.shade800,
                  () => _showSettleBottomSheet(t),
                ),
              ),
            ],
          ),
          if (t.isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _actionBtn(
                Icons.no_accounts,
                'إنهاء وإغلاق الحساب نهائياً',
                Colors.red.shade800,
                () => _showCloseAccountBottomSheet(t),
              ),
            ),
          ],
          const SizedBox(height: 40),
          Row(
            children: [
              const Icon(Icons.history, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'سجل الحركة المالية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFinancialHistory(t),
        ],
      ),
    );
  }

  Widget _financialItemRow(
    String label,
    double value,
    Color color,
    IconData icon, {
    bool isBold = false,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} ج',
            style: TextStyle(
              fontSize: isBold ? 18 : 15,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: isBold ? primaryBrown : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _internalInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: primaryBrown.withOpacity(0.6)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.blueGrey.shade900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFinancialHistory(RentalTransaction t) {
    final List<dynamic> history = [...t.invoices, ...t.payments];
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

  void _showEditTenantBottomSheet(Tenant? tenant, RentalTransaction t) {
    if (tenant == null) return;

    final nameCtrl = TextEditingController(text: tenant.name);
    final phoneCtrl = TextEditingController(text: tenant.phoneNumber);
    final addressCtrl = TextEditingController(text: tenant.address);
    final notesCtrl = TextEditingController(text: tenant.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تعديل بيانات العميل',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم العميل',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'الوصف / ملاحظات إضافية',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final updatedTenant = Tenant(
                    id: tenant.id,
                    name: nameCtrl.text,
                    phoneNumber: phoneCtrl.text,
                    address: addressCtrl.text,
                    notes: notesCtrl.text,
                    hasIdCard: tenant.hasIdCard,
                  );

                  await context.read<TenantCubit>().updateTenant(updatedTenant);

                  // Update the transaction snapshot too
                  t.tenantName = nameCtrl.text;
                  t.tenantPhone = phoneCtrl.text;
                  t.tenantAddress = addressCtrl.text;
                  await t.save();

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث بيانات العميل بنجاح'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'حفظ التغييرات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

enum ReceiptPartMode { summary, history }

class ReceiptPartWidget extends StatelessWidget {
  final RentalTransaction transaction;
  final ReceiptPartMode mode;
  final Tenant? tenant;
  const ReceiptPartWidget({
    super.key,
    required this.transaction,
    required this.mode,
    this.tenant,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final unbilled = transaction.calculateUnbilledAmount(now);
    final totalInvoiced = transaction.invoices.fold(
      0.0,
      (s, i) => s + i.amount,
    );
    final totalPaid = transaction.payments.fold(0.0, (s, p) => s + p.amount);
    final balance = (unbilled + totalInvoiced) - totalPaid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.white,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'فاتورة',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF553117),
                        ),
                      ),
                      Text(
                        transaction.tenantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'تاريخ التقرير: ${_formatFullDate(now)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.receipt_long,
                    size: 40,
                    color: Color(0xFF553117),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8DED6)),
                ),
                child: Column(
                  children: [
                    _receiptRow(
                      'العميل:',
                      transaction.tenantName,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (mode == ReceiptPartMode.summary) ...[
                const Text(
                  'البضاعة النشطة (حالياً)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF553117),
                  ),
                ),
                const SizedBox(height: 12),
                _buildItemsTable(
                  transaction.items.where((i) => i.status == 'Active').toList(),
                ),
                const SizedBox(height: 24),
                const Divider(thickness: 1),
                const SizedBox(height: 8),
                _receiptRow(
                  'مديونية الاستهلاك الحالي:',
                  '${unbilled.toStringAsFixed(1)} ج',
                ),
                _receiptRow(
                  'إجمالي فواتير سابقة:',
                  '${totalInvoiced.toStringAsFixed(1)} ج',
                ),
                const Divider(height: 32),
                _receiptRow(
                  'إجمالي المديونية المستحقة:',
                  '${(unbilled + totalInvoiced).toStringAsFixed(1)} ج',
                  isBold: true,
                ),
                _receiptRow(
                  'إجمالي الدفعات النقدية:',
                  '${totalPaid.toStringAsFixed(1)} ج',
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: balance > 0
                        ? const Color(0xFFFFF1F0)
                        : const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الرصيد المتبقي في الذمة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balance > 0
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                      Text(
                        '${balance.toStringAsFixed(1)} ج',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: balance > 0
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (mode == ReceiptPartMode.history) _buildHistoryPart(),

              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Text(
                      '══════════════════════════',
                      style: TextStyle(color: Colors.grey.shade300),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'نورتنا يا هندسة.. نتمنى لك يوماً سعيداً!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF553117),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPart() {
    final returnedItems = transaction.items
        .where((i) => i.status == 'Returned')
        .toList();
    final payments = transaction.payments;
    final invoices = transaction.invoices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجل الحركة التفصيلي (المرتجع والدفعات)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF553117),
          ),
        ),
        const Divider(height: 30),
        const Text(
          '1. سجل المرتجعات:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
        if (returnedItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('لا يوجد مرتجعات سابقة'),
          )
        else
          _buildReturnsTable(returnedItems),
        const SizedBox(height: 25),
        const Text(
          '2. سجل الدفعات النقدية:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
        if (payments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('لا يوجد دفعات مسجلة'),
          )
        else
          _buildPaymentsTable(payments),
        const SizedBox(height: 25),
        const Text(
          '3. سجل المستخلصات (التصفيات):',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
        if (invoices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('لا يوجد تصفيات سابقة'),
          )
        else
          _buildSettlementsTable(invoices),
      ],
    );
  }

  Widget _buildItemsTable(List<RentalItem> items) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5), // Item Name
        1: FlexColumnWidth(1), // Date
        2: FlexColumnWidth(0.8), // Qty
        3: FlexColumnWidth(1), // price/day
        4: FlexColumnWidth(0.8), // Days
        5: FlexColumnWidth(1.2), // Total
      },
      border: TableBorder.all(color: Colors.grey[300]!),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: const [
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'الصنف',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'من تاريخ',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'ع',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'سعر يوم',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'يوم',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'إجمالي',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ),
          ],
        ),
        ...items.map((i) {
          DateTime? effStart;
          if (transaction.lastSettlementDate != null &&
              transaction.lastSettlementDate!.isAfter(i.startDate)) {
            effStart = transaction.lastSettlementDate;
          }
          final b = i.calculateDetailedDays(
            DateTime.now(),
            excludeFridays: transaction.discountFridays,
            alternativeStartDate: effStart,
          );
          final total = i.quantity * i.priceAtMoment * b.chargeableDays;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(i.itemName, style: const TextStyle(fontSize: 8)),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  intl.DateFormat('MM-dd').format(effStart ?? i.startDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${i.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${i.priceAtMoment}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${b.chargeableDays}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${total.toStringAsFixed(1)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildReturnsTable(List<RentalItem> items) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1.5),
      },
      border: TableBorder.all(color: Colors.grey[300]!),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[50]),
          children: const [
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'الصنف المرتجع',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'ع',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'سعر',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'أيام',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'جمعة',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'الإجمالي',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
        ...items.map((i) {
          DateTime? effStart;
          if (transaction.lastSettlementDate != null &&
              transaction.lastSettlementDate!.isAfter(i.startDate)) {
            effStart = transaction.lastSettlementDate;
          }
          final b = i.calculateDetailedDays(
            DateTime.now(),
            excludeFridays: transaction.discountFridays,
            alternativeStartDate: effStart,
          );
          final total = i.quantity * i.priceAtMoment * b.chargeableDays;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(i.itemName, style: const TextStyle(fontSize: 9)),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${i.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${i.priceAtMoment}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${b.totalDays}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${b.fridays}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${total.toStringAsFixed(1)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPaymentsTable(List<PaymentLog> payments) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.green[50]),
          children: const [
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'التاريخ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'المبلغ',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'ملاحظة',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        ...payments.map(
          (p) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  intl.DateFormat('yyyy-MM-dd').format(p.date),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${p.amount} ج',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  p.note ?? '-',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementsTable(List<FinancialRecord> records) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blue[50]),
          children: const [
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'فترة التصفية',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'المبلغ',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        ...records.map(
          (r) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${_getDayName(r.periodStar)} ${intl.DateFormat('MM-dd').format(r.periodStar)} إلى ${_getDayName(r.periodEnd)} ${intl.DateFormat('MM-dd').format(r.periodEnd)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  '${r.amount} ج',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

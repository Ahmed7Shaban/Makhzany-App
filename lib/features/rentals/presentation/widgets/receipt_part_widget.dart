import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/rental_transaction_model.dart';
import '../../data/models/rental_item.dart';
import '../../data/models/payment_log_model.dart';
import '../../data/models/financial_record_model.dart';
import '../../../tenants/data/models/tenant_model.dart';

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

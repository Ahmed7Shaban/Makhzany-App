import 'package:flutter/material.dart';
import '../../data/models/rental_transaction_model.dart';
import '../../data/models/payment_log_model.dart';
import '../../../tenants/data/models/tenant_model.dart';
import 'financial_history_list.dart';

class FinancialsTab extends StatelessWidget {
  final RentalTransaction transaction;
  final double unbilled;
  final double invoiced;
  final double total;
  final double paid;
  final double balance;
  final Tenant? tenant;
  final VoidCallback onAddPayment;
  final VoidCallback onSettle;
  final VoidCallback onCloseAccount;
  final VoidCallback onEditTenant;

  const FinancialsTab({
    super.key,
    required this.transaction,
    required this.unbilled,
    required this.invoiced,
    required this.total,
    required this.paid,
    required this.balance,
    this.tenant,
    required this.onAddPayment,
    required this.onSettle,
    required this.onCloseAccount,
    required this.onEditTenant,
  });

  static const primaryBrown = Color(0xFF553117);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Internal Client Info
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
                  (tenant?.phoneNumber ?? transaction.tenantPhone) ??
                      'غير مسجل',
                ),
                const SizedBox(height: 10),
                _internalInfoRow(
                  Icons.location_on,
                  'العنوان:',
                  (tenant?.address ?? transaction.tenantAddress) ?? 'غير مسجل',
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
                    onPressed: onEditTenant,
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text(
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
                colors: balance > 0
                    ? [Colors.red.shade800, Colors.red.shade600]
                    : [Colors.teal.shade800, Colors.teal.shade600],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (balance > 0 ? Colors.red : Colors.teal).withOpacity(
                    0.3,
                  ),
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
                  '${balance.toStringAsFixed(1)} ج',
                  style: const TextStyle(
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
                        balance > 0
                            ? Icons.info_outline
                            : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        balance > 0 ? 'مديونية مستحقة' : 'الحساب خالص',
                        style: const TextStyle(
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
                  subtitle: transaction.discountFridays
                      ? 'تاريخ التصفية القادم'
                      : null,
                ),
                if (transaction.discountFridays)
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
                            'المستبعد: ${transaction.calculateTotalUnbilledFridays(DateTime.now())} يوم جمعة',
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
                      const Text(
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
                    const Text(
                      'النسبة المحصلة',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      total > 0
                          ? '${((paid / total) * 100).toStringAsFixed(0)}%'
                          : '0%',
                      style: const TextStyle(
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
                  onAddPayment,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(
                  Icons.assignment_turned_in,
                  'تصفية فترة',
                  Colors.blueGrey.shade800,
                  onSettle,
                ),
              ),
            ],
          ),
          if (transaction.isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _actionBtn(
                Icons.no_accounts,
                'إنهاء وإغلاق الحساب نهائياً',
                Colors.red.shade800,
                onCloseAccount,
              ),
            ),
          ],
          const SizedBox(height: 40),
          const Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'سجل الحركة المالية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FinancialHistoryList(transaction: transaction),
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
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

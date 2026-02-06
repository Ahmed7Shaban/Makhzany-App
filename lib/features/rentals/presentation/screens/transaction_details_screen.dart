import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/rental_transaction_model.dart';
import '../../data/models/rental_item.dart';
import '../cubit/rental_cubit.dart';
import '../cubit/rental_state.dart';
import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../tenants/presentation/cubit/tenant_cubit.dart';
import '../../../tenants/presentation/cubit/tenant_state.dart';
import '../../../tenants/data/models/tenant_model.dart';

import '../widgets/receipt_part_widget.dart';
import '../widgets/active_items_tab.dart';
import '../widgets/returned_items_tab.dart';
import '../widgets/financials_tab.dart';
import '../widgets/add_items_bottom_sheet.dart';
import '../widgets/return_item_bottom_sheet.dart';
import '../widgets/settle_account_bottom_sheet.dart';
import '../widgets/close_account_bottom_sheet.dart';

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

  void _showReturnBottomSheet(RentalItem item, RentalTransaction t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReturnItemBottomSheet(transaction: t, item: item),
    );
  }

  void _showAddItemsBottomSheet() {
    context.read<InventoryCubit>().loadInventory();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AddItemsBottomSheet(transactionId: widget.transaction.id),
    );
  }

  void _showSettleBottomSheet(RentalTransaction t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettleAccountBottomSheet(transaction: t),
    );
  }

  void _showCloseAccountBottomSheet(RentalTransaction t) {
    if (!t.isActive) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CloseAccountBottomSheet(transaction: t),
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('جاري إنشاء صور الفاتورة...')));

    try {
      final img1 = await screenshotController.captureFromWidget(
        ReceiptPartWidget(
          transaction: t,
          mode: ReceiptPartMode.summary,
          tenant: tenant,
        ),
        delay: const Duration(milliseconds: 100),
      );

      final img2 = await screenshotController.captureFromWidget(
        ReceiptPartWidget(
          transaction: t,
          mode: ReceiptPartMode.history,
          tenant: tenant,
        ),
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final path1 = '${directory.path}/receipt_summary_${t.id}.png';
      final path2 = '${directory.path}/receipt_history_${t.id}.png';

      await File(path1).writeAsBytes(img1);
      await File(path2).writeAsBytes(img2);

      await Share.shareXFiles(
        [XFile(path1), XFile(path2)],
        text:
            'فاتورة العميل: ${t.tenantName}\nبتاريخ: ${_formatFullDate(DateTime.now())}',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في مشاركة الفاتورة: $e')));
    }
  }

  void _addPayment(RentalTransaction t) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة دفعة نقدية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'المبلغ (ج)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text);
              if (amt != null && amt > 0) {
                context.read<RentalCubit>().addPayment(
                  t.id,
                  amt,
                  noteCtrl.text,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEditTenantBottomSheet(Tenant? tenant, RentalTransaction t) {
    final nameCtrl = TextEditingController(text: tenant?.name ?? t.tenantName);
    final phoneCtrl = TextEditingController(
      text: tenant?.phoneNumber ?? t.tenantPhone,
    );
    final addressCtrl = TextEditingController(
      text: tenant?.address ?? t.tenantAddress,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تعديل بيانات العميل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'الهاتف'),
            ),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (tenant != null) {
                    tenant.name = nameCtrl.text;
                    tenant.phoneNumber = phoneCtrl.text;
                    tenant.address = addressCtrl.text;
                    context.read<TenantCubit>().updateTenant(tenant);
                  }
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
                child: const Text(
                  'حفظ التغييرات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
                ActiveItemsTab(
                  transaction: currentTx,
                  items: activeItems,
                  onReturn: (item) => _showReturnBottomSheet(item, currentTx),
                ),
                ReturnedItemsTab(transaction: currentTx, items: returnedItems),
                FinancialsTab(
                  transaction: currentTx,
                  unbilled: unbilled,
                  invoiced: totalInvoiced,
                  total: totalDue,
                  paid: totalPaid,
                  balance: balance,
                  tenant: tenant,
                  onAddPayment: () => _addPayment(currentTx),
                  onSettle: () => _showSettleBottomSheet(currentTx),
                  onCloseAccount: () => _showCloseAccountBottomSheet(currentTx),
                  onEditTenant: () =>
                      _showEditTenantBottomSheet(tenant, currentTx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

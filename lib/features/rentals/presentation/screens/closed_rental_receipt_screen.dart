import 'package:flutter/material.dart';

import '../../data/models/rental_transaction_model.dart';
import '../../../tenants/data/models/tenant_model.dart';
import '../widgets/receipt_part_widget.dart';
import 'transaction_details_screen.dart';

class ClosedRentalReceiptScreen extends StatelessWidget {
  final RentalTransaction transaction;
  final Tenant? tenant;

  const ClosedRentalReceiptScreen({
    super.key,
    required this.transaction,
    this.tenant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'إيصال تصفية نهائية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // We could trigger the share logic here by calling the capture method
              // But for now, just show the UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'استخدم زر المشاركة من داخل شاشة الإدارة للتصدير بصيغة صورة',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: ReceiptPartWidget(
                  transaction: transaction,
                  tenant: tenant,
                  mode: ReceiptPartMode.summary,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: ReceiptPartWidget(
                  transaction: transaction,
                  tenant: tenant,
                  mode: ReceiptPartMode.history,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TransactionDetailsScreen(transaction: transaction),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('فتح صفحة الإدارة كاملة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF553117),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/rental_transaction_model.dart';
import '../../data/models/rental_item.dart';
import '../../../tenants/data/models/tenant_model.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../cubit/rental_cubit.dart';
import '../screens/transaction_details_screen.dart';
import '../screens/closed_rental_receipt_screen.dart';
import 'rental_card.dart';

class RentalsListView extends StatelessWidget {
  final List<RentalTransaction> rentals;
  final bool canDelete;

  const RentalsListView({
    super.key,
    required this.rentals,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    if (rentals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Color(0xFFEEEEEE)),
            SizedBox(height: 16),
            Text(
              'لا توجد نتائج مطابقة',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF757575),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        return RentalCard(
          rental: rental,
          canDelete: canDelete,
          onTap: () {
            if (rental.isActive) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailsScreen(transaction: rental),
                ),
              );
            } else {
              final tenantBox = Hive.box<Tenant>(HiveBoxes.tenantsBox);
              final tenant = tenantBox.get(rental.tenantId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClosedRentalReceiptScreen(
                    transaction: rental,
                    tenant: tenant,
                  ),
                ),
              );
            }
          },
          onDelete: (r) => _confirmDelete(context, r),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, RentalTransaction rental) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'حذف السجل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف سجل العميل "${rental.tenantName}" نهائياً؟ لا يمكن التراجع عن هذه الخطوة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              context.read<RentalCubit>().deleteRental(rental.id);
              Navigator.pop(ctx);
            },
            child: const Text(
              'حذف نهائي',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

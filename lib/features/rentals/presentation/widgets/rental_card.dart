import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/rental_transaction_model.dart';

class RentalCard extends StatelessWidget {
  final RentalTransaction rental;
  final bool canDelete;
  final VoidCallback onTap;
  final Function(RentalTransaction) onDelete;

  const RentalCard({
    super.key,
    required this.rental,
    required this.onTap,
    required this.onDelete,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeItemsCount = rental.items
        .where((i) => i.status == 'Active')
        .length;
    final totalPaid = rental.payments.fold(0.0, (s, p) => s + p.amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 20,
            bottom: 20,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: rental.isActive ? Colors.green : Colors.grey,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: rental.isActive
                            ? Colors.green.withOpacity(0.08)
                            : Colors.grey.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        rental.isActive ? Icons.engineering : Icons.history,
                        color: rental.isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rental.tenantName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF422712),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: rental.isActive
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  rental.isActive ? 'نشط' : 'مغلق',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: rental.isActive
                                        ? Colors.green.shade800
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (rental.tenantPhone != null &&
                              rental.tenantPhone!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                rental.tenantPhone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _infoLabel(
                                Icons.widgets_outlined,
                                '$activeItemsCount أصناف',
                              ),
                              const SizedBox(width: 12),
                              _infoLabel(
                                Icons.calendar_today,
                                intl.DateFormat(
                                  'MM-dd',
                                ).format(rental.startDate),
                              ),
                              const SizedBox(width: 12),
                              _infoLabel(
                                Icons.payments_outlined,
                                '${totalPaid.toInt()} ج',
                                color: Colors.green.shade600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        onPressed: () => onDelete(rental),
                      ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade300,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLabel(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color ?? Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color ?? Colors.grey[600],
            fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

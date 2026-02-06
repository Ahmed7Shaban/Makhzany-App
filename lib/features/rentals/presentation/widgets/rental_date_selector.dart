import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class RentalDateSelector extends StatelessWidget {
  final DateTime startDate;
  final Function(DateTime) onDateSelected;

  const RentalDateSelector({
    super.key,
    required this.startDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: startDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) onDateSelected(picked);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF553117).withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF553117).withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: Color(0xFF553117)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تاريخ بدء الإيجار',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    intl.DateFormat(
                      'EEEE, d MMMM yyyy',
                      'ar',
                    ).format(startDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.edit_calendar, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

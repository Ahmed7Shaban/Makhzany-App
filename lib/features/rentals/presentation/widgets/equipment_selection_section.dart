import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_state.dart';

class EquipmentSelectionSection extends StatelessWidget {
  final Map<String, int> selectedQuantities;
  final Function(String, int) onQuantityChanged;

  const EquipmentSelectionSection({
    super.key,
    required this.selectedQuantities,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المعدات المطلوبة',
            style: TextStyle(
              color: Color(0xFF553117),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const Text(
            'قم بزيادة الكمية للأصناف التي سيأخذها العميل',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              if (state is InventoryLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is InventoryLoaded) {
                if (state.items.isEmpty) {
                  return const Text('لا يوجد أصناف في المخزن');
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.items.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final currentQty = selectedQuantities[item.id] ?? 0;
                    final isSelected = currentQty > 0;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF553117).withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF553117)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF553117,
                                  ).withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF553117)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.inventory_2_outlined,
                                color: isSelected ? Colors.white : Colors.grey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isSelected
                                          ? const Color(0xFF422712)
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'السعر: ${item.pricePerDay} ج | متاح: ${item.availableQty}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: currentQty > 0
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                  ),
                                  onPressed: currentQty > 0
                                      ? () => onQuantityChanged(
                                          item.id,
                                          currentQty - 1,
                                        )
                                      : null,
                                ),
                                SizedBox(
                                  width: 30,
                                  child: Center(
                                    child: Text(
                                      '$currentQty',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: currentQty < item.availableQty
                                        ? const Color(0xFF553117)
                                        : Colors.grey.shade300,
                                  ),
                                  onPressed: currentQty < item.availableQty
                                      ? () => onQuantityChanged(
                                          item.id,
                                          currentQty + 1,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const Text('خطأ في تحميل المخزن');
            },
          ),
        ],
      ),
    );
  }
}

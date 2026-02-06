import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/rental_item.dart';
import '../cubit/rental_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_state.dart';

class AddItemsBottomSheet extends StatefulWidget {
  final String transactionId;

  const AddItemsBottomSheet({super.key, required this.transactionId});

  @override
  State<AddItemsBottomSheet> createState() => _AddItemsBottomSheetState();
}

class _AddItemsBottomSheetState extends State<AddItemsBottomSheet> {
  DateTime selectedDate = DateTime.now();
  Map<String, int> selectedQtys = {};
  static const primaryBrown = Color(0xFF553117);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryBrown.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: primaryBrown,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
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
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
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
                                  onPressed: () => setState(() {
                                    if (currentQty > 0) {
                                      selectedQtys[item.id] = currentQty - 1;
                                    }
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
                                    ? () => setState(() {
                                        selectedQtys[item.id] = currentQty + 1;
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
                            widget.transactionId,
                            newItems,
                          );
                          Navigator.pop(context);
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
    );
  }
}

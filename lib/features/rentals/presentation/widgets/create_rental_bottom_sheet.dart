import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart' as intl;

import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_state.dart';
import '../../../tenants/data/models/tenant_model.dart';
import '../../../tenants/presentation/cubit/tenant_cubit.dart';
import '../../../tenants/presentation/cubit/tenant_state.dart';
import '../../data/models/rental_item.dart';
import '../../data/models/rental_transaction_model.dart';
import '../cubit/rental_cubit.dart';

class CreateRentalBottomSheet extends StatefulWidget {
  const CreateRentalBottomSheet({super.key});

  @override
  State<CreateRentalBottomSheet> createState() =>
      _CreateRentalBottomSheetState();
}

class _CreateRentalBottomSheetState extends State<CreateRentalBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  // Tenant Form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _hasIdCard = false;
  String? _selectedTenantId;

  // Inventory Selection
  final Map<String, int> _selectedQuantities = {};
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<TenantCubit>().loadTenants();
    context.read<InventoryCubit>().loadInventory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTenantSelected(Tenant? tenant) {
    if (tenant != null) {
      setState(() {
        _selectedTenantId = tenant.id;
        _nameController.text = tenant.name;
        _phoneController.text = tenant.phoneNumber ?? '';
        _addressController.text = tenant.address ?? '';
        _notesController.text = tenant.notes ?? '';
        _hasIdCard = tenant.hasIdCard;
      });
    } else {
      setState(() => _selectedTenantId = null);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final itemsToRent = <RentalItem>[];
      final inventoryState = context.read<InventoryCubit>().state;
      if (inventoryState is! InventoryLoaded) return;

      final inventoryMap = {for (var i in inventoryState.items) i.id: i};
      List<String> errors = [];

      _selectedQuantities.forEach((id, qty) {
        if (qty > 0) {
          final item = inventoryMap[id];
          if (item != null) {
            if (qty > item.availableQty) {
              errors.add("الكمية غير متوفرة للصنف: ${item.name}");
            } else {
              itemsToRent.add(
                RentalItem(
                  itemId: item.id,
                  itemName: item.name,
                  quantity: qty,
                  priceAtMoment: item.pricePerDay,
                  startDate: _startDate,
                ),
              );
            }
          }
        }
      });

      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errors.join('\n'))));
        return;
      }

      if (itemsToRent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب اختيار صنف واحد على الأقل')),
        );
        return;
      }

      final tenantId = _selectedTenantId ?? const Uuid().v4();
      final tenant = Tenant(
        id: tenantId,
        name: _nameController.text,
        phoneNumber: _phoneController.text.isEmpty
            ? null
            : _phoneController.text,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        hasIdCard: _hasIdCard,
      );

      if (_selectedTenantId == null) {
        context.read<TenantCubit>().addTenant(tenant);
      } else {
        context.read<TenantCubit>().addTenant(tenant);
      }

      final transaction = RentalTransaction(
        id: const Uuid().v4(),
        tenantId: tenantId,
        tenantName: tenant.name,
        tenantPhone: tenant.phoneNumber,
        tenantAddress: tenant.address,
        startDate: _startDate,
        items: itemsToRent,
        isActive: true,
      );

      context.read<RentalCubit>().createRental(transaction).then((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إضافة التأجير بنجاح')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
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
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF553117).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart_rounded,
                    color: Color(0xFF553117),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'تأجير جديد للعميل',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF422712),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  // --- Tenant Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بيانات المستأجر',
                          style: TextStyle(
                            color: Color(0xFF553117),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<TenantCubit, TenantState>(
                          builder: (context, state) {
                            if (state is TenantLoaded &&
                                state.tenants.isNotEmpty) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'اختر عيل مسجل (اختياري)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(Icons.person_search),
                                  ),
                                  value: _selectedTenantId,
                                  items: state.tenants
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t.id,
                                          child: Text(t.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (id) {
                                    if (id == null) return;
                                    final tenant = state.tenants.firstWhere(
                                      (t) => t.id == id,
                                    );
                                    _onTenantSelected(tenant);
                                  },
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'اسم العميل',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'يرجى إدخال الاسم' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'رقم التليفون',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: _hasIdCard
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _hasIdCard
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _hasIdCard ? Icons.badge : Icons.no_accounts,
                                  color: _hasIdCard
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                                onPressed: () =>
                                    setState(() => _hasIdCard = !_hasIdCard),
                                tooltip: 'البطاقة الشخصية',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'العنوان',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'ملاحظات إضافية',
                            prefixIcon: const Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF553117).withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF553117).withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: Color(0xFF553117),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تاريخ بدء الإيجار',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  intl.DateFormat(
                                    'EEEE, d MMMM yyyy',
                                    'ar',
                                  ).format(_startDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_calendar,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
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
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (state is InventoryLoaded) {
                              if (state.items.isEmpty)
                                return const Text('لا يوجد أصناف في المخزن');

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.items.length,
                                separatorBuilder: (ctx, i) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = state.items[index];
                                  final currentQty =
                                      _selectedQuantities[item.id] ?? 0;
                                  final isSelected = currentQty > 0;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF553117,
                                            ).withOpacity(0.05)
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              isSelected
                                                  ? Icons.check_circle
                                                  : Icons.inventory_2_outlined,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF422712,
                                                          )
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
                                                    ? () => setState(
                                                        () =>
                                                            _selectedQuantities[item
                                                                    .id] =
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
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.add_circle,
                                                  color:
                                                      currentQty <
                                                          item.availableQty
                                                      ? const Color(0xFF553117)
                                                      : Colors.grey.shade300,
                                                ),
                                                onPressed:
                                                    currentQty <
                                                        item.availableQty
                                                    ? () => setState(
                                                        () =>
                                                            _selectedQuantities[item
                                                                    .id] =
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
                  ),
                ],
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF553117),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'تأكيد وحفظ عملية الإيجار',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

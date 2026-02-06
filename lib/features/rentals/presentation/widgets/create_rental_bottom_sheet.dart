import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_state.dart';
import '../../../tenants/data/models/tenant_model.dart';
import '../../../tenants/presentation/cubit/tenant_cubit.dart';
import '../../data/models/rental_item.dart';
import '../../data/models/rental_transaction_model.dart';
import '../cubit/rental_cubit.dart';
import 'tenant_form_section.dart';
import 'rental_date_selector.dart';
import 'equipment_selection_section.dart';

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
                  TenantFormSection(
                    nameController: _nameController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                    notesController: _notesController,
                    hasIdCard: _hasIdCard,
                    selectedTenantId: _selectedTenantId,
                    onHasIdCardChanged: (v) => setState(() => _hasIdCard = v),
                    onTenantSelected: _onTenantSelected,
                  ),
                  const Divider(height: 1),
                  RentalDateSelector(
                    startDate: _startDate,
                    onDateSelected: (date) => setState(() => _startDate = date),
                  ),
                  const Divider(height: 1),
                  EquipmentSelectionSection(
                    selectedQuantities: _selectedQuantities,
                    onQuantityChanged: (id, qty) =>
                        setState(() => _selectedQuantities[id] = qty),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart' as intl;

// Cubits
import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_state.dart';
import '../../../tenants/presentation/cubit/tenant_cubit.dart';
import '../../../tenants/presentation/cubit/tenant_state.dart';
import '../cubit/rental_cubit.dart';

// Models
import '../../../inventory/data/models/inventory_item.dart';
import '../../../tenants/data/models/tenant_model.dart';
import '../../data/models/rental_transaction_model.dart';
import '../../data/models/rental_item.dart';

class CreateRentalScreen extends StatefulWidget {
  const CreateRentalScreen({super.key});

  @override
  State<CreateRentalScreen> createState() => _CreateRentalScreenState();
}

class _CreateRentalScreenState extends State<CreateRentalScreen> {
  Tenant? _selectedTenant;
  final List<RentalItemDraft> _cart = [];
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<TenantCubit>().loadTenants();
    context.read<InventoryCubit>().loadInventory();
  }

  void _addItemToCart(InventoryItem item) {
    if (item.availableQty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('نقدت الكمية!')));
      return;
    }
    setState(() {
      // Check if already in cart
      final existingIndex = _cart.indexWhere(
        (element) => element.item.id == item.id,
      );
      if (existingIndex != -1) {
        // Already added, maybe create a warning or just ignore
      } else {
        _cart.add(RentalItemDraft(item: item, quantity: 1));
      }
    });
  }

  void _submitRental() {
    if (_selectedTenant == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار مستأجر')));
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('السلة فارغة')));
      return;
    }

    final rentalItems = _cart.map((draft) {
      return RentalItem(
        itemId: draft.item.id,
        itemName: draft.item.name,
        quantity: draft.quantity,
        priceAtMoment: draft.item.pricePerDay,
        startDate: _startDate,
      );
    }).toList();

    final transaction = RentalTransaction(
      id: const Uuid().v4(),
      tenantId: _selectedTenant!.id,
      tenantName: _selectedTenant!.name,
      startDate: _startDate,
      items: rentalItems,
      isActive: true,
    );

    context.read<RentalCubit>().createRental(transaction).then((_) {
      Navigator.pop(context); // Close screen
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تسجيل الإيجار بنجاح')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأجير جديد')),
      body: Column(
        children: [
          // 1. Tenant Selector
          _buildTenantSelector(),

          // 2. Date Picker (Default Today)
          ListTile(
            title: const Text('تاريخ البدء'),
            subtitle: Text(intl.DateFormat('yyyy-MM-dd').format(_startDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
          ),

          const Divider(),

          // 3. Cart Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الأصناف في السلة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.orange,
                    size: 30,
                  ),
                  onPressed: () => _showInventoryDialog(),
                ),
              ],
            ),
          ),

          // 4. Cart List
          Expanded(
            child: ListView.builder(
              itemCount: _cart.length,
              itemBuilder: (context, index) {
                final draft = _cart[index];
                return _buildCartItem(draft, index);
              },
            ),
          ),

          // 5. Submit Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitRental,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('إتمام التأجير'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantSelector() {
    return BlocBuilder<TenantCubit, TenantState>(
      builder: (context, state) {
        List<Tenant> tenants = [];
        if (state is TenantLoaded) tenants = state.tenants;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Tenant>(
                  decoration: const InputDecoration(labelText: 'اختر المستأجر'),
                  value: _selectedTenant,
                  items: tenants
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedTenant = val),
                  validator: (v) => v == null ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => _showAddTenantDialog(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItem(RentalItemDraft draft, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${draft.item.availableQty} متاح',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (draft.quantity > 1) setState(() => draft.quantity--);
                    },
                  ),
                  Text('${draft.quantity}'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (draft.quantity < draft.item.availableQty)
                        setState(() => draft.quantity++);
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _cart.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }

  void _showInventoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر صنف'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: BlocBuilder<InventoryCubit, InventoryState>(
              builder: (context, state) {
                if (state is InventoryLoaded) {
                  return ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      // Don't show items already in cart
                      if (_cart.any((d) => d.item.id == item.id))
                        return const SizedBox.shrink();

                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('متاح: ${item.availableQty}'),
                        enabled: item.availableQty > 0,
                        onTap: () {
                          _addItemToCart(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTenantDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final idCardCtrl = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة مستأجر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'الهاتف'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: idCardCtrl,
              builder: (ctx, val, _) => SwitchListTile(
                title: const Text('تم استلام البطاقة'),
                value: val,
                onChanged: (v) => idCardCtrl.value = v,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final newTenant = Tenant(
                  id: const Uuid().v4(),
                  name: nameCtrl.text,
                  phoneNumber: phoneCtrl.text,
                  hasIdCard: idCardCtrl.value,
                );
                context.read<TenantCubit>().addTenant(newTenant);
                Navigator.pop(context);
                // Ideally default select this new tenant, but keeping simple
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class RentalItemDraft {
  final InventoryItem item;
  int quantity;

  RentalItemDraft({required this.item, required this.quantity});
}

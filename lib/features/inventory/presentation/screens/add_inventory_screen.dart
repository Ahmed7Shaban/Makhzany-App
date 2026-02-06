import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/inventory_item.dart';
import '../cubit/inventory_cubit.dart';

class AddInventoryScreen extends StatefulWidget {
  final InventoryItem? itemToEdit;
  const AddInventoryScreen({super.key, this.itemToEdit});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.itemToEdit?.name ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.itemToEdit?.category ?? '',
    );
    _qtyController = TextEditingController(
      text: widget.itemToEdit?.totalQty.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.itemToEdit?.pricePerDay.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final category = _categoryController.text;
      final int totalQty = int.parse(_qtyController.text);
      final double price = double.parse(_priceController.text);

      if (widget.itemToEdit != null) {
        // Update Logic
        final oldTotal = widget.itemToEdit!.totalQty;
        final difference = totalQty - oldTotal;

        final updatedItem = widget.itemToEdit!.copyWith(
          name: name,
          category: category,
          totalQty: totalQty,
          availableQty: widget.itemToEdit!.availableQty + difference,
          pricePerDay: price,
        );

        if (updatedItem.availableQty < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطأ: الكمية المتاحة ستصبح أقل من صفر'),
            ),
          );
          return;
        }

        context.read<InventoryCubit>().updateItem(updatedItem);
      } else {
        // Create Logic
        final newItem = InventoryItem(
          id: const Uuid().v4(),
          name: name,
          category: category,
          totalQty: totalQty,
          availableQty: totalQty,
          pricePerDay: price,
        );
        context.read<InventoryCubit>().addItem(newItem);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل صنف' : 'إضافة صنف جديد')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الصنف (مثال: سقالة)',
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'الفئة (مثال: معدات خشبية)',
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'العدد الكلي'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'سعر اليوم (ج.م)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة للمخزن'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

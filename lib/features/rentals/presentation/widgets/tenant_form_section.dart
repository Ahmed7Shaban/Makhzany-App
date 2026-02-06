import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../tenants/data/models/tenant_model.dart';
import '../../../tenants/presentation/cubit/tenant_cubit.dart';
import '../../../tenants/presentation/cubit/tenant_state.dart';

class TenantFormSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController notesController;
  final bool hasIdCard;
  final String? selectedTenantId;
  final Function(bool) onHasIdCardChanged;
  final Function(Tenant?) onTenantSelected;

  const TenantFormSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.notesController,
    required this.hasIdCard,
    required this.selectedTenantId,
    required this.onHasIdCardChanged,
    required this.onTenantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              if (state is TenantLoaded && state.tenants.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'اختر عميل مسجل (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person_search),
                    ),
                    value: selectedTenantId,
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
                      onTenantSelected(tenant);
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'اسم العميل',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            validator: (v) => v!.isEmpty ? 'يرجى إدخال الاسم' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: phoneController,
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
                  color: hasIdCard ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasIdCard
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    hasIdCard ? Icons.badge : Icons.no_accounts,
                    color: hasIdCard
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                  onPressed: () => onHasIdCardChanged(!hasIdCard),
                  tooltip: 'البطاقة الشخصية',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: addressController,
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
            controller: notesController,
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
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../models/tenant_model.dart';

class TenantRepository {
  final _supabase = Supabase.instance.client;
  final String _tableName = 'tenants';

  Box<Tenant> get _box => Hive.box<Tenant>(HiveBoxes.tenantsBox);

  /// For backward compatibility
  List<Tenant> getTenants() {
    return _box.values.toList();
  }

  Stream<List<Tenant>> getTenantsStream() async* {
    yield _box.values.toList();

    try {
      final response = await _supabase.from(_tableName).select();
      final List<Tenant> remoteItems = (response as List)
          .map((data) => Tenant.fromJson(data))
          .toList();

      await _box.clear();
      for (var item in remoteItems) {
        await _box.put(item.id, item);
      }

      yield remoteItems;
    } catch (e) {
      print('Error fetching tenants from Supabase: $e');
    }
  }

  Future<void> addTenant(Tenant tenant) async {
    try {
      await _supabase.from(_tableName).insert(tenant.toJson());
      await _box.put(tenant.id, tenant);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      await _supabase
          .from(_tableName)
          .update(tenant.toJson())
          .eq('id', tenant.id);
      await _box.put(tenant.id, tenant);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
      await _box.delete(id);
    } catch (e) {
      rethrow;
    }
  }
}

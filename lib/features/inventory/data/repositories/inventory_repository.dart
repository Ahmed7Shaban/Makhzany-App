import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../models/inventory_item.dart';

class InventoryRepository {
  final _supabase = Supabase.instance.client;
  final String _tableName = 'inventory';

  Box<InventoryItem> get _box =>
      Hive.box<InventoryItem>(HiveBoxes.inventoryBox);

  /// For backward compatibility with existing Cubits
  List<InventoryItem> getInventory() {
    return _box.values.toList();
  }

  /// Offline-First Stream: Emits Hive data first, then Supabase data
  Stream<List<InventoryItem>> getInventoryStream() async* {
    // 1. Emit local data immediately
    yield _box.values.toList();

    try {
      // 2. Fetch from Supabase
      final response = await _supabase.from(_tableName).select();
      final List<InventoryItem> remoteItems = (response as List)
          .map((data) => InventoryItem.fromJson(data))
          .toList();

      // 3. Update Hive if changed (simplistic sync)
      await _box.clear();
      for (var item in remoteItems) {
        await _box.put(item.id, item);
      }

      // 4. Re-emit updated local data
      yield remoteItems;
    } catch (e) {
      print('Error fetching inventory from Supabase: $e');
    }
  }

  Future<void> addItem(InventoryItem item) async {
    try {
      await _supabase.from(_tableName).insert(item.toJson());
      await _box.put(item.id, item);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateItem(InventoryItem item) async {
    try {
      await _supabase.from(_tableName).update(item.toJson()).eq('id', item.id);
      await _box.put(item.id, item);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
      await _box.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  bool hasSufficientStock(String itemId, int requestedQty) {
    final item = _box.get(itemId);
    if (item == null) return false;
    return item.availableQty >= requestedQty;
  }
}

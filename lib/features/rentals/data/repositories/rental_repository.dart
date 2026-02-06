import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../models/rental_transaction_model.dart';

class RentalRepository {
  final _supabase = Supabase.instance.client;
  final String _tableName = 'rentals';

  Box<RentalTransaction> get _box =>
      Hive.box<RentalTransaction>(HiveBoxes.rentalsBox);

  /// For backward compatibility
  List<RentalTransaction> getRentals() {
    return _box.values.toList();
  }

  /// Aliases for backward compatibility
  Future<void> addRental(RentalTransaction rental) => addTransaction(rental);
  Future<void> updateRental(RentalTransaction rental) =>
      updateTransaction(rental);
  Future<void> deleteRental(String id) => deleteTransaction(id);

  Stream<List<RentalTransaction>> getRentalsStream() async* {
    yield _box.values.toList();

    try {
      final response = await _supabase.from(_tableName).select();
      final List<RentalTransaction> remoteItems = (response as List)
          .map((data) => RentalTransaction.fromJson(data))
          .toList();

      await _box.clear();
      for (var item in remoteItems) {
        await _box.put(item.id, item);
      }

      yield remoteItems;
    } catch (e) {
      print('Error fetching rentals from Supabase: $e');
    }
  }

  Future<void> addTransaction(RentalTransaction transaction) async {
    try {
      await _supabase.from(_tableName).insert(transaction.toJson());
      await _box.put(transaction.id, transaction);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransaction(RentalTransaction transaction) async {
    try {
      await _supabase
          .from(_tableName)
          .update(transaction.toJson())
          .eq('id', transaction.id);
      await _box.put(transaction.id, transaction);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
      await _box.delete(id);
    } catch (e) {
      rethrow;
    }
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/inventory_item.dart';
import '../../data/repositories/inventory_repository.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _repository;
  StreamSubscription? _subscription;

  InventoryCubit(this._repository) : super(InventoryInitial());

  Future<void> loadInventory() async {
    emit(InventoryLoading());
    await _subscription?.cancel();
    _subscription = _repository.getInventoryStream().listen(
      (items) {
        if (!isClosed) emit(InventoryLoaded(items));
      },
      onError: (e) {
        if (!isClosed) emit(InventoryError("Failed to load inventory: $e"));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> addItem(InventoryItem item) async {
    try {
      await _repository.addItem(item);
      loadInventory();
    } catch (e) {
      emit(InventoryError("Failed to add item: $e"));
    }
  }

  Future<void> updateItem(InventoryItem item) async {
    try {
      await _repository.updateItem(item);
      loadInventory();
    } catch (e) {
      emit(InventoryError("Failed to update item: $e"));
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _repository.deleteItem(id);
      loadInventory();
    } catch (e) {
      emit(InventoryError("Failed to delete item: $e"));
    }
  }
}

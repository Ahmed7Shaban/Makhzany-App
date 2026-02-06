import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/rental_transaction_model.dart';
import '../../data/models/rental_item.dart';
import '../../data/models/payment_log_model.dart';
import '../../data/models/financial_record_model.dart';
import '../../data/repositories/rental_repository.dart';
import '../../../inventory/data/repositories/inventory_repository.dart';
import 'rental_state.dart';

class RentalCubit extends Cubit<RentalState> {
  final RentalRepository _rentalRepository;
  final InventoryRepository _inventoryRepository;
  StreamSubscription? _subscription;

  RentalCubit(this._rentalRepository, this._inventoryRepository)
    : super(RentalInitial());

  Future<void> loadRentals() async {
    emit(RentalLoading());
    await _subscription?.cancel();
    _subscription = _rentalRepository.getRentalsStream().listen(
      (rentals) {
        final sorted = List<RentalTransaction>.from(rentals)
          ..sort((a, b) => b.startDate.compareTo(a.startDate));
        if (!isClosed) emit(RentalLoaded(sorted));
      },
      onError: (e) {
        if (!isClosed) emit(RentalError("Failed to load rentals: $e"));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> createRental(RentalTransaction transaction) async {
    emit(RentalLoading());
    try {
      for (var item in transaction.items) {
        if (!_inventoryRepository.hasSufficientStock(
          item.itemId,
          item.quantity,
        )) {
          throw Exception("Insufficient stock for ${item.itemName}");
        }
      }

      for (var item in transaction.items) {
        final inventoryItem = _inventoryRepository.getInventory().firstWhere(
          (i) => i.id == item.itemId,
        );
        inventoryItem.availableQty -= item.quantity;
        await _inventoryRepository.updateItem(inventoryItem);
      }

      await _rentalRepository.addRental(transaction);
      loadRentals();
    } catch (e) {
      emit(RentalError(e.toString()));
      loadRentals();
    }
  }

  Future<void> settleAccount(
    String transactionId,
    DateTime settlementDate,
  ) async {
    emit(RentalLoading());
    try {
      final transaction = _rentalRepository.getRentals().firstWhere(
        (r) => r.id == transactionId,
      );

      double unbilled = transaction.calculateUnbilledAmount(settlementDate);

      if (unbilled >= 0) {
        final record = FinancialRecord(
          amount: unbilled,
          date: settlementDate,
          periodStar: transaction.lastSettlementDate ?? transaction.startDate,
          periodEnd: settlementDate,
          note: "تصفية حساب",
        );
        transaction.invoices.add(record);
        transaction.lastSettlementDate = settlementDate;
        await _rentalRepository.updateTransaction(transaction);
      }
      loadRentals();
    } catch (e) {
      emit(RentalError("Settlement failed: $e"));
      loadRentals();
    }
  }

  Future<void> returnItemsPartial(
    String transactionId,
    RentalItem item,
    int returnQty,
    DateTime returnDate,
  ) async {
    emit(RentalLoading());
    try {
      final transaction = _rentalRepository.getRentals().firstWhere(
        (r) => r.id == transactionId,
      );

      if (returnQty > item.quantity) {
        throw Exception("Cannot return more than rented quantity");
      }

      final inventoryItem = _inventoryRepository.getInventory().firstWhere(
        (i) => i.id == item.itemId,
      );

      if (returnQty == item.quantity) {
        item.status = 'Returned';
        item.returnDate = returnDate;
        inventoryItem.availableQty += returnQty;
      } else {
        transaction.items.remove(item);

        final remainingItem = RentalItem(
          itemId: item.itemId,
          itemName: item.itemName,
          quantity: item.quantity - returnQty,
          priceAtMoment: item.priceAtMoment,
          startDate: item.startDate,
          status: 'Active',
        );

        final returnedItem = RentalItem(
          itemId: item.itemId,
          itemName: item.itemName,
          quantity: returnQty,
          priceAtMoment: item.priceAtMoment,
          startDate: item.startDate,
          status: 'Returned',
          returnDate: returnDate,
        );

        transaction.items.add(remainingItem);
        transaction.items.add(returnedItem);
        inventoryItem.availableQty += returnQty;
      }

      await _inventoryRepository.updateItem(inventoryItem);
      await _rentalRepository.updateTransaction(transaction);
      loadRentals();
    } catch (e) {
      emit(RentalError("Return failed: $e"));
      loadRentals();
    }
  }

  Future<void> addExtraItems(
    String transactionId,
    List<RentalItem> newItems,
  ) async {
    emit(RentalLoading());
    try {
      final transaction = _rentalRepository.getRentals().firstWhere(
        (r) => r.id == transactionId,
      );

      for (var item in newItems) {
        if (!_inventoryRepository.hasSufficientStock(
          item.itemId,
          item.quantity,
        )) {
          throw Exception("Insufficient stock for ${item.itemName}");
        }
        final inventoryItem = _inventoryRepository.getInventory().firstWhere(
          (i) => i.id == item.itemId,
        );
        inventoryItem.availableQty -= item.quantity;
        await _inventoryRepository.updateItem(inventoryItem);
      }

      transaction.items.addAll(newItems);
      await _rentalRepository.updateTransaction(transaction);
      loadRentals();
    } catch (e) {
      emit(RentalError("Add items failed: $e"));
      loadRentals();
    }
  }

  Future<void> addPayment(String transactionId, PaymentLog payment) async {
    emit(RentalLoading());
    try {
      final transaction = _rentalRepository.getRentals().firstWhere(
        (r) => r.id == transactionId,
      );
      transaction.payments.add(payment);
      await _rentalRepository.updateTransaction(transaction);
      loadRentals();
    } catch (e) {
      emit(RentalError("Payment failed: $e"));
      loadRentals();
    }
  }

  Future<void> closeRental(
    RentalTransaction transaction,
    DateTime endDate,
  ) async {
    emit(RentalLoading());
    try {
      double unbilled = transaction.calculateUnbilledAmount(endDate);
      if (unbilled > 0) {
        final record = FinancialRecord(
          amount: unbilled,
          date: endDate,
          periodStar: transaction.lastSettlementDate ?? transaction.startDate,
          periodEnd: endDate,
          note: "تصفية نهائية (إغلاق)",
        );
        transaction.invoices.add(record);
        transaction.lastSettlementDate = endDate;
      }

      for (var item in List<RentalItem>.from(transaction.items)) {
        if (item.status == 'Active') {
          transaction.items.remove(item);
          final returnedItem = RentalItem(
            itemId: item.itemId,
            itemName: item.itemName,
            quantity: item.quantity,
            priceAtMoment: item.priceAtMoment,
            startDate: item.startDate,
            returnDate: endDate,
            status: 'Returned',
          );
          transaction.items.add(returnedItem);

          try {
            final inventoryItem = _inventoryRepository
                .getInventory()
                .firstWhere((i) => i.id == item.itemId);
            inventoryItem.availableQty += item.quantity;
            await _inventoryRepository.updateItem(inventoryItem);
          } catch (_) {}
        }
      }

      transaction.endDate = endDate;
      transaction.isActive = false;
      await _rentalRepository.updateTransaction(transaction);
      loadRentals();
    } catch (e) {
      emit(RentalError("Close failed: $e"));
      loadRentals();
    }
  }

  Future<void> updateTransactionHeader({
    required String transactionId,
    required String name,
    required String? phone,
    required String? address,
    required bool discountFridays,
  }) async {
    emit(RentalLoading());
    try {
      final transaction = _rentalRepository.getRentals().firstWhere(
        (r) => r.id == transactionId,
      );

      transaction.tenantName = name;
      transaction.tenantPhone = phone;
      transaction.tenantAddress = address;
      transaction.discountFridays = discountFridays;

      await _rentalRepository.updateTransaction(transaction);
      loadRentals();
    } catch (e) {
      emit(RentalError("Failed to update header: $e"));
      loadRentals();
    }
  }

  Future<void> updateItemPriceOrQuantity({
    required String transactionId,
    required String itemId,
    double? newPrice,
    int? newQuantity,
  }) async {
    emit(RentalLoading());
    try {
      final transaction = _rentalRepository.getRentals().firstWhere(
        (r) => r.id == transactionId,
      );

      final item = transaction.items.firstWhere(
        (i) => i.itemId == itemId && i.status == 'Active',
      );

      if (newPrice != null) {
        item.priceAtMoment = newPrice;
      }

      if (newQuantity != null && newQuantity != item.quantity) {
        final inventoryItem = _inventoryRepository.getInventory().firstWhere(
          (i) => i.id == itemId,
        );

        final difference = newQuantity - item.quantity;

        if (difference > 0) {
          if (!_inventoryRepository.hasSufficientStock(itemId, difference)) {
            throw Exception("Insufficient stock in inventory");
          }
          inventoryItem.availableQty -= difference;
        } else {
          inventoryItem.availableQty += difference.abs();
        }

        item.quantity = newQuantity;
        await _inventoryRepository.updateItem(inventoryItem);
      }

      await _rentalRepository.updateTransaction(transaction);
      loadRentals();
    } catch (e) {
      emit(RentalError("Update failed: $e"));
      loadRentals();
    }
  }

  Future<void> deleteRental(String id) async {
    emit(RentalLoading());
    try {
      final rental = _rentalRepository.getRentals().firstWhere(
        (r) => r.id == id,
      );

      if (rental.isActive) {
        for (var item in rental.items) {
          if (item.status == 'Active') {
            try {
              final inventoryItem = _inventoryRepository
                  .getInventory()
                  .firstWhere((i) => i.id == item.itemId);
              inventoryItem.availableQty += item.quantity;
              await _inventoryRepository.updateItem(inventoryItem);
            } catch (_) {}
          }
        }
      }

      await _rentalRepository.deleteRental(id);
      loadRentals();
    } catch (e) {
      emit(RentalError("Failed to delete rental: $e"));
      loadRentals();
    }
  }
}

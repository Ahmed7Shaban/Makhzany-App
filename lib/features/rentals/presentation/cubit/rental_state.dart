import 'package:equatable/equatable.dart';

// Fix relative path if previous file structure assumption was wrong.
// Path: lib/features/rentals/presentation/cubit/rental_state.dart
import '../../data/models/rental_transaction_model.dart';

abstract class RentalState extends Equatable {
  const RentalState();
  @override
  List<Object> get props => [];
}

class RentalInitial extends RentalState {}

class RentalLoading extends RentalState {}

class RentalLoaded extends RentalState {
  final List<RentalTransaction> rentals;
  const RentalLoaded(this.rentals);
  @override
  List<Object> get props => [rentals];
}

class RentalError extends RentalState {
  final String message;
  const RentalError(this.message);
  @override
  List<Object> get props => [message];
}

class RentalSuccess extends RentalState {
  // Transient state for success actions like "Rental Created" to trigger UI events
  // But standard loaded is often better. I will stick to Loaded.
}

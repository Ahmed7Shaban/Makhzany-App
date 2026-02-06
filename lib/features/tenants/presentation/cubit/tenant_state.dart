import 'package:equatable/equatable.dart';
import '../../data/models/tenant_model.dart';

abstract class TenantState extends Equatable {
  const TenantState();
  @override
  List<Object> get props => [];
}

class TenantInitial extends TenantState {}

class TenantLoading extends TenantState {}

class TenantLoaded extends TenantState {
  final List<Tenant> tenants;
  const TenantLoaded(this.tenants);
  @override
  List<Object> get props => [tenants];
}

class TenantError extends TenantState {
  final String message;
  const TenantError(this.message);
  @override
  List<Object> get props => [message];
}

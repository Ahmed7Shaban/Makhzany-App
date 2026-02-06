import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/tenant_model.dart';
import '../../data/repositories/tenant_repository.dart';
import 'tenant_state.dart';

class TenantCubit extends Cubit<TenantState> {
  final TenantRepository _repository;
  StreamSubscription? _subscription;

  TenantCubit(this._repository) : super(TenantInitial());

  Future<void> loadTenants() async {
    emit(TenantLoading());
    await _subscription?.cancel();
    _subscription = _repository.getTenantsStream().listen(
      (tenants) {
        if (!isClosed) emit(TenantLoaded(tenants));
      },
      onError: (e) {
        if (!isClosed) emit(TenantError("Failed to load tenants: $e"));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> addTenant(Tenant tenant) async {
    try {
      await _repository.addTenant(tenant);
      loadTenants();
    } catch (e) {
      emit(TenantError("Failed to add tenant: $e"));
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      await _repository.updateTenant(tenant);
      loadTenants();
    } catch (e) {
      emit(TenantError("Failed to update tenant: $e"));
    }
  }
}

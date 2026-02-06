import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/hive_boxes.dart';
import 'core/localization/arabic_material_localizations.dart';

// Models
import 'features/inventory/data/models/inventory_item.dart';
import 'features/tenants/data/models/tenant_model.dart';
import 'features/rentals/data/models/rental_transaction_model.dart';
import 'features/rentals/data/models/rental_item.dart';
import 'features/rentals/data/models/payment_log_model.dart';
import 'features/rentals/data/models/financial_record_model.dart';

// Repositories
import 'features/inventory/data/repositories/inventory_repository.dart';
import 'features/tenants/data/repositories/tenant_repository.dart';
import 'features/rentals/data/repositories/rental_repository.dart';

// Cubits
import 'features/inventory/presentation/cubit/inventory_cubit.dart';
import 'features/tenants/presentation/cubit/tenant_cubit.dart';
import 'features/rentals/presentation/cubit/rental_cubit.dart';

// Screens
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase
  await Supabase.initialize(
    url: 'https://zrvnmfroramwtmddvfgy.supabase.co',
    anonKey:
        'sb_publishable_fzo0TJGIzdeFDI1xG836fQ_GokDwnH4', // Note: Ensure this is the correct Anon Key from Supabase dashboard
  );

  // 2. Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(InventoryItemAdapter());
  Hive.registerAdapter(TenantAdapter());
  Hive.registerAdapter(RentalTransactionAdapter());
  Hive.registerAdapter(RentalItemAdapter());
  Hive.registerAdapter(PaymentLogAdapter());
  Hive.registerAdapter(FinancialRecordAdapter());

  // Open Boxes
  await Hive.openBox<InventoryItem>(HiveBoxes.inventoryBox);
  await Hive.openBox<Tenant>(HiveBoxes.tenantsBox);
  await Hive.openBox<RentalTransaction>(HiveBoxes.rentalsBox);
  // RentalItem is inside Transaction, usually doesn't need own box unless independent query needed.

  runApp(const MakhzaniApp());
}

class MakhzaniApp extends StatelessWidget {
  const MakhzaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate Repositories
    final inventoryRepo = InventoryRepository();
    final tenantRepo = TenantRepository();
    final rentalRepo = RentalRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => InventoryCubit(inventoryRepo)..loadInventory(),
        ),
        BlocProvider(
          create: (context) => TenantCubit(tenantRepo)..loadTenants(),
        ),
        BlocProvider(
          create: (context) =>
              RentalCubit(rentalRepo, inventoryRepo)..loadRentals(),
        ),
      ],
      child: MaterialApp(
        title: 'مخزني',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          ArabicFullDaysMaterialLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        home: const DashboardScreen(),
      ),
    );
  }
}

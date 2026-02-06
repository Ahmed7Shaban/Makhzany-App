import 'package:hive/hive.dart';
import 'rental_item.dart';
import 'payment_log_model.dart';
import 'financial_record_model.dart';

part 'rental_transaction_model.g.dart';

@HiveType(typeId: 2)
class RentalTransaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tenantId;

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  DateTime? endDate;

  @HiveField(4)
  bool isActive;

  @HiveField(5)
  late List<RentalItem> items; // Made mutable for editing

  // @HiveField(6) totalCost - REMOVED

  @HiveField(7)
  String tenantName;

  @HiveField(8)
  String? tenantPhone; // Store snapshot

  @HiveField(9)
  String? tenantAddress; // Store snapshot

  @HiveField(10)
  bool discountFridays; // Store status

  @HiveField(11)
  List<PaymentLog> payments;

  @HiveField(12)
  DateTime? lastSettlementDate;

  @HiveField(13)
  List<FinancialRecord> invoices;

  RentalTransaction({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.startDate,
    required this.items,
    this.isActive = true,
    this.endDate,
    this.tenantPhone,
    this.tenantAddress,
    this.discountFridays = false,
    List<PaymentLog>? payments,
    List<FinancialRecord>? invoices,
    this.lastSettlementDate,
  }) : payments = payments ?? [],
       invoices = invoices ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'items': items.map((e) => e.toJson()).toList(),
      'tenantPhone': tenantPhone,
      'tenantAddress': tenantAddress,
      'discountFridays': discountFridays,
      'payments': payments.map((e) => e.toJson()).toList(),
      'lastSettlementDate': lastSettlementDate?.toIso8601String(),
      'invoices': invoices.map((e) => e.toJson()).toList(),
    };
  }

  factory RentalTransaction.fromJson(Map<String, dynamic> json) {
    return RentalTransaction(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      tenantName: json['tenantName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => RentalItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tenantPhone: json['tenantPhone'] as String?,
      tenantAddress: json['tenantAddress'] as String?,
      discountFridays: json['discountFridays'] as bool? ?? false,
      payments:
          (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastSettlementDate: json['lastSettlementDate'] != null
          ? DateTime.parse(json['lastSettlementDate'] as String)
          : null,
      invoices:
          (json['invoices'] as List<dynamic>?)
              ?.map((e) => FinancialRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Updates basic transaction info (Header)
  void updateHeaderInfo({
    String? name,
    String? phone,
    String? address,
    bool? discount,
  }) {
    if (name != null) tenantName = name;
    if (phone != null) tenantPhone = phone;
    if (address != null) tenantAddress = address;
    if (discount != null) discountFridays = discount;
  }

  /// Calculates the Unbilled Amount (Current Usage since last settlement)
  double calculateUnbilledAmount(DateTime calculationDate) {
    if (items.isEmpty) return 0.0;

    // Safety check
    DateTime effectiveCalcDate = calculationDate.isBefore(startDate)
        ? startDate
        : calculationDate;
    DateTime limitDate = (!isActive && endDate != null)
        ? endDate!
        : effectiveCalcDate;

    double total = 0.0;
    for (var item in items) {
      DateTime effectiveStart = item.startDate;
      if (lastSettlementDate != null &&
          lastSettlementDate!.isAfter(effectiveStart)) {
        effectiveStart = lastSettlementDate!;
      }

      DateTime effectiveEnd =
          (item.status == 'Returned' && item.returnDate != null)
          ? item.returnDate!
          : limitDate;

      // 4. Calculate Days
      // Normalize to dates to avoid time issues
      final s = DateTime(
        effectiveStart.year,
        effectiveStart.month,
        effectiveStart.day,
      );
      final e = DateTime(
        effectiveEnd.year,
        effectiveEnd.month,
        effectiveEnd.day,
      );

      // NO Double Charging Logic
      bool isContinuation =
          lastSettlementDate != null &&
          (lastSettlementDate!.isAfter(item.startDate) ||
              lastSettlementDate!.isAtSameMomentAs(item.startDate));

      int daysDiff = e.difference(s).inDays;
      int days = isContinuation ? daysDiff : daysDiff + 1;
      if (days < 0) days = 0;

      // Friday Logic
      if (discountFridays && days > 0) {
        int fridays = 0;
        for (int i = 0; i < days; i++) {
          DateTime checkDate = s.add(
            Duration(days: isContinuation ? i + 1 : i),
          );
          if (checkDate.isAfter(e)) break;
          if (checkDate.weekday == DateTime.friday) fridays++;
        }
        days -= fridays;
      }

      total += (item.quantity * item.priceAtMoment * days);
    }
    return total;
  }

  /// Total Due = Sum(Invoices) + Unbilled Amount
  double calculateTotalDue(DateTime calculationDate) {
    double invoicesTotal = invoices.fold(0.0, (sum, inv) => sum + inv.amount);
    double unbilled = calculateUnbilledAmount(calculationDate);
    return invoicesTotal + unbilled;
  }

  /// Balance = Total Due - Payments
  double calculateBalance(DateTime calculationDate) {
    double due = calculateTotalDue(calculationDate);
    double paid = payments.fold(0.0, (sum, p) => sum + p.amount);
    return due - paid;
  }

  /// Counts total Fridays discounted across all items for the unbilled period
  int calculateTotalUnbilledFridays(DateTime calculationDate) {
    if (!discountFridays || items.isEmpty) return 0;
    int totalFridays = 0;

    DateTime effectiveCalcDate = calculationDate.isBefore(startDate)
        ? startDate
        : calculationDate;
    DateTime limitDate = (!isActive && endDate != null)
        ? endDate!
        : effectiveCalcDate;

    for (var item in items) {
      DateTime effectiveStart = item.startDate;
      if (lastSettlementDate != null &&
          lastSettlementDate!.isAfter(effectiveStart)) {
        effectiveStart = lastSettlementDate!;
      }

      DateTime effectiveEnd =
          (item.status == 'Returned' && item.returnDate != null)
          ? item.returnDate!
          : limitDate;

      final s = DateTime(
        effectiveStart.year,
        effectiveStart.month,
        effectiveStart.day,
      );
      final e = DateTime(
        effectiveEnd.year,
        effectiveEnd.month,
        effectiveEnd.day,
      );

      bool isContinuation =
          lastSettlementDate != null &&
          (lastSettlementDate!.isAfter(item.startDate) ||
              lastSettlementDate!.isAtSameMomentAs(item.startDate));

      int daysDiff = e.difference(s).inDays;
      int days = isContinuation ? daysDiff : daysDiff + 1;

      if (days > 0) {
        for (int i = 0; i < days; i++) {
          DateTime checkDate = s.add(
            Duration(days: isContinuation ? i + 1 : i),
          );
          if (checkDate.isAfter(e)) break;
          if (checkDate.weekday == DateTime.friday) totalFridays++;
        }
      }
    }
    return totalFridays;
  }
}

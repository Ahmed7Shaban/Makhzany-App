import 'package:hive/hive.dart';

part 'rental_item.g.dart';

@HiveType(typeId: 3)
class RentalItem extends HiveObject {
  @HiveField(0)
  final String itemId;

  @HiveField(1)
  final String itemName;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  double priceAtMoment;

  @HiveField(4)
  final DateTime startDate;

  @HiveField(5)
  DateTime? returnDate;

  @HiveField(6)
  String status; // 'Active' or 'Returned'

  RentalItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.priceAtMoment,
    required this.startDate,
    this.returnDate,
    this.status = 'Active',
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'priceAtMoment': priceAtMoment,
      'startDate': startDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'status': status,
    };
  }

  factory RentalItem.fromJson(Map<String, dynamic> json) {
    return RentalItem(
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int,
      priceAtMoment: (json['priceAtMoment'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'] as String)
          : null,
      status: json['status'] as String? ?? 'Active',
    );
  }

  // Helper to calculate days for this specific item
  int calculateDays(
    DateTime calculationEndDate, {
    bool excludeFridays = false,
  }) {
    final end = status == 'Returned' && returnDate != null
        ? returnDate!
        : calculationEndDate;

    // Normalize
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(end.year, end.month, end.day);

    int days = e.difference(s).inDays + 1; // Inclusive

    if (excludeFridays) {
      int fridays = 0;
      for (int i = 0; i < days; i++) {
        if (s.add(Duration(days: i)).weekday == DateTime.friday) {
          fridays++;
        }
      }
      days -= fridays;
    }

    return days < 0 ? 0 : days;
  }

  DayBreakdown calculateDetailedDays(
    DateTime calculationEndDate, {
    bool excludeFridays = false,
    DateTime? alternativeStartDate,
  }) {
    final end = status == 'Returned' && returnDate != null
        ? returnDate!
        : calculationEndDate;

    final baseStart = alternativeStartDate ?? startDate;

    final s = DateTime(baseStart.year, baseStart.month, baseStart.day);
    final e = DateTime(end.year, end.month, end.day);

    // If it's a continuation, we start from the day AFTER the last settlement
    // to avoid double charging the settlement day.
    // However, if it's the original start, we include the start day.
    bool isContinuation = alternativeStartDate != null;

    int totalDaysDiff = e.difference(s).inDays;
    int totalDays = isContinuation ? totalDaysDiff : totalDaysDiff + 1;

    if (totalDays < 0) totalDays = 0;

    int fridays = 0;
    if (totalDays > 0) {
      for (int i = 0; i < totalDays; i++) {
        DateTime checkDate = s.add(Duration(days: isContinuation ? i + 1 : i));
        if (checkDate.isAfter(e)) break;
        if (checkDate.weekday == DateTime.friday) {
          fridays++;
        }
      }
    }

    return DayBreakdown(
      totalDays: totalDays,
      fridays: excludeFridays ? fridays : 0,
      chargeableDays: excludeFridays ? (totalDays - fridays) : totalDays,
    );
  }
}

class DayBreakdown {
  final int totalDays;
  final int fridays;
  final int chargeableDays;

  DayBreakdown({
    required this.totalDays,
    required this.fridays,
    required this.chargeableDays,
  });
}

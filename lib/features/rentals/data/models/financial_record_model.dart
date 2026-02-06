import 'package:hive/hive.dart';

part 'financial_record_model.g.dart';

@HiveType(typeId: 5)
class FinancialRecord extends HiveObject {
  @HiveField(0)
  final double amount; // The amount generated in this settlement

  @HiveField(1)
  final DateTime date; // Date of settlement

  @HiveField(2)
  final DateTime periodStar; // Billing period start

  @HiveField(3)
  final DateTime periodEnd; // Billing period end

  @HiveField(4)
  final String? note;

  FinancialRecord({
    required this.amount,
    required this.date,
    required this.periodStar,
    required this.periodEnd,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'periodStar': periodStar.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'note': note,
    };
  }

  factory FinancialRecord.fromJson(Map<String, dynamic> json) {
    return FinancialRecord(
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      periodStar: DateTime.parse(json['periodStar'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      note: json['note'] as String?,
    );
  }
}

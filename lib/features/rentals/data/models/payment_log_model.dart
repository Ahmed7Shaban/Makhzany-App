import 'package:hive/hive.dart';

part 'payment_log_model.g.dart';

@HiveType(typeId: 4)
class PaymentLog extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String? note;

  PaymentLog({required this.amount, required this.date, this.note});

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'date': date.toIso8601String(), 'note': note};
  }

  factory PaymentLog.fromJson(Map<String, dynamic> json) {
    return PaymentLog(
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}

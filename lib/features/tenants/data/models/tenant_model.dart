import 'package:hive/hive.dart';

part 'tenant_model.g.dart';

@HiveType(typeId: 1)
class Tenant extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? phoneNumber; // Changed to nullable

  @HiveField(3)
  final String? notes;

  @HiveField(4)
  bool hasIdCard;

  @HiveField(5)
  final String? address; // New field

  Tenant({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.notes,
    this.hasIdCard = false,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'hasIdCard': hasIdCard,
      'address': address,
    };
  }

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      notes: json['notes'] as String?,
      hasIdCard: json['hasIdCard'] as bool? ?? false,
      address: json['address'] as String?,
    );
  }
}

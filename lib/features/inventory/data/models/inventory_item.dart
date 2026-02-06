import 'package:hive/hive.dart';

part 'inventory_item.g.dart';

@HiveType(typeId: 0)
class InventoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  int totalQty;

  @HiveField(4)
  int availableQty;

  @HiveField(5)
  double pricePerDay;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.totalQty,
    required this.availableQty,
    required this.pricePerDay,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'totalQty': totalQty,
      'availableQty': availableQty,
      'pricePerDay': pricePerDay,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      totalQty: json['totalQty'] as int,
      availableQty: json['availableQty'] as int,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
    );
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    int? totalQty,
    int? availableQty,
    double? pricePerDay,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      totalQty: totalQty ?? this.totalQty,
      availableQty: availableQty ?? this.availableQty,
      pricePerDay: pricePerDay ?? this.pricePerDay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

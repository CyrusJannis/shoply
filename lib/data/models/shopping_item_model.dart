import 'package:equatable/equatable.dart';

class ShoppingItemModel extends Equatable {
  final String id;
  final String listId;
  final String name;
  final double quantity;
  final String? unit;
  final String? category;
  final String? notes;
  final bool isChecked;
  final bool isDietWarning;
  final String? barcode;
  final String? addedBy;
  final int? sortOrder;
  final DateTime createdAt;
  final DateTime? checkedAt;
  final DateTime updatedAt;

  const ShoppingItemModel({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity = 1.0,
    this.unit,
    this.category,
    this.notes,
    this.isChecked = false,
    this.isDietWarning = false,
    this.barcode,
    this.addedBy,
    this.sortOrder,
    required this.createdAt,
    this.checkedAt,
    required this.updatedAt,
  });

  factory ShoppingItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingItemModel(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      isChecked: json['is_checked'] as bool? ?? false,
      isDietWarning: json['is_diet_warning'] as bool? ?? false,
      barcode: json['barcode'] as String?,
      addedBy: json['added_by'] as String?,
      sortOrder: json['sort_order'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      checkedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'] as String)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'notes': notes,
      'is_checked': isChecked,
      'is_diet_warning': isDietWarning,
      'barcode': barcode,
      'added_by': addedBy,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'checked_at': checkedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ShoppingItemModel copyWith({
    String? id,
    String? listId,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    String? notes,
    bool? isChecked,
    bool? isDietWarning,
    String? barcode,
    String? addedBy,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? checkedAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isChecked: isChecked ?? this.isChecked,
      isDietWarning: isDietWarning ?? this.isDietWarning,
      barcode: barcode ?? this.barcode,
      addedBy: addedBy ?? this.addedBy,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      checkedAt: checkedAt ?? this.checkedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        listId,
        name,
        quantity,
        unit,
        category,
        notes,
        isChecked,
        isDietWarning,
        barcode,
        addedBy,
        sortOrder,
        createdAt,
        checkedAt,
        updatedAt,
      ];
}

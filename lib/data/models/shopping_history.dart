import 'package:equatable/equatable.dart';

class ShoppingHistory extends Equatable {
  final String id;
  final String userId;
  final String listName;
  final int totalItems;
  final DateTime completedAt;
  final List<ShoppingHistoryItem> items;

  const ShoppingHistory({
    required this.id,
    required this.userId,
    required this.listName,
    required this.totalItems,
    required this.completedAt,
    this.items = const [],
  });

  factory ShoppingHistory.fromJson(Map<String, dynamic> json) {
    return ShoppingHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      listName: json['list_name'] as String,
      totalItems: json['total_items'] as int,
      completedAt: DateTime.parse(json['completed_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => ShoppingHistoryItem.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'list_name': listName,
      'total_items': totalItems,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, listName, totalItems, completedAt, items];
}

class ShoppingHistoryItem extends Equatable {
  final String id;
  final String historyId;
  final String name;
  final double quantity;
  final String? unit;
  final String? category;

  const ShoppingHistoryItem({
    required this.id,
    required this.historyId,
    required this.name,
    this.quantity = 1.0,
    this.unit,
    this.category,
  });

  factory ShoppingHistoryItem.fromJson(Map<String, dynamic> json) {
    return ShoppingHistoryItem(
      id: json['id'] as String,
      historyId: json['history_id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'history_id': historyId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
    };
  }

  @override
  List<Object?> get props => [id, historyId, name, quantity, unit, category];
}

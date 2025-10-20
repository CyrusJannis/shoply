import 'package:equatable/equatable.dart';

class ShoppingListModel extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String? shareCode;
  final String? qrCodeData;
  final String? shareLink;
  final bool isShared;
  final String sortMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? itemCount;
  final int? uncheckedCount;

  const ShoppingListModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.shareCode,
    this.qrCodeData,
    this.shareLink,
    this.isShared = false,
    this.sortMode = 'category',
    required this.createdAt,
    required this.updatedAt,
    this.itemCount,
    this.uncheckedCount,
  });

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    // Extract item count from the items array if present
    int? itemCount = json['item_count'] as int?;
    if (itemCount == null && json['items'] != null) {
      final items = json['items'] as List?;
      if (items != null && items.isNotEmpty) {
        itemCount = items[0]['count'] as int?;
      }
    }

    return ShoppingListModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      shareCode: json['share_code'] as String?,
      qrCodeData: json['qr_code_data'] as String?,
      shareLink: json['share_link'] as String?,
      isShared: json['is_shared'] as bool? ?? false,
      sortMode: json['sort_mode'] as String? ?? 'category',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      itemCount: itemCount,
      uncheckedCount: json['unchecked_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'share_code': shareCode,
      'qr_code_data': qrCodeData,
      'share_link': shareLink,
      'is_shared': isShared,
      'sort_mode': sortMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ShoppingListModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? shareCode,
    String? qrCodeData,
    String? shareLink,
    bool? isShared,
    String? sortMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
    int? uncheckedCount,
  }) {
    return ShoppingListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      shareCode: shareCode ?? this.shareCode,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      shareLink: shareLink ?? this.shareLink,
      isShared: isShared ?? this.isShared,
      sortMode: sortMode ?? this.sortMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
      uncheckedCount: uncheckedCount ?? this.uncheckedCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        ownerId,
        shareCode,
        qrCodeData,
        shareLink,
        isShared,
        sortMode,
        createdAt,
        updatedAt,
        itemCount,
        uncheckedCount,
      ];
}

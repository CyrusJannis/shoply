import 'dart:io';
import 'package:flutter/services.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.shoply.widget');
  
  /// Update widget with shopping list data
  static Future<void> updateWidget({
    required String listName,
    required List<WidgetItem> items,
  }) async {
    if (!Platform.isIOS) return;
    
    try {
      final data = {
        'listName': listName,
        'items': items.map((item) => item.toJson()).toList(),
      };
      
      await _channel.invokeMethod('updateWidget', data);
      print('Widget updated successfully');
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
  
  /// Clear widget data
  static Future<void> clearWidget() async {
    if (!Platform.isIOS) return;
    
    try {
      await _channel.invokeMethod('clearWidget');
      print('Widget cleared successfully');
    } catch (e) {
      print('Error clearing widget: $e');
    }
  }
}

class WidgetItem {
  final String id;
  final String name;
  final int quantity;
  final bool isChecked;
  
  WidgetItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isChecked,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'isChecked': isChecked,
  };
  
  factory WidgetItem.fromJson(Map<String, dynamic> json) => WidgetItem(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    isChecked: json['isChecked'] as bool,
  );
}

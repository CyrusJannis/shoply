import 'package:equatable/equatable.dart';

class Recipe extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int defaultServings;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int likes;
  final bool isLikedByUser;

  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.defaultServings,
    required this.ingredients,
    required this.instructions,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.likes = 0,
    this.isLikedByUser = false,
  });

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? defaultServings,
    List<Ingredient>? ingredients,
    List<String>? instructions,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    int? likes,
    bool? isLikedByUser,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      defaultServings: defaultServings ?? this.defaultServings,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'default_servings': defaultServings,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
      'likes': likes,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      prepTimeMinutes: json['prep_time_minutes'] as int,
      cookTimeMinutes: json['cook_time_minutes'] as int,
      defaultServings: json['default_servings'] as int,
      ingredients: (json['ingredients'] as List)
          .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
          .toList(),
      instructions: List<String>.from(json['instructions'] as List),
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      likes: json['likes'] as int? ?? 0,
      isLikedByUser: json['is_liked_by_user'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        prepTimeMinutes,
        cookTimeMinutes,
        defaultServings,
        ingredients,
        instructions,
        authorId,
        authorName,
        createdAt,
        likes,
        isLikedByUser,
      ];
}

class Ingredient extends Equatable {
  final String name;
  final double amount;
  final String unit;

  const Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  Ingredient adjustForServings(int originalServings, int newServings) {
    final multiplier = newServings / originalServings;
    return Ingredient(
      name: name,
      amount: amount * multiplier,
      unit: unit,
    );
  }

  String get displayText {
    // Format amount nicely
    String formattedAmount;
    if (amount == amount.toInt()) {
      formattedAmount = amount.toInt().toString();
    } else {
      formattedAmount = amount.toStringAsFixed(1);
    }
    
    return '$formattedAmount $unit $name';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }

  @override
  List<Object?> get props => [name, amount, unit];
}

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? authProvider;
  final List<String> dietPreferences;
  final bool notificationEnabled;
  final String language;
  final String theme;
  final String? fcmToken;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.authProvider,
    this.dietPreferences = const [],
    this.notificationEnabled = true,
    this.language = 'de',
    this.theme = 'light',
    this.fcmToken,
    this.onboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      authProvider: json['auth_provider'] as String?,
      dietPreferences: json['diet_preferences'] != null
          ? List<String>.from(json['diet_preferences'] as List)
          : [],
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      language: json['language'] as String? ?? 'de',
      theme: json['theme'] as String? ?? 'light',
      fcmToken: json['fcm_token'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'auth_provider': authProvider,
      'diet_preferences': dietPreferences,
      'notification_enabled': notificationEnabled,
      'language': language,
      'theme': theme,
      'fcm_token': fcmToken,
      'onboarding_completed': onboardingCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? authProvider,
    List<String>? dietPreferences,
    bool? notificationEnabled,
    String? language,
    String? theme,
    String? fcmToken,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      authProvider: authProvider ?? this.authProvider,
      dietPreferences: dietPreferences ?? this.dietPreferences,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      fcmToken: fcmToken ?? this.fcmToken,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        authProvider,
        dietPreferences,
        notificationEnabled,
        language,
        theme,
        fcmToken,
        onboardingCompleted,
        createdAt,
        updatedAt,
        lastLogin,
      ];
}

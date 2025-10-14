# 🛒 Shoply - Smart Shopping List App

A modern, feature-rich Flutter shopping list application with real-time synchronization, shared lists, recipe suggestions, and promotional flyers.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-Enabled-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/License-MIT-green)

## 🎯 Current Status

**✅ Core Functionality Complete (40%)**

The app has a solid foundation with working authentication, list management, and item operations. Users can:
- ✅ Sign in/Sign up
- ✅ Create and manage shopping lists
- ✅ Add, edit, delete, and check off items
- ✅ Auto-categorize items
- ✅ Get diet warnings
- ✅ Sort items multiple ways

**See [PROJECT_STATUS.md](PROJECT_STATUS.md) for detailed progress.**

## ✨ Features

### ✅ Implemented
- **Authentication** - Email/password, Google, Apple Sign-In
- **Shopping Lists** - Create, edit, delete lists
- **Shopping Items** - Add, edit, delete, check off items
- **Auto-Categorization** - Smart category detection (English & German)
- **Diet Warnings** - Highlight items that don't match diet preferences
- **Multiple Sort Options** - By category, alphabetical, or quantity
- **Modern UI** - Material 3 with light and dark mode support
- **Responsive Design** - Works on phones and tablets

### 🚧 In Progress
- **Real-time Sync** - Structure in place, needs activation
- **List Sharing** - Backend ready, UI pending
- **Offline Support** - Hive configured, sync logic pending

### 📋 Planned
- **Smart Recommendations** - Based on purchase history
- **Recipe Integration** - Browse and add ingredients to lists
- **Barcode Scanner** - Quick item addition
- **Promotional Flyers** - View supermarket deals
- **Shopping History** - Track completed trips
- **Push Notifications** - For shared list updates

## 🚀 Quick Start

**Want to get started quickly? See [QUICKSTART.md](QUICKSTART.md) for a 10-minute setup guide.**

For detailed setup instructions, continue reading or check [SETUP_GUIDE.md](SETUP_GUIDE.md).

## 📦 Installation

### Prerequisites

- Flutter SDK 3.9.2 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart SDK 3.0+
- A code editor (VS Code or Android Studio)
- Supabase account (free tier is fine)
- Git

### 1. Clone & Install

```bash
# Clone the repository
git clone <your-repo-url>
cd shoply

# Install dependencies
flutter pub get
```

### 2. Set up Supabase

```bash
# 1. Go to https://supabase.com and create a new project
# 2. In SQL Editor, run the supabase_schema.sql file
# 3. Enable Email authentication in Auth settings
# 4. Copy your project URL and anon key
```

### 3. Configure Environment

Edit `lib/core/config/env.dart` with your Supabase credentials:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

**⚠️ Important:** Never commit this file with real credentials!

### 4. Run the App

```bash
# Check available devices
flutter devices

# Run on your device
flutter run

# Or run on web for quick testing
flutter run -d chrome
```

### 5. Create Test Account

Since sign-up UI is not implemented:
1. Go to your Supabase dashboard
2. Navigate to Authentication → Users
3. Click "Add User" → "Create new user"
4. Use those credentials to log in to the app

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── config/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── state/
└── routes/
    └── app_router.dart
```

## Building for Production

### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

See LICENSE file for details.

## Support

For support, email support@shoply.app or open an issue on GitHub.

# ⚠️ WICHTIG: env.dart Setup

## Du musst die env.dart Datei aktualisieren!

Die Datei `lib/core/config/env.dart` ist in `.gitignore` und muss manuell erstellt werden.

### 1. Kopiere env.example.dart zu env.dart
```bash
cp lib/core/config/env.example.dart lib/core/config/env.dart
```

### 2. Fülle die Werte aus

Öffne `lib/core/config/env.dart` und ersetze die Platzhalter:

```dart
class Env {
  // Supabase Configuration
  static const String supabaseUrl = 'DEINE-SUPABASE-URL';
  static const String supabaseAnonKey = 'DEIN-SUPABASE-ANON-KEY';
  
  // Google OAuth Configuration
  // WICHTIG: Verwende die WEB Client ID (nicht iOS Client ID!)
  static const String googleClientId = 'DEINE-WEB-CLIENT-ID.apps.googleusercontent.com';
  static const String googleWebClientId = 'DEINE-WEB-CLIENT-ID.apps.googleusercontent.com';
}
```

### 3. Wo finde ich die Werte?

#### Supabase
1. Gehe zu [Supabase Dashboard](https://app.supabase.com)
2. Wähle dein Projekt
3. **Settings** → **API**
4. Kopiere:
   - **Project URL** → `supabaseUrl`
   - **anon public** key → `supabaseAnonKey`

#### Google Client ID
1. Folge der Anleitung in `GOOGLE_SIGNIN_SETUP.md`
2. Verwende die **Web Client ID** (nicht die iOS Client ID!)
3. Format: `123456789-abc123.apps.googleusercontent.com`

## ✅ Fertig!

Nachdem du `env.dart` erstellt und ausgefüllt hast, kannst du die App bauen und Google Sign-In wird funktionieren!

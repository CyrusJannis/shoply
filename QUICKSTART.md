# 🚀 Shoply - Quick Start Guide

Get your Shoply app running in 10 minutes!

## Prerequisites Check

Before starting, make sure you have:
- ✅ Flutter SDK installed (`flutter --version`)
- ✅ An IDE (VS Code or Android Studio)
- ✅ A device or emulator to test on

## Step 1: Install Dependencies (2 minutes)

```bash
cd shoply
flutter pub get
```

## Step 2: Set Up Supabase (5 minutes)

### Create Supabase Project
1. Go to [https://supabase.com](https://supabase.com)
2. Click "New Project"
3. Fill in:
   - **Name**: Shoply
   - **Database Password**: (create a strong password)
   - **Region**: (choose closest to you)
4. Click "Create new project" and wait ~2 minutes

### Run Database Schema
1. In Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy ALL content from `supabase_schema.sql` file
4. Paste and click "Run"
5. ✅ You should see "Success" message

### Enable Email Authentication
1. Go to **Authentication** → **Providers**
2. Find "Email" provider
3. Toggle it **ON**
4. Click "Save"

### Get Your API Keys
1. Go to **Settings** → **API**
2. You'll see:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbG...` (long string)

## Step 3: Configure App (1 minute)

Open `lib/core/config/env.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual values:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbG...your-key-here';
```

**💡 Tip:** Don't commit this file to git with real credentials!

## Step 4: Run the App (2 minutes)

```bash
# Check available devices
flutter devices

# Run the app
flutter run
```

Select your device when prompted, or run on specific device:

```bash
flutter run -d chrome          # Web (quick test)
flutter run -d <device-id>     # Specific device
```

## Step 5: Test It Out! ✨

### Create Your First Account

1. App should open to **Login Screen**
2. At the bottom, click "Sign Up" (shows "not implemented" for now)
3. **Workaround**: Create account via Supabase:
   - Go to Supabase → **Authentication** → **Users**
   - Click "Add User" → "Create new user"
   - Enter email and password
   - Click "Create user"

4. Go back to app and login with those credentials

### Explore the App

1. **Home Screen**: See quick actions and widgets
2. **Lists Tab**: Create your first shopping list
   - Click the `+` icon
   - Enter "Weekly Groceries"
   - Click "Create"
3. **Profile Tab**: View your profile
   - See your email
   - Try the settings (most are placeholders)
   - Sign out and sign in again

## 🎉 Success! You're Running Shoply!

## What's Working Right Now

- ✅ User authentication (email/password)
- ✅ Create and view shopping lists
- ✅ Navigate between screens
- ✅ View profile information
- ✅ Sign in/Sign out

## What's Not Implemented Yet

- ❌ Adding items to lists
- ❌ Sharing lists
- ❌ Recipes
- ❌ Barcode scanning
- ❌ Push notifications
- ❌ Offline mode

See `PROJECT_STATUS.md` for complete feature list.

## Common Issues & Solutions

### "Supabase has not been initialized"
**Solution:** Check that `env.dart` has your real Supabase URL and key.

### "Invalid API key"
**Solution:** Copy the key again from Supabase → Settings → API. Make sure you copied the entire key.

### "Connection refused"
**Solution:** 
- Check internet connection
- Verify Supabase project is running (not paused)
- Wait a minute and try again

### "No device found"
**Solution:**
```bash
# For web testing
flutter run -d chrome

# For Android
# Make sure Android emulator is running or phone is connected

# For iOS
# Make sure simulator is running or iPhone is connected
```

### Build errors
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

## Next Steps

Now that you have the app running:

1. **Read** `PROJECT_STATUS.md` to see what's implemented
2. **Check** `SETUP_GUIDE.md` for detailed configuration
3. **Explore** the code structure in `lib/`
4. **Start building** remaining features!

## Development Tips

### Hot Reload
While app is running:
- Press `r` for hot reload (fast)
- Press `R` for hot restart (full restart)
- Press `q` to quit

### Debugging
```bash
# Run with verbose output
flutter run --verbose

# View logs
flutter logs
```

### Testing on Real Device

**Android:**
1. Enable Developer Options on phone
2. Enable USB Debugging
3. Connect via USB
4. Accept debugging permission
5. Run `flutter run`

**iOS:**
1. Connect iPhone via USB
2. Trust computer on iPhone
3. In Xcode, select your team
4. Run `flutter run`

## Resources

- 📖 **Project Status**: `PROJECT_STATUS.md`
- 🛠️ **Setup Guide**: `SETUP_GUIDE.md`
- 📚 **Flutter Docs**: https://flutter.dev/docs
- 💾 **Supabase Docs**: https://supabase.com/docs

## Need Help?

1. Check the troubleshooting section in `SETUP_GUIDE.md`
2. Review Flutter and Supabase documentation
3. Check Stack Overflow for common issues
4. Review error messages carefully

---

**Happy Coding! 🎨📱✨**

You now have a fully functional authentication system and basic app structure. The foundation is solid - now you can build amazing features on top of it!

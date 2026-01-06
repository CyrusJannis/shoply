# Deep Linking Implementation Guide for Shared Shopping Lists

## Overview
This guide explains how to implement deep linking for shared shopping lists in Shoply, allowing users to share lists via URLs that:
- **Open the app** if installed (with join list prompt)
- **Redirect to App Store** if app is not installed

## Architecture

### URL Structure
```
https://yourdomain.com/shared/list/{list_id}?invite_code={code}
```

**Example**: `https://shoply.app/shared/list/abc123?invite_code=xyz789`

### Flow Diagram
```
User clicks link
    ↓
Has app installed?
    ├─ YES → Open app → Show "Join List" dialog → Add user to list
    └─ NO  → Open web page → Show list preview → "Download App" button → App Store
```

---

## Implementation Steps

## Step 1: Web Hosting Setup (Landing Page)

### 1.1 Create Landing Page on Your Domain

Create a simple HTML page at `https://yourdomain.com/shared/list/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Join Shopping List - Shoply</title>
    
    <!-- iOS Universal Links -->
    <meta name="apple-itunes-app" content="app-id=YOUR_APP_STORE_ID, 
          app-argument=shoply://shared/list">
    
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 500px;
            text-align: center;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .icon {
            font-size: 80px;
            margin-bottom: 20px;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
        }
        .list-name {
            color: #667eea;
            font-size: 24px;
            font-weight: bold;
            margin: 20px 0;
        }
        .description {
            color: #666;
            margin-bottom: 30px;
            line-height: 1.6;
        }
        .download-btn {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 15px 40px;
            border-radius: 30px;
            text-decoration: none;
            font-weight: bold;
            font-size: 18px;
            transition: all 0.3s;
        }
        .download-btn:hover {
            background: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(0,0,0,0.2);
        }
        .loading {
            color: #666;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🛒</div>
        <h1>You've been invited to join a shopping list!</h1>
        <div class="list-name" id="listName">Loading...</div>
        <p class="description">
            Download Shoply to collaborate on shopping lists with friends and family.
        </p>
        <a href="#" id="downloadBtn" class="download-btn">Download Shoply</a>
        <p class="loading" id="loadingText">Checking if you have the app...</p>
    </div>

    <script>
        // Parse URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        const listId = window.location.pathname.split('/').pop();
        const inviteCode = urlParams.get('invite_code');
        const listName = urlParams.get('name') || 'Shopping List';
        
        document.getElementById('listName').textContent = listName;
        
        // Try to open app with deep link
        const appScheme = `shoply://shared/list/${listId}?invite_code=${inviteCode}`;
        const appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_STORE_ID';
        const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.dominik.shoply';
        
        // Detect platform
        const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
        const isAndroid = /android/i.test(navigator.userAgent);
        
        // Set download button URL
        if (isIOS) {
            document.getElementById('downloadBtn').href = appStoreUrl;
        } else if (isAndroid) {
            document.getElementById('downloadBtn').href = playStoreUrl;
        } else {
            document.getElementById('downloadBtn').href = appStoreUrl;
        }
        
        // Try to open app
        let appOpened = false;
        const timeout = setTimeout(() => {
            if (!appOpened) {
                document.getElementById('loadingText').textContent = 
                    "Don't have the app? Download it now!";
            }
        }, 2000);
        
        // Attempt to open app
        window.location.href = appScheme;
        
        // Detect if user came back (app didn't open)
        window.addEventListener('blur', () => {
            appOpened = true;
            clearTimeout(timeout);
        });
        
        // iOS Universal Links fallback
        if (isIOS) {
            setTimeout(() => {
                if (!appOpened) {
                    window.location.href = appStoreUrl;
                }
            }, 3000);
        }
    </script>
</body>
</html>
```

### 1.2 Configure Apple App Site Association (iOS Universal Links)

Create `.well-known/apple-app-site-association` file on your server:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.dominik.shoply",
        "paths": [
          "/shared/list/*"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": [
      "TEAM_ID.com.dominik.shoply"
    ]
  }
}
```

**Important**: 
- Replace `TEAM_ID` with your Apple Developer Team ID
- Host this file at: `https://yourdomain.com/.well-known/apple-app-site-association`
- Must be served with `Content-Type: application/json`
- Must be accessible via HTTPS (SSL required)

---

## Step 2: iOS App Configuration

### 2.1 Update Info.plist

Add URL scheme to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.dominik.shoply</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>shoply</string>
        </array>
    </dict>
</array>
```

### 2.2 Enable Associated Domains in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Click "+ Capability" → Add "Associated Domains"
5. Add domain: `applinks:yourdomain.com`

### 2.3 Update Entitlements

File: `ios/Runner/Runner.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:yourdomain.com</string>
    </array>
</dict>
</plist>
```

---

## Step 3: Flutter App Implementation

### 3.1 Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  uni_links: ^0.5.1  # For handling deep links
  app_links: ^6.3.2  # Modern alternative (recommended)
```

### 3.2 Create Deep Link Service

Create `lib/data/services/deep_link_service.dart`:

```dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance {
    _instance ??= DeepLinkService._();
    return _instance!;
  }

  DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  
  // Callback for handling deep links
  Function(Uri)? onLinkReceived;

  /// Initialize deep link handling
  Future<void> initialize() async {
    debugPrint('🔗 [DEEP_LINK] Initializing deep link service');
    
    // Handle initial link (when app is opened from terminated state)
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        debugPrint('🔗 [DEEP_LINK] Initial link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('❌ [DEEP_LINK] Error getting initial link: $e');
    }

    // Handle links while app is running or in background
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 [DEEP_LINK] Received link: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('❌ [DEEP_LINK] Error in link stream: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 [DEEP_LINK] Handling: ${uri.toString()}');
    debugPrint('🔗 [DEEP_LINK] Scheme: ${uri.scheme}');
    debugPrint('🔗 [DEEP_LINK] Host: ${uri.host}');
    debugPrint('🔗 [DEEP_LINK] Path: ${uri.path}');
    debugPrint('🔗 [DEEP_LINK] Query: ${uri.queryParameters}');
    
    if (onLinkReceived != null) {
      onLinkReceived!(uri);
    }
  }

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
  }
}
```

### 3.3 Update Main App Initialization

Modify `lib/main.dart`:

```dart
import 'package:shoply/data/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing initialization (Supabase, etc.)
  
  // Initialize deep link service
  await DeepLinkService.instance.initialize();
  
  runApp(const MyApp());
}
```

### 3.4 Create Shared List Invitation Handler

Create `lib/presentation/screens/shared/shared_list_handler.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/data/repositories/list_repository.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/core/constants/app_colors.dart';

class SharedListHandler extends ConsumerStatefulWidget {
  final String listId;
  final String inviteCode;

  const SharedListHandler({
    super.key,
    required this.listId,
    required this.inviteCode,
  });

  @override
  ConsumerState<SharedListHandler> createState() => _SharedListHandlerState();
}

class _SharedListHandlerState extends ConsumerState<SharedListHandler> {
  bool _isLoading = true;
  String? _listName;
  String? _ownerName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadListInfo();
  }

  Future<void> _loadListInfo() async {
    try {
      // Fetch list information using invite code
      final response = await SupabaseService.instance.client
          .from('shopping_lists')
          .select('name, owner_id, users!inner(display_name)')
          .eq('id', widget.listId)
          .eq('invite_code', widget.inviteCode)
          .single();

      if (mounted) {
        setState(() {
          _listName = response['name'] as String;
          _ownerName = response['users']['display_name'] as String;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Invalid or expired invitation link';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinList() async {
    final user = SupabaseService.instance.currentUser;
    
    if (user == null) {
      // Show login dialog or navigate to login
      if (mounted) {
        context.go('/login?redirect=/shared/list/${widget.listId}?invite_code=${widget.inviteCode}');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Add user to shared list
      await SupabaseService.instance.client
          .from('list_shares')
          .insert({
        'list_id': widget.listId,
        'user_id': user.id,
        'permission': 'edit',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined "$_listName"!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to the list
        context.go('/lists/${widget.listId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to join list. You may already be a member.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: AppColors.error),
              SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag, size: 100, color: AppColors.accentBlue),
              SizedBox(height: 30),
              Text(
                'Join Shopping List',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                _listName ?? '',
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Shared by $_ownerName',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 40),
              Text(
                'You\'ve been invited to collaborate on this shopping list. Join to add items and shop together!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _joinList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text('Join List'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text('Maybe Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 3.5 Update Router Configuration

Modify `lib/routes/app_router.dart` to add deep link routes:

```dart
import 'package:shoply/presentation/screens/shared/shared_list_handler.dart';
import 'package:shoply/data/services/deep_link_service.dart';

// ... existing code ...

// Add to routes:
GoRoute(
  path: '/shared/list/:listId',
  name: 'sharedList',
  builder: (context, state) {
    final listId = state.pathParameters['listId']!;
    final inviteCode = state.uri.queryParameters['invite_code'] ?? '';
    
    return SharedListHandler(
      listId: listId,
      inviteCode: inviteCode,
    );
  },
),

// In router initialization, set up deep link handler:
final router = GoRouter(
  // ... existing config ...
  
  // Add deep link observer
  observers: [DeepLinkObserver()],
);

// Create observer class
class DeepLinkObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Set up deep link callback when router is ready
    DeepLinkService.instance.onLinkReceived = (uri) {
      if (uri.path.startsWith('/shared/list/')) {
        final segments = uri.pathSegments;
        if (segments.length >= 3) {
          final listId = segments[2];
          final inviteCode = uri.queryParameters['invite_code'] ?? '';
          
          router.go('/shared/list/$listId?invite_code=$inviteCode');
        }
      }
    };
  }
}
```

---

## Step 4: Database Schema for List Sharing

### 4.1 Add Invite Code to Shopping Lists

```sql
-- Add invite_code column to shopping_lists table
ALTER TABLE shopping_lists 
ADD COLUMN invite_code TEXT UNIQUE;

-- Create function to generate invite codes
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Update existing lists with invite codes
UPDATE shopping_lists 
SET invite_code = generate_invite_code() 
WHERE invite_code IS NULL;

-- Trigger to auto-generate invite code for new lists
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.invite_code IS NULL THEN
    NEW.invite_code := generate_invite_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER shopping_lists_invite_code
BEFORE INSERT ON shopping_lists
FOR EACH ROW
EXECUTE FUNCTION set_invite_code();
```

### 4.2 Create List Shares Table

```sql
-- Table to track who has access to which lists
CREATE TABLE IF NOT EXISTS list_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission TEXT NOT NULL DEFAULT 'view' CHECK (permission IN ('view', 'edit', 'admin')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(list_id, user_id)
);

-- Enable RLS
ALTER TABLE list_shares ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see shares for lists they own or are part of
CREATE POLICY "Users can view their list shares"
ON list_shares FOR SELECT
USING (
  user_id = auth.uid() OR
  list_id IN (SELECT id FROM shopping_lists WHERE owner_id = auth.uid())
);

-- Policy: Anyone can insert (for joining via invite)
CREATE POLICY "Anyone can join lists with invite code"
ON list_shares FOR INSERT
WITH CHECK (true);

-- Policy: List owners can manage shares
CREATE POLICY "List owners can manage shares"
ON list_shares FOR ALL
USING (
  list_id IN (SELECT id FROM shopping_lists WHERE owner_id = auth.uid())
);

-- Index for performance
CREATE INDEX idx_list_shares_list_id ON list_shares(list_id);
CREATE INDEX idx_list_shares_user_id ON list_shares(user_id);
```

---

## Step 5: Add Share Functionality to App

### 5.1 Create Share Button in List Detail Screen

Add to `lib/presentation/screens/lists/list_detail_screen.dart`:

```dart
// In the AppBar actions:
IconButton(
  icon: Icon(Icons.share),
  onPressed: _shareList,
  tooltip: 'Share List',
),

// Add method:
Future<void> _shareList() async {
  try {
    final list = await ref.read(listRepositoryProvider).getList(widget.listId);
    final inviteCode = list.inviteCode; // Add this field to ShoppingListModel
    
    final shareUrl = 'https://yourdomain.com/shared/list/${widget.listId}?invite_code=$inviteCode&name=${Uri.encodeComponent(list.name)}';
    
    await Share.share(
      'Join my shopping list "${list.name}" on Shoply!\n\n$shareUrl',
      subject: 'Shopping List Invitation',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share list'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
```

### 5.2 Update ShoppingListModel

Add invite_code field to `lib/data/models/shopping_list_model.dart`:

```dart
class ShoppingListModel {
  final String id;
  final String name;
  // ... existing fields ...
  final String? inviteCode;
  
  // Update fromJson:
  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListModel(
      id: json['id'] as String,
      name: json['name'] as String,
      // ... existing fields ...
      inviteCode: json['invite_code'] as String?,
    );
  }
}
```

---

## Step 6: Testing Deep Links

### 6.1 Test on iOS Simulator

```bash
# Test custom URL scheme
xcrun simctl openurl booted "shoply://shared/list/abc123?invite_code=xyz789"

# Test universal link
xcrun simctl openurl booted "https://yourdomain.com/shared/list/abc123?invite_code=xyz789"
```

### 6.2 Test on Real Device

1. **Email yourself** the link
2. **Send via Messages** to yourself
3. **Create QR code** and scan it
4. **Safari**: Type URL in Safari and tap

### 6.3 Verify Universal Links (iOS)

```bash
# Check if AASA file is valid
curl https://yourdomain.com/.well-known/apple-app-site-association

# Verify with Apple's validator
# https://search.developer.apple.com/appsearch-validation-tool/
```

---

## Step 7: App Store Submission Requirements

### 7.1 Update App Store Listing

1. **App Preview Video**: Show sharing feature
2. **Screenshots**: Include invite acceptance flow
3. **Description**: Mention "Share lists with friends and family"

### 7.2 Privacy Policy Update

Add section about shared lists:
```
When you share a shopping list, we share:
- List name
- List items
- Your display name (with people you share with)
```

---

## Troubleshooting

### Issue: Universal Links Not Working on iOS

**Solutions**:
1. Verify AASA file is accessible via HTTPS
2. Check that `Content-Type: application/json` header is set
3. Ensure Team ID matches in AASA and Xcode
4. Uninstall and reinstall app (iOS caches AASA)
5. Wait 24 hours (Apple CDN caching)

### Issue: Deep Link Opens Browser Instead of App

**Solutions**:
1. Check URL scheme is correctly registered in `Info.plist`
2. Verify app is installed on device
3. Test with `xcrun simctl openurl` first
4. Check for typos in scheme name

### Issue: "Invalid Invitation" Error

**Solutions**:
1. Verify invite code exists in database
2. Check RLS policies allow reading list info
3. Ensure invite code wasn't regenerated

---

## Security Considerations

### 1. Invite Code Expiration (Optional)
```sql
ALTER TABLE shopping_lists 
ADD COLUMN invite_expires_at TIMESTAMP WITH TIME ZONE;

-- Check expiration in app
WHERE invite_code = ? AND (invite_expires_at IS NULL OR invite_expires_at > NOW())
```

### 2. Permission Levels
- **View**: Can see list items only
- **Edit**: Can add/remove items
- **Admin**: Can share list and manage members

### 3. Revoke Access
Add button in list settings to remove members:
```dart
Future<void> _removeUser(String userId) async {
  await SupabaseService.instance.client
      .from('list_shares')
      .delete()
      .eq('list_id', widget.listId)
      .eq('user_id', userId);
}
```

---

## Analytics Tracking

Add tracking for sharing metrics:

```dart
// When user shares a list
AnalyticsService.instance.logEvent('list_shared', {
  'list_id': listId,
  'method': 'link', // vs 'qr_code', 'email', etc.
});

// When user joins via link
AnalyticsService.instance.logEvent('list_joined_via_link', {
  'list_id': listId,
  'is_new_user': isNewUser,
});
```

---

## Future Enhancements

1. **QR Code Sharing**: Generate QR codes for in-person sharing
2. **Email Invites**: Send direct email invitations
3. **Temporary Guest Access**: Allow view-only access without account
4. **Smart Share Suggestions**: Suggest sharing with frequent contacts
5. **Share Analytics**: Show list owner who joined and when

---

## Cost Estimate

### Domain & Hosting
- **Domain**: $10-15/year
- **Static Hosting** (Netlify/Vercel): Free tier (plenty for landing page)
- **SSL Certificate**: Free (Let's Encrypt via hosting provider)

### Development Time
- **Backend** (Database, API): 4-6 hours
- **iOS Configuration**: 2-3 hours
- **Flutter Implementation**: 6-8 hours
- **Testing & Polish**: 3-4 hours
- **Total**: ~15-20 hours

---

## Quick Start Checklist

- [ ] Purchase domain (e.g., shoply.app)
- [ ] Set up hosting (Netlify/Vercel)
- [ ] Create landing page HTML
- [ ] Configure AASA file
- [ ] Run database migrations (add invite_code, list_shares table)
- [ ] Add deep link dependencies to pubspec.yaml
- [ ] Create DeepLinkService
- [ ] Create SharedListHandler screen
- [ ] Update router with deep link routes
- [ ] Add share button to list detail screen
- [ ] Test on simulator
- [ ] Test on real device
- [ ] Submit to App Store with updated description

---

## Support

For issues with implementation:
1. Check Supabase logs for RLS policy issues
2. Use `xcrun simctl openurl` for testing
3. Check browser console on landing page
4. Verify AASA file with Apple's validator

---

**Remember**: Universal Links require HTTPS and can take up to 24 hours to propagate due to Apple's CDN caching!

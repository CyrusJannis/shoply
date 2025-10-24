# Voice Assistant Setup Guide

**Status:** Implementation Complete  
**Platforms:** iOS (Siri) & Android (Google Assistant)  
**Date:** October 23, 2025

---

## 🎙️ Overview

Voice assistant integration allows users to:
- Add items to shopping lists via voice
- Create new shopping lists
- View shopping lists
- All without opening the app

**Supported Commands:**
- "Hey Siri, add milk to my shopping list"
- "OK Google, add bread to my shopping list in Shoply"
- "Hey Siri, create a new shopping list"
- "OK Google, show my shopping list"

---

## 📁 Files Created

### Flutter Service
- ✅ `lib/data/services/voice_assistant_service.dart` - Main service

### iOS (Siri Shortcuts)
- ✅ `ios/Runner/VoiceAssistantPlugin.swift` - Native iOS implementation

### Android (Google Assistant)
- ✅ `android/app/src/main/kotlin/com/shoply/VoiceAssistantPlugin.kt` - Native Android implementation
- ✅ `android/app/src/main/res/xml/actions.xml` - App Actions configuration

---

## 🍎 iOS Setup (Siri Shortcuts)

### Step 1: Update Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<key>NSSiriUsageDescription</key>
<string>Shoply needs access to Siri to add items to your shopping list using voice commands.</string>

<key>NSUserActivityTypes</key>
<array>
    <string>AddItemIntent</string>
    <string>CreateListIntent</string>
    <string>ViewListIntent</string>
</array>
```

### Step 2: Enable Siri Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Siri"

### Step 3: Create Intents Definition

1. In Xcode, File → New → File
2. Select "SiriKit Intent Definition File"
3. Name it "Intents.intentdefinition"
4. Add three intents:
   - **AddItemIntent**
     - Parameters: itemName (String), listName (String, optional)
     - Suggested phrase: "Add to shopping list"
   - **CreateListIntent**
     - Parameters: listName (String)
     - Suggested phrase: "Create shopping list"
   - **ViewListIntent**
     - Parameters: listName (String, optional)
     - Suggested phrase: "Show shopping list"

### Step 4: Register Plugin in AppDelegate

Update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register Voice Assistant Plugin
    if #available(iOS 12.0, *) {
        let controller = window?.rootViewController as! FlutterViewController
        VoiceAssistantPlugin.register(with: registrar(forPlugin: "VoiceAssistantPlugin")!)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Step 5: Handle Intents

The plugin automatically handles intents and calls back to Flutter via the method channel.

---

## 🤖 Android Setup (Google Assistant)

### Step 1: Update AndroidManifest.xml

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <application>
        <!-- Existing activity -->
        <activity android:name=".MainActivity">
            <!-- Add intent filters for App Actions -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="shoply" />
            </intent-filter>
        </activity>

        <!-- Reference to actions.xml -->
        <meta-data
            android:name="com.google.android.actions"
            android:resource="@xml/actions" />
    </application>
</manifest>
```

### Step 2: Add String Resources

Create/update `android/app/src/main/res/values/strings.xml`:

```xml
<resources>
    <string name="app_name">Shoply</string>
    
    <!-- Item names -->
    <string name="item_milk">Milk</string>
    <string name="item_bread">Bread</string>
    <string name="item_eggs">Eggs</string>
    
    <!-- List names -->
    <string name="list_shopping">Shopping List</string>
    <string name="list_groceries">Groceries</string>
</resources>
```

### Step 3: Register Plugin in MainActivity

Update `android/app/src/main/kotlin/com/shoply/MainActivity.kt`:

```kotlin
package com.shoply

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register Voice Assistant Plugin
        flutterEngine.plugins.add(VoiceAssistantPlugin())
    }
}
```

### Step 4: Handle Deep Links

The app will automatically receive deep links from Google Assistant via the intent filters.

---

## 🔧 Flutter Integration

### Initialize Service

In your main app initialization:

```dart
import 'package:shoply/data/services/voice_assistant_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize voice assistant
  final voiceAssistant = VoiceAssistantService();
  await voiceAssistant.initialize();
  
  runApp(MyApp());
}
```

### Donate Shortcuts (iOS)

When user adds an item manually, donate the action to Siri:

```dart
// After adding an item
await voiceAssistant.donateSiriShortcut(
  action: 'addItemToList',
  parameters: {
    'itemName': itemName,
    'listName': listName,
  },
);
```

### Register Custom Shortcuts (iOS)

Allow users to create custom Siri phrases:

```dart
// In settings or list screen
ElevatedButton(
  onPressed: () async {
    await voiceAssistant.registerSiriShortcut(
      phrase: 'Add to my shopping list',
      action: 'addItemToList',
      parameters: {
        'listName': currentListName,
      },
    );
  },
  child: Text('Add Siri Shortcut'),
)
```

---

## 🧪 Testing

### iOS (Siri)

1. Build and run on physical iOS device (Siri doesn't work in simulator)
2. Go to Settings → Siri & Search → Shoply
3. Verify shortcuts appear
4. Say: "Hey Siri, add milk to my shopping list"
5. Check that item was added

**Test Commands:**
- "Hey Siri, add [item] to my shopping list"
- "Hey Siri, add [item] to [list name]"
- "Hey Siri, create a shopping list called [name]"
- "Hey Siri, show my shopping list"

### Android (Google Assistant)

1. Build and run on Android device
2. Open Google Assistant
3. Say: "Add milk to my shopping list in Shoply"
4. App should open and add the item

**Test Commands:**
- "OK Google, add [item] to my shopping list in Shoply"
- "OK Google, create a shopping list in Shoply"
- "OK Google, open my shopping list in Shoply"

---

## 🎯 Supported Commands

### Add Item to List
**iOS:** "Hey Siri, add milk to my shopping list"  
**Android:** "OK Google, add milk to my shopping list in Shoply"

**Behavior:**
- If list name specified: Adds to that list (fuzzy matching)
- If no list specified: Adds to last accessed list
- If no lists exist: Creates default list and adds item

### Create List
**iOS:** "Hey Siri, create a shopping list called Groceries"  
**Android:** "OK Google, create a shopping list in Shoply"

**Behavior:**
- Creates new list with specified name
- Opens the list in the app

### View List
**iOS:** "Hey Siri, show my shopping list"  
**Android:** "OK Google, open my shopping list in Shoply"

**Behavior:**
- If list name specified: Opens that list
- If no list specified: Opens last accessed list

---

## 🔒 Permissions

### iOS
- **Siri Usage:** Required for Siri Shortcuts
- **Description:** "Shoply needs access to Siri to add items to your shopping list using voice commands."

### Android
- **Internet:** Already required for Supabase
- **Deep Links:** Handled via intent filters

---

## 🐛 Troubleshooting

### iOS Issues

**Siri doesn't recognize commands:**
- Ensure Siri capability is enabled in Xcode
- Check Info.plist has NSUserActivityTypes
- Verify intents are properly defined
- Donate shortcuts after user actions

**Shortcuts don't appear in Settings:**
- Rebuild app after adding intents
- Donate shortcuts programmatically
- Check Siri & Search settings

### Android Issues

**Google Assistant doesn't open app:**
- Verify AndroidManifest.xml has intent filters
- Check actions.xml is properly formatted
- Ensure app is installed from Play Store (for production)
- Test with "Test your Action" in Actions Console

**Deep links not working:**
- Verify scheme is "shoply"
- Check MainActivity handles intents
- Test deep link manually: `adb shell am start -a android.intent.action.VIEW -d "shoply://addItem?itemName=milk"`

---

## 📊 Implementation Status

### ✅ Complete
- [x] Voice assistant service created
- [x] iOS plugin implementation
- [x] Android plugin implementation
- [x] Method channel setup
- [x] Intent handling
- [x] Deep link support
- [x] Fuzzy list name matching
- [x] Default list fallback

### ⚠️ Requires Manual Setup
- [ ] iOS: Enable Siri capability in Xcode
- [ ] iOS: Create Intents.intentdefinition
- [ ] iOS: Update Info.plist
- [ ] iOS: Register plugin in AppDelegate
- [ ] Android: Update AndroidManifest.xml
- [ ] Android: Add string resources
- [ ] Android: Register plugin in MainActivity
- [ ] Testing on physical devices

### 📋 Optional Enhancements
- [ ] Add more entity types (common items)
- [ ] Implement voice feedback
- [ ] Add confirmation dialogs
- [ ] Support quantity in voice commands
- [ ] Multi-language support
- [ ] Custom wake words (iOS)

---

## 🚀 Deployment Checklist

### iOS
- [ ] Siri capability enabled
- [ ] Intents defined
- [ ] Info.plist updated
- [ ] Tested on physical device
- [ ] App Store submission includes Siri usage description

### Android
- [ ] AndroidManifest.xml updated
- [ ] actions.xml configured
- [ ] String resources added
- [ ] Tested on physical device
- [ ] Play Store listing mentions voice commands

---

## 📝 User Documentation

### For App Users

**iOS Users:**
1. Open Shoply
2. Go to Settings → Siri & Search → Shoply
3. Tap "Add to Siri" on any shortcut
4. Record your custom phrase
5. Use your phrase to add items hands-free!

**Android Users:**
1. Make sure Google Assistant is set up
2. Say "OK Google, add [item] to my shopping list in Shoply"
3. The app will open and add your item automatically

---

## 🎓 Best Practices

1. **Donate Shortcuts Frequently**
   - Donate after every manual action
   - Helps Siri learn user patterns
   - Improves suggestion quality

2. **Handle Errors Gracefully**
   - Always provide feedback
   - Fallback to default list
   - Create list if none exists

3. **Fuzzy Matching**
   - Use ILIKE for list name matching
   - Accept partial matches
   - Case-insensitive

4. **User Experience**
   - Confirm actions with notifications
   - Provide voice feedback when possible
   - Keep commands simple and natural

---

## 📞 Support

**Documentation:**
- Apple Siri Shortcuts: https://developer.apple.com/siri/
- Google App Actions: https://developers.google.com/assistant/app/

**Implementation Files:**
- `lib/data/services/voice_assistant_service.dart`
- `ios/Runner/VoiceAssistantPlugin.swift`
- `android/app/src/main/kotlin/com/shoply/VoiceAssistantPlugin.kt`

---

**Voice Assistant Implementation Complete! 🎙️**

**Next Steps:**
1. Complete manual iOS/Android setup
2. Test on physical devices
3. Deploy to App Store/Play Store

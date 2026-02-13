# FaithStream Flutter App - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Ensure Backend is Running
```bash
# In backend directory
cd /Users/kcs/Documents/MPP/faithstream-backend
npm start

# Backend should be running on http://localhost:9000
```

### Step 2: Run the Flutter App
```bash
# In Flutter app directory
cd /Users/kcs/Documents/MPP/faithstream-backend/faith_stream_music_app

# Run on your preferred device
flutter run

# Or run on specific device
flutter run -d <device-id>
flutter devices  # To see available devices
```

### Step 3: Test the App

#### Option A: Use Existing Account
1. App opens on Splash Screen
2. Redirects to Login Screen
3. Enter existing credentials:
   - Email: `your-email@example.com`
   - Password: `your-password`
4. Tap "LOGIN"
5. Redirects to Home Screen

#### Option B: Create New Account
1. From Login Screen, tap "Register"
2. Enter details:
   - Name: `Your Name`
   - Email: `new-email@example.com`
   - Password: `password123`
   - Confirm Password: `password123`
3. Tap "REGISTER"
4. Redirects to Home Screen

## 📱 What You'll See

### Splash Screen (2-3 seconds)
- Beautiful gradient background (brown → gold)
- App logo with fade-in animation
- Loading indicator
- Auto-checks authentication

### Login Screen
- Email input field
- Password input field (with show/hide toggle)
- LOGIN button
- "Don't have an account? Register" link
- Smooth animations on all elements

### Register Screen
- Name input field
- Email input field
- Password input field
- Confirm Password input field
- REGISTER button
- "Already have an account? Login" link
- Form validation with error messages

### Home Screen (Placeholder)
- Welcome message with user's name
- User info card showing:
  - Email
  - Name
  - Artist status
  - Admin status
- Logout button in app bar

## 🎨 Features to Notice

### Animations
- ✨ Fade-in effects on screen elements
- 📲 Slide-in transitions for inputs
- 🔄 Scale animations on buttons
- 🌊 Smooth page transitions

### Validation
- ✅ Email format validation
- ✅ Password length (min 6 characters)
- ✅ Password matching for registration
- ✅ Required field validation

### Loading States
- ⏳ Button shows spinner during API call
- 🚫 Form inputs disabled while loading
- ✓ Success redirects to home
- ❌ Errors shown in red SnackBar

### Theme
- 🌞 Light theme (default)
- 🌙 Dark theme (follows system)
- 🎨 Christian color scheme:
  - Brown primary (#8B4513)
  - Gold accent (#D4A76A)

## 🔧 Configuration

### For Android Emulator
If the app can't connect to localhost, update the base URL:

**lib/config/app_config.dart**
```dart
static const String baseUrl = 'http://10.0.2.2:9000';  // For Android
```

### For iOS Simulator
Localhost should work fine:
```dart
static const String baseUrl = 'http://localhost:9000';  // For iOS
```

### For Physical Device
Use your computer's IP address:
```dart
static const String baseUrl = 'http://192.168.x.x:9000';  // Your local IP
```

## 🧪 Testing Checklist

### Authentication Flow
- [ ] Splash screen shows and auto-checks auth
- [ ] Redirects to login if not authenticated
- [ ] Can enter credentials and login
- [ ] Shows loading spinner during login
- [ ] Redirects to home on successful login
- [ ] Displays error message on invalid credentials
- [ ] Can navigate to register screen
- [ ] Can register new account
- [ ] Password visibility toggle works
- [ ] Form validation works (empty fields, invalid email)
- [ ] Password matching validation works
- [ ] Token persists (close and reopen app → auto-logged in)
- [ ] Logout button works
- [ ] After logout, redirects to login

### UI/UX
- [ ] Animations are smooth
- [ ] Colors match Christian theme (brown/gold)
- [ ] Text is readable in both light and dark mode
- [ ] Buttons respond to taps
- [ ] Keyboard dismisses appropriately
- [ ] Form scrolls when keyboard is open

## 🐛 Common Issues

### Issue: "Connection refused" or "Network error"
**Solution:**
1. Check backend is running
2. Verify URL in app_config.dart
3. For Android emulator, use 10.0.2.2 instead of localhost

### Issue: "Invalid credentials" even with correct password
**Solution:**
1. Check backend console for errors
2. Verify user exists in database
3. Test backend API directly with Postman/curl

### Issue: App crashes on startup
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Animations not smooth
**Solution:**
- Use Release mode: `flutter run --release`
- Debug mode has performance overhead

### Issue: Theme not applying
**Solution:**
- Hot restart the app (not hot reload)
- Press 'R' in terminal or Stop & Run again

## 📊 Next Development Steps

### Phase 2: Home & Content
1. Implement real home screen with content
2. Add music player controls
3. Integrate song browsing
4. Add search functionality

### Phase 3: Playback
1. Audio player integration (just_audio)
2. Background playback
3. Lock screen controls
4. Queue management

### Phase 4: Advanced Features
1. Playlists
2. Favorites
3. Downloads
4. Subscription management

## 💡 Development Tips

### Hot Reload vs Hot Restart
- **Hot Reload (r)**: Quick refresh, keeps state
- **Hot Restart (R)**: Full restart, loses state
- Use Hot Restart for navigation/auth changes

### Viewing Logs
```bash
# In the terminal where flutter run is active
# Network logs show automatically (dio logger)
# Look for:
# ┌── HTTP Request ──
# └── HTTP Response ──
```

### Debugging Auth State
The AuthBloc logs state changes. Watch for:
- `AuthLoading` → API call in progress
- `AuthAuthenticated` → Login successful
- `AuthError` → Something went wrong
- `AuthUnauthenticated` → Logged out / No token

### Inspecting Storage
Token is stored securely, but you can check:
```dart
// Add this temporarily in home_screen.dart
final token = await StorageService(...).getToken();
print('Token: $token');
```

## 🎯 Ready to Test!

Everything is set up and ready. Just:
1. Start your backend
2. Run `flutter run`
3. Test login/register
4. Enjoy the smooth animations!

---

**Need help?** Check PHASE_1_COMPLETE.md for detailed documentation.

**Found a bug?** Double-check the troubleshooting section above.

**Ready for Phase 2?** All the foundation is in place! 🚀

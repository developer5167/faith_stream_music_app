### Debugging Guide - Blank Screen Issues

## What We've Fixed

1. **Added Error Boundary in main.dart**
   - Wrapped app initialization in try-catch
   - Shows error screen if initialization fails
   - Logs detailed error messages

2. **Enhanced Splash Screen Error Handling**
   - Added try-catch in initState
   - Logs auth state changes
   - Handles AuthError state
   - Falls back to login on errors

3. **Debug Logging Added**
   - Auth state transitions now logged
   - Errors are printed to console
   - Stack traces captured

## How to Debug

### Step 1: Check Flutter Logs
When you run the app, look for these debug messages:
```
Splash Screen - Auth State Changed: AuthInitial
Splash Screen - Auth State Changed: AuthLoading
Splash Screen - Auth State Changed: AuthUnauthenticated
```

### Step 2: Look for Errors
Check for these error messages:
```
Error initializing app: [error details]
Error in splash screen initState: [error details]
Auth Error: [error message]
```

### Step 3: Common Issues

**Issue 1: White/Blank Screen**
- **Cause**: App initialized but stuck on loading state
- **Check**: Look for "Auth State Changed" logs
- **Fix**: Auth state might not be transitioning properly

**Issue 2: Immediate Crash**
- **Cause**: Initialization error in main()
- **Check**: Look for "Error initializing app" message
- **Fix**: Check API config, storage permissions

**Issue 3: Stuck on Splash**
- **Cause**: AuthBloc not emitting states
- **Check**: No state change logs after AuthLoading
- **Fix**: Backend connection or API issue

### Step 4: Quick Fixes

**If backend is not running:**
```bash
cd /Users/kcs/Documents/MPP/faithstream-backend
npm start
```

**If still blank, check device logs:**
```bash
# For iOS
flutter logs

# Or in Xcode
Window > Devices and Simulators > View Device Logs
```

**Test without backend:**
- The app should show splash → login screen
- Even if backend is down, it should navigate

## Test Commands

```bash
# Clean and rebuild
cd faith_stream_music_app
flutter clean
flutter pub get
flutter run

# Run with verbose logging
flutter run -v

# Check for analysis errors
flutter analyze
```

## Expected Flow

1. **App Launches** → Shows Splash Screen
2. **AuthBloc.add(AuthCheckRequested)** → Checks for saved token
3. **No Token Found** → Navigate to Login Screen
4. **Token Found** → Validate with backend → Navigate to Home or Login

## Next Steps if Still Blank

1. Run with verbose logging: `flutter run -v`
2. Check the output for the first error
3. Share the error message for specific fix

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionsHelper {
  /// DEBUG: Test permissions immediately (call this from UI to test)
  static Future<void> debugTestPermissions() async {
    print('🔧 DEBUG: Testing permissions...');

    // Check current status
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    print('🔧 DEBUG: Current Camera: $cameraStatus, Microphone: $micStatus');

    // Force request both
    final cameraResult = await Permission.camera.request();
    final micResult = await Permission.microphone.request();
    print(
      '🔧 DEBUG: After request Camera: $cameraResult, Microphone: $micResult',
    );
  }

  /// Request camera permission for video recording
  static Future<bool> requestCameraPermission() async {
    print('🎥 Camera permission status check...');
    final status = await Permission.camera.status;
    print('🎥 Camera current status: $status');

    if (status.isGranted) {
      print('🎥 Camera already granted');
      return true;
    }

    // Always request permission if not granted (this ensures iOS shows the dialog)
    print('🎥 Requesting camera permission...');
    final result = await Permission.camera.request();
    print('🎥 Camera request result: $result');

    return result.isGranted;
  }

  /// Request microphone permission for video recording
  static Future<bool> requestMicrophonePermission() async {
    print('🎙️ Microphone permission status check...');
    final status = await Permission.microphone.status;
    print('🎙️ Microphone current status: $status');

    if (status.isGranted) {
      print('🎙️ Microphone already granted');
      return true;
    }

    // Always request permission if not granted (this ensures iOS shows the dialog)
    print('🎙️ Requesting microphone permission...');
    final result = await Permission.microphone.request();
    print('🎙️ Microphone request result: $result');

    return result.isGranted;
  }

  /// Request both camera and microphone permissions
  static Future<bool> requestVideoRecordingPermissions() async {
    print('📱 Starting video recording permission requests...');

    final cameraGranted = await requestCameraPermission();
    print('📱 Camera granted: $cameraGranted');

    final microphoneGranted = await requestMicrophonePermission();
    print('📱 Microphone granted: $microphoneGranted');

    final result = cameraGranted && microphoneGranted;
    print('📱 Final result: $result');

    return result;
  }

  /// Show settings dialog when permissions are permanently denied
  static void showPermissionSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'FaithStream needs camera and microphone permissions to record your selfie video for artist verification.\n\n'
          'To enable permissions:\n'
          '1. Tap "Open Settings"\n'
          '2. Find "FaithStream" in the list\n'
          '3. Enable Camera and Microphone permissions\n'
          '4. Return to the app to try again',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

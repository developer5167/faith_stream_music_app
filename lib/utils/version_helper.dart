import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_config.dart';

class VersionHelper {
  final AppConfig appConfig;

  VersionHelper(this.appConfig);

  /**
   * Checks if an update is available for the current platform.
   * Returns an AppVersion object if an update is suggested/required.
   */
  Future<AppVersion?> getAvailableUpdate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final int currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      
      debugPrint('🔍 Version Check: Current Build Number (local) = $currentVersionCode');

      final AppVersion? platformVersion = defaultTargetPlatform == TargetPlatform.android
          ? appConfig.android
          : appConfig.ios;

      if (platformVersion != null) {
        debugPrint('🔍 Version Check: Target Version Code (backend) = ${platformVersion.versionCode} (${defaultTargetPlatform == TargetPlatform.android ? "Android" : "iOS"})');
        
        if (platformVersion.versionCode > currentVersionCode) {
          debugPrint('🆕 Update available detected! Latest: ${platformVersion.versionCode}');
          return platformVersion;
        } else {
          debugPrint('✅ App is up to date.');
        }
      } else {
        debugPrint('⚠️ No version config found for platform: $defaultTargetPlatform');
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    return null;
  }
}

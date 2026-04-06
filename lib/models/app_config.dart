import 'package:equatable/equatable.dart';

class AppConfig extends Equatable {
  final AppVersion? android;
  final AppVersion? ios;

  const AppConfig({this.android, this.ios});

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      android: json['android_latest_version'] != null
          ? AppVersion.fromJson(json['android_latest_version'])
          : null,
      ios: json['ios_latest_version'] != null
          ? AppVersion.fromJson(json['ios_latest_version'])
          : null,
    );
  }

  @override
  List<Object?> get props => [android, ios];
}

class AppVersion extends Equatable {
  final int versionCode;
  final String versionName;
  final bool isMandatory;
  final String updateUrl;
  final String updateMessage;

  const AppVersion({
    required this.versionCode,
    required this.versionName,
    required this.isMandatory,
    required this.updateUrl,
    required this.updateMessage,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      versionCode: json['version_code'] ?? 0,
      versionName: json['version_name'] ?? '1.0.0',
      isMandatory: json['is_mandatory'] ?? false,
      updateUrl: json['update_url'] ?? '',
      updateMessage: json['update_message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    versionCode,
    versionName,
    isMandatory,
    updateUrl,
    updateMessage,
  ];
}

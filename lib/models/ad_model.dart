import 'package:equatable/equatable.dart';

class AdModel extends Equatable {
  final String id;
  final String title;
  final String adType;
  final String mediaUrl;
  final String landingUrl;

  const AdModel({
    required this.id,
    required this.title,
    required this.adType,
    required this.mediaUrl,
    required this.landingUrl,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] as String,
      title: json['title'] as String,
      adType: json['ad_type'] as String,
      mediaUrl: json['media_url'] as String,
      landingUrl: json['landing_url'] as String,
    );
  }

  @override
  List<Object?> get props => [id, title, adType, mediaUrl, landingUrl];
}

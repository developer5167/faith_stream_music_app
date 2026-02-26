import 'package:faith_stream_music_app/models/ad_model.dart';
import 'package:faith_stream_music_app/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdsService {
  final ApiClient _apiClient;
  static const String _lastAdPlayTimeKey = 'last_video_ad_play_time';

  AdsService(this._apiClient);

  Future<AdModel?> getNextAd(String type) async {
    try {
      final response = await _apiClient.get('/ads/next?type=$type');
      if (response.data != null) {
        return AdModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> trackAdEvent(String adId, String type) async {
    try {
      await _apiClient.post('/ads/track', data: {'adId': adId, 'type': type});
    } catch (e) {
      // Ignored
    }
  }

  Future<bool> shouldPlayVideoAd() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayStr = prefs.getString(_lastAdPlayTimeKey);

    // For testing/first time, if there's no last play time, we can decide to play one.
    // Let's say if no last play time, we play one.
    if (lastPlayStr == null) return true;

    final lastPlayTime = DateTime.tryParse(lastPlayStr);
    if (lastPlayTime == null) return true;

    // Check if 30 minutes have passed
    return DateTime.now().difference(lastPlayTime).inMinutes >= 30;
  }

  Future<void> markVideoAdPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAdPlayTimeKey, DateTime.now().toIso8601String());
  }
}

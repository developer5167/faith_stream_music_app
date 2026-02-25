import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';

class SharingService {
  static final String baseUrl =
      '${AppConfig.baseUrl}/share'; // Redirect service URL

  Future<void> shareSong({
    required String id,
    required String title,
    required String artist,
  }) async {
    final String url = '$baseUrl/song/$id';
    await Share.share(
      'Check out "$title" by $artist on FaithStream!\n\n$url',
      subject: 'FaithStream Song Share',
    );
  }

  Future<void> shareAlbum({
    required String id,
    required String title,
    required String artist,
  }) async {
    final String url = '$baseUrl/album/$id';
    await Share.share(
      'Listen to the album "$title" by $artist on FaithStream!\n\n$url',
      subject: 'FaithStream Album Share',
    );
  }

  Future<void> shareArtist({required String id, required String name}) async {
    final String url = '$baseUrl/artist/$id';
    await Share.share(
      'Follow $name on FaithStream for amazing gospel music!\n\n$url',
      subject: 'FaithStream Artist Share',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';

class SharingService {
  static final String baseUrl =
      '${AppConfig.baseUrl}/share'; // Redirect service URL

  // Helper to ensure iOS/iPadOS doesn't crash with zero or null coordinate rects
  Rect _getSafeOrigin(Rect? origin) {
    if (origin == null || origin.width == 0 || origin.height == 0) {
      // Fallback non-zero rect that will definitely be inside the screen
      return const Rect.fromLTWH(0, 0, 50, 50);
    }
    return origin;
  }

  Future<void> shareSong({
    required String id,
    required String title,
    required String artist,
    Rect? sharePositionOrigin,
  }) async {
    final String url = '$baseUrl/song/$id';
    await Share.share(
      'Check out "$title" by $artist on FaithStream!\n\n$url',
      subject: 'FaithStream Song Share',
      sharePositionOrigin: _getSafeOrigin(sharePositionOrigin),
    );
  }

  Future<void> shareAlbum({
    required String id,
    required String title,
    required String artist,
    Rect? sharePositionOrigin,
  }) async {
    final String url = '$baseUrl/album/$id';
    await Share.share(
      'Listen to the album "$title" by $artist on FaithStream!\n\n$url',
      subject: 'FaithStream Album Share',
      sharePositionOrigin: _getSafeOrigin(sharePositionOrigin),
    );
  }

  Future<void> shareArtist({
    required String id,
    required String name,
    Rect? sharePositionOrigin,
  }) async {
    final String url = '$baseUrl/artist/$id';
    await Share.share(
      'Follow $name on FaithStream for amazing gospel music!\n\n$url',
      subject: 'FaithStream Artist Share',
      sharePositionOrigin: _getSafeOrigin(sharePositionOrigin),
    );
  }
}

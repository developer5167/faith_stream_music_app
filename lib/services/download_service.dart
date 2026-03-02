import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

part 'download_service.g.dart';

// ── Hive Model ────────────────────────────────────────────────────────────────

@HiveType(typeId: 10)
class DownloadedSong extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String artistName;

  @HiveField(3)
  String localAudioPath;

  @HiveField(4)
  String? localCoverPath;

  @HiveField(5)
  String? coverImageUrl; // remote fallback

  @HiveField(6)
  String? albumTitle;

  @HiveField(7)
  DateTime downloadedAt;

  DownloadedSong({
    required this.id,
    required this.title,
    required this.artistName,
    required this.localAudioPath,
    this.localCoverPath,
    this.coverImageUrl,
    this.albumTitle,
    required this.downloadedAt,
  });

  /// Convert to a playable `Song` with a local file:// URL so the player works offline.
  Song toSong() => Song(
    id: id,
    title: title,
    audioUrl: 'file://$localAudioPath',
    coverImageUrl: localCoverPath != null
        ? 'file://$localCoverPath'
        : coverImageUrl,
    artistName: artistName,
    albumTitle: albumTitle,
  );
}

// ── Service ───────────────────────────────────────────────────────────────────

class DownloadService {
  static const _boxName = 'downloads';

  late Box<DownloadedSong> _box;
  final _dio = Dio();

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(DownloadedSongAdapter());
    }
    _box = await Hive.openBox<DownloadedSong>(_boxName);
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  bool isDownloaded(String songId) => _box.values.any((s) => s.id == songId);

  List<DownloadedSong> getDownloads() =>
      _box.values.toList()
        ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));

  int get downloadCount => _box.length;

  // ── Download ──────────────────────────────────────────────────────────────

  /// Downloads a song to local storage. Calls [onProgress] with 0.0–1.0.
  /// Returns true on success, false on failure.
  Future<bool> downloadSong(
    Song song, {
    required void Function(double progress) onProgress,
  }) async {
    if (song.audioUrl == null) return false;
    if (isDownloaded(song.id)) return true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final songsDir = Directory('${dir.path}/downloads/songs');
      final coversDir = Directory('${dir.path}/downloads/covers');
      await songsDir.create(recursive: true);
      await coversDir.create(recursive: true);

      // ── Download audio ─────────────────────────────────────────────────
      final audioPath = '${songsDir.path}/${song.id}.mp3';
      await _dio.download(
        song.audioUrl!,
        audioPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress((received / total).clamp(0.0, 1.0));
          }
        },
      );

      // ── Download cover image (optional, don't fail if it errors) ───────
      String? coverPath;
      if (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty) {
        try {
          coverPath = '${coversDir.path}/${song.id}.jpg';
          await _dio.download(song.coverImageUrl!, coverPath);
        } catch (_) {
          coverPath = null; // not critical
        }
      }

      // ── Persist to Hive ───────────────────────────────────────────────
      final downloaded = DownloadedSong(
        id: song.id,
        title: song.title,
        artistName: song.displayArtist,
        localAudioPath: audioPath,
        localCoverPath: coverPath,
        coverImageUrl: song.coverImageUrl,
        albumTitle: song.albumTitle,
        downloadedAt: DateTime.now(),
      );
      await _box.put(song.id, downloaded);
      return true;
    } catch (e) {
      // Clean up partial download
      try {
        final dir = await getApplicationDocumentsDirectory();
        final partial = File('${dir.path}/downloads/songs/${song.id}.mp3');
        if (await partial.exists()) await partial.delete();
      } catch (_) {}
      return false;
    }
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  Future<void> removeDownload(String songId) async {
    final item = _box.get(songId);
    if (item == null) return;

    // Delete local audio file
    try {
      final audio = File(item.localAudioPath);
      if (await audio.exists()) await audio.delete();
    } catch (_) {}

    // Delete local cover
    if (item.localCoverPath != null) {
      try {
        final cover = File(item.localCoverPath!);
        if (await cover.exists()) await cover.delete();
      } catch (_) {}
    }

    await _box.delete(songId);
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  Future<void> close() => _box.close();
}

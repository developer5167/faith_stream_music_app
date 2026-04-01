import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

enum RepeatMode { off, one, all }

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  List<Song> _playlist = [];
  int _currentIndex = 0;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffleEnabled = false;
  List<int> _shuffleIndices = [];

  // Getters
  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  int get currentIndex => _player.currentIndex ?? 0;
  Song? get currentSong =>
      (_playlist.isNotEmpty &&
          _player.currentIndex != null &&
          _player.currentIndex! < _playlist.length)
      ? _playlist[_player.currentIndex!]
      : null;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffleEnabled => _isShuffleEnabled;

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  AudioPlayerService() {
    _init();
  }

  void _init() async {
    // Request notification permission for Android 13+
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }

    // Configure audio session for background playback
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      print('Error configuring audio session: $e');
    }
  }

  bool _isAdPlaying = false;

  void setAdPlaying(bool value) {
    _isAdPlaying = value;
    if (value) {
      _player.pause();
    }
  }

  Future<void> playSong(Song song, {List<Song>? queue}) async {
    try {
      if (queue != null && queue.isNotEmpty) {
        _playlist = queue;
        _currentIndex = queue.indexOf(song);
        if (_currentIndex == -1) {
          _playlist.insert(0, song);
          _currentIndex = 0;
        }
      } else {
        _playlist = [song];
        _currentIndex = 0;
      }

      await _loadAndPlay(song);
    } catch (e) {
      print('Error playing song: $e');
      rethrow;
    }
  }

  Future<void> _loadAndPlay(Song song) async {
    if (song.audioUrl == null) {
      throw Exception('Song audio URL is null');
    }

    try {
      // Create a playlist of audio sources for lock screen skip controls
      final List<AudioSource> audioSources = _playlist.map((s) {
        // Offline downloaded song check
        if (s.audioUrl != null && s.audioUrl!.startsWith('file://')) {
          return AudioSource.uri(
            Uri.parse(s.audioUrl!),
            tag: MediaItem(
              id: s.id,
              title: s.title,
              artist: s.displayArtist,
              artUri: s.coverImageUrl != null
                  ? Uri.parse(s.coverImageUrl!)
                  : null,
            ),
          );
        }

        final String? processedUrl = s.audioProcessedUrl;
        final String? rawUrl = s.audioUrl;

        String finalUrl = '';
        if (processedUrl != null && processedUrl.isNotEmpty) {
          if (processedUrl.startsWith('http')) {
            finalUrl = processedUrl;
          } else {
            // It's a key. Try to construct it using the same domain as the original URL if possible
            if (rawUrl != null &&
                rawUrl.contains('amazonaws.com') &&
                rawUrl.contains('.s3.')) {
              final String bucketBase = rawUrl.substring(
                0,
                rawUrl.indexOf('amazonaws.com/') + 14,
              );
              finalUrl = '$bucketBase$processedUrl';
            } else {
              // Fallback to the production bucket identified in logs
              finalUrl =
                  'https://faithstream-songs-production.s3.ap-south-1.amazonaws.com/$processedUrl';
            }
          }
        } else {
          finalUrl = rawUrl ?? '';
        }

        return AudioSource.uri(
          Uri.parse(finalUrl),
          tag: MediaItem(
            id: s.id,
            title: s.title,
            artist: s.displayArtist,
            artUri: s.coverImageUrl != null
                ? Uri.parse(s.coverImageUrl!)
                : null,
          ),
        );
      }).toList();

      // Use ConcatenatingAudioSource for queue support
      final playlist = ConcatenatingAudioSource(children: audioSources);

      await _player.setAudioSource(
        playlist,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );

      if (!_isAdPlaying) {
        await _player.play();
      }
    } catch (e) {
      print('Error loading song: $e');
      rethrow;
    }
  }

  Future<void> play() async {
    if (!_isAdPlaying) {
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> skipToPrevious() async {
    // If song has been playing for more than 3 seconds, restart it
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        _player.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        _player.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    _player.setShuffleModeEnabled(_isShuffleEnabled);
  }

  Future<void> addToQueue(Song song) async {
    _playlist.add(song);

    // Add to audio source if it's the correct type
    if (_player.audioSource is ConcatenatingAudioSource) {
      final String? processedUrl = song.audioProcessedUrl;
      final String? rawUrl = song.audioUrl;

      String finalUrl = '';
      if (processedUrl != null && processedUrl.isNotEmpty) {
        if (processedUrl.startsWith('http')) {
          finalUrl = processedUrl;
        } else {
          // It's a key. Try to construct it using the same domain as the original URL if possible
          if (rawUrl != null &&
              rawUrl.contains('amazonaws.com') &&
              rawUrl.contains('.s3.')) {
            final String bucketBase = rawUrl.substring(
              0,
              rawUrl.indexOf('amazonaws.com/') + 14,
            );
            finalUrl = '$bucketBase$processedUrl';
          } else {
            // Fallback to the production bucket identified in logs
            finalUrl =
                'https://faithstream-songs-production.s3.ap-south-1.amazonaws.com/$processedUrl';
          }
        }
      } else {
        finalUrl = rawUrl ?? '';
      }

      final source = AudioSource.uri(
        Uri.parse(finalUrl),
        tag: MediaItem(
          id: song.id,
          title: song.title,
          artist: song.displayArtist,
          artUri: song.coverImageUrl != null
              ? Uri.parse(song.coverImageUrl!)
              : null,
        ),
      );

      final playlist = _player.audioSource as ConcatenatingAudioSource;
      await playlist.add(source);
    }
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    if (index == currentIndex) {
      // Can't remove currently playing song via this method for simplicity
      // In a real app, you'd handle this case more gracefully
      return;
    }

    _playlist.removeAt(index);

    if (_player.audioSource is ConcatenatingAudioSource) {
      final playlist = _player.audioSource as ConcatenatingAudioSource;
      await playlist.removeAt(index);
    }
  }

  void clearQueue() {
    _playlist.clear();
    _currentIndex = 0;
    _shuffleIndices.clear();
    _player.stop();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.5, 2.0));
  }

  void dispose() {
    _player.dispose();
  }
}

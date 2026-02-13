import 'package:just_audio/just_audio.dart';
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
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffleEnabled => _isShuffleEnabled;

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;

  AudioPlayerService() {
    _init();
  }

  void _init() {
    // Handle playback completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompleted();
      }
    });
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
      await _player.setUrl(song.audioUrl!);
      await _player.play();
    } catch (e) {
      print('Error loading song: $e');
      rethrow;
    }
  }

  Future<void> play() async {
    await _player.play();
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
    if (_playlist.isEmpty) return;

    if (_isShuffleEnabled) {
      _skipToNextShuffle();
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }

    await _loadAndPlay(_playlist[_currentIndex]);
  }

  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;

    // If song has been playing for more than 3 seconds, restart it
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_isShuffleEnabled) {
      _skipToPreviousShuffle();
    } else {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    }

    await _loadAndPlay(_playlist[_currentIndex]);
  }

  void _handleSongCompleted() {
    switch (_repeatMode) {
      case RepeatMode.one:
        // Replay current song
        _player.seek(Duration.zero);
        _player.play();
        break;
      case RepeatMode.all:
        // Skip to next song
        skipToNext();
        break;
      case RepeatMode.off:
        // Check if there's a next song
        if (_currentIndex < _playlist.length - 1) {
          skipToNext();
        } else {
          // Playlist ended
          _player.stop();
        }
        break;
    }
  }

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (_isShuffleEnabled) {
      _generateShuffleIndices();
    }
  }

  void _generateShuffleIndices() {
    _shuffleIndices = List.generate(_playlist.length, (index) => index);
    _shuffleIndices.shuffle();

    // Ensure current song stays as current
    final currentSongIndex = _shuffleIndices.indexOf(_currentIndex);
    if (currentSongIndex != 0) {
      final temp = _shuffleIndices[0];
      _shuffleIndices[0] = _shuffleIndices[currentSongIndex];
      _shuffleIndices[currentSongIndex] = temp;
    }
  }

  void _skipToNextShuffle() {
    if (_shuffleIndices.isEmpty) {
      _generateShuffleIndices();
    }

    final currentShufflePosition = _shuffleIndices.indexOf(_currentIndex);
    final nextShufflePosition =
        (currentShufflePosition + 1) % _shuffleIndices.length;
    _currentIndex = _shuffleIndices[nextShufflePosition];
  }

  void _skipToPreviousShuffle() {
    if (_shuffleIndices.isEmpty) {
      _generateShuffleIndices();
    }

    final currentShufflePosition = _shuffleIndices.indexOf(_currentIndex);
    final previousShufflePosition =
        (currentShufflePosition - 1 + _shuffleIndices.length) %
        _shuffleIndices.length;
    _currentIndex = _shuffleIndices[previousShufflePosition];
  }

  Future<void> addToQueue(Song song) async {
    _playlist.add(song);
    if (_isShuffleEnabled) {
      _generateShuffleIndices();
    }
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    if (index == _currentIndex) {
      // Can't remove currently playing song
      return;
    }

    _playlist.removeAt(index);

    if (index < _currentIndex) {
      _currentIndex--;
    }

    if (_isShuffleEnabled) {
      _generateShuffleIndices();
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

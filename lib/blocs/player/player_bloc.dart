import 'dart:async';
import 'package:faith_stream_music_app/models/song.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'player_event.dart';
import 'player_state.dart';
import '../../models/artist.dart';
import '../../services/audio_player_service.dart';
import '../../repositories/stream_repository.dart';
import '../../services/artist_service.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayerService _audioService;
  final StreamRepository _streamRepository;
  final ApiClient _apiClient;
  late final ArtistService _artistService;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _currentIndexSubscription;

  // ─── 30-second listen tracker ─────────────────────────────────────────────
  // Uses a 1-second periodic ticker instead of a one-shot timer so that
  // pause/resume works reliably: stopping the ticker preserves the counter,
  // restarting it picks up where it left off.
  //
  //  Song starts  → _startListenTicker()          (ticker counting up from 0)
  //  Pause        → _stopListenTicker()            (counter stays, ticker stops)
  //  Resume       → _startListenTicker()           (ticker restarts, counter continues)
  //  Skip / new   → _resetListenTicker()           (counter reset to 0, no count)
  //  30s reached  → logStream() fired once, ticker self-stops
  // ──────────────────────────────────────────────────────────────────────────
  Timer? _listenTicker;
  String? _currentSongId;
  int _listenedSeconds = 0; // cumulative seconds listened for current song
  bool _streamCounted = false; // ensures count fires only once per song play

  static const int _streamThreshold = 30;

  PlayerBloc({
    required AudioPlayerService audioService,
    required StreamRepository streamRepository,
    required StorageService storageService,
  }) : _audioService = audioService,
       _streamRepository = streamRepository,
       _apiClient = ApiClient(storageService),
       super(const PlayerInitial()) {
    _artistService = ArtistService(_apiClient);
    on<PlayerPlaySong>(_onPlaySong);
    on<PlayerPlay>(_onPlay);
    on<PlayerPause>(_onPause);
    on<PlayerStop>(_onStop);
    on<PlayerSeek>(_onSeek);
    on<PlayerSkipNext>(_onSkipNext);
    on<PlayerSkipPrevious>(_onSkipPrevious);
    on<PlayerToggleRepeat>(_onToggleRepeat);
    on<PlayerToggleShuffle>(_onToggleShuffle);
    on<PlayerUpdatePosition>(_onUpdatePosition);
    on<PlayerUpdateDuration>(_onUpdateDuration);
    on<PlayerUpdatePlayingState>(_onUpdatePlayingState);
    on<PlayerAddToQueue>(_onAddToQueue);
    on<PlayerRemoveFromQueue>(_onRemoveFromQueue);
    on<PlayerClearQueue>(_onClearQueue);
    on<PlayerSetVolume>(_onSetVolume);
    on<PlayerIndexChanged>(_onIndexChanged);

    _setupListeners();
  }

  // ─── Ticker helpers ───────────────────────────────────────────────────────

  /// Start (or resume) the 1-second ticker. Does nothing if already running.
  void _startListenTicker() {
    if (_listenTicker != null || _streamCounted) return;
    _listenTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_streamCounted) {
        _stopListenTicker();
        return;
      }
      _listenedSeconds++;
      if (_listenedSeconds >= _streamThreshold) {
        _streamCounted = true;
        _stopListenTicker();
        // Fire the stream count exactly once when 30 seconds reached
        if (_currentSongId != null) {
          _streamRepository.logStream(
            songId: _currentSongId!,
            durationListened: _streamThreshold,
          );
        }
      }
    });
  }

  /// Stop the ticker (counter is preserved so resume works correctly).
  void _stopListenTicker() {
    _listenTicker?.cancel();
    _listenTicker = null;
  }

  /// Reset the ticker completely for a new song.
  void _resetListenTicker() {
    _stopListenTicker();
    _listenedSeconds = 0;
    _streamCounted = false;
  }

  // ─── Audio-player event listeners ─────────────────────────────────────────

  void _setupListeners() {
    _positionSubscription = _audioService.positionStream.listen((position) {
      add(PlayerUpdatePosition(position));
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (duration != null) {
        add(PlayerUpdateDuration(duration));
      }
    });

    _playingSubscription = _audioService.playingStream.listen((isPlaying) {
      add(PlayerUpdatePlayingState(isPlaying));
    });

    _currentIndexSubscription = _audioService.currentIndexStream.listen((
      index,
    ) {
      if (index != null) {
        add(PlayerIndexChanged(index));
      }
    });
  }

  // ─── Event Handlers ───────────────────────────────────────────────────────

  Future<void> _onPlaySong(
    PlayerPlaySong event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      Song songToPlay = event.song;
      if (songToPlay.artistUserId != null && songToPlay.artist == null) {
        final Artist? artist = await _artistService.getArtistDetails(
          songToPlay.artistUserId!,
        );
        if (artist != null) {
          songToPlay = songToPlay.copyWith(artist: artist);
        }
      }

      List<Song>? updatedQueue = event.queue;
      if (updatedQueue != null && updatedQueue.isNotEmpty) {
        updatedQueue = await Future.wait(
          updatedQueue.map((song) async {
            if (song.artistUserId != null && song.artist == null) {
              final Artist? artist = await _artistService.getArtistDetails(
                song.artistUserId!,
              );
              if (artist != null) {
                return song.copyWith(artist: artist);
              }
            }
            return song;
          }),
        );
        final indexInQueue = updatedQueue.indexWhere(
          (s) => s.id == songToPlay.id,
        );
        if (indexInQueue != -1) {
          songToPlay = updatedQueue[indexInQueue];
        }
      }

      emit(PlayerLoading(song: songToPlay, queue: updatedQueue));

      // New song → reset the listen ticker
      _resetListenTicker();
      _currentSongId = songToPlay.id;

      await _audioService.playSong(songToPlay, queue: updatedQueue);

      // Update recently-played immediately (does NOT increment stream count)
      await _streamRepository.logRecentlyPlayed(songId: _currentSongId!);

      // Start the 30-second ticker for this new song
      _startListenTicker();
    } catch (e) {
      emit(PlayerError('Failed to play song: $e'));
    }
    // _onUpdatePlayingState transitions from PlayerLoading → PlayerPlaying
  }

  Future<void> _onPlay(PlayerPlay event, Emitter<PlayerState> emit) async {
    if (state is! PlayerPaused) return;
    final pausedState = state as PlayerPaused;
    await _audioService.play();

    // Resume the listen ticker from where it was paused
    _startListenTicker();

    emit(
      PlayerPlaying(
        song: pausedState.song,
        queue: pausedState.queue,
        currentIndex: pausedState.currentIndex,
        position: pausedState.position,
        duration: pausedState.duration,
        repeatMode: pausedState.repeatMode,
        isShuffleEnabled: pausedState.isShuffleEnabled,
        volume: pausedState.volume,
      ),
    );
  }

  Future<void> _onPause(PlayerPause event, Emitter<PlayerState> emit) async {
    if (state is! PlayerPlaying) return;
    final playingState = state as PlayerPlaying;

    await _audioService.pause();

    // Pause the ticker — counter is preserved for when we resume
    _stopListenTicker();

    emit(
      PlayerPaused(
        song: playingState.song,
        queue: playingState.queue,
        currentIndex: playingState.currentIndex,
        position: playingState.position,
        duration: playingState.duration,
        repeatMode: playingState.repeatMode,
        isShuffleEnabled: playingState.isShuffleEnabled,
        volume: playingState.volume,
      ),
    );
  }

  Future<void> _onStop(PlayerStop event, Emitter<PlayerState> emit) async {
    _resetListenTicker();
    _currentSongId = null;
    await _audioService.stop();
    emit(const PlayerStopped());
  }

  Future<void> _onSeek(PlayerSeek event, Emitter<PlayerState> emit) async {
    await _audioService.seek(event.position);
  }

  Future<void> _onSkipNext(
    PlayerSkipNext event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      await _audioService.skipToNext();
      // _onIndexChanged handles the rest via currentIndexStream
    } catch (e) {
      emit(PlayerError('Failed to skip to next: $e'));
    }
  }

  Future<void> _onSkipPrevious(
    PlayerSkipPrevious event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      await _audioService.skipToPrevious();
      // _onIndexChanged handles the rest via currentIndexStream
    } catch (e) {
      emit(PlayerError('Failed to skip to previous: $e'));
    }
  }

  void _onToggleRepeat(PlayerToggleRepeat event, Emitter<PlayerState> emit) {
    _audioService.toggleRepeatMode();
    if (state is PlayerPlaying) {
      emit(
        (state as PlayerPlaying).copyWith(repeatMode: _audioService.repeatMode),
      );
    } else if (state is PlayerPaused) {
      emit(
        (state as PlayerPaused).copyWith(repeatMode: _audioService.repeatMode),
      );
    }
  }

  void _onToggleShuffle(PlayerToggleShuffle event, Emitter<PlayerState> emit) {
    _audioService.toggleShuffle();
    if (state is PlayerPlaying) {
      emit(
        (state as PlayerPlaying).copyWith(
          isShuffleEnabled: _audioService.isShuffleEnabled,
        ),
      );
    } else if (state is PlayerPaused) {
      emit(
        (state as PlayerPaused).copyWith(
          isShuffleEnabled: _audioService.isShuffleEnabled,
        ),
      );
    }
  }

  void _onUpdatePosition(
    PlayerUpdatePosition event,
    Emitter<PlayerState> emit,
  ) {
    // Ignore position updates while a new song is loading to avoid
    // the stale end-of-last-song position filling the seek bar
    if (state is PlayerLoading) return;

    if (state is PlayerPlaying) {
      emit((state as PlayerPlaying).copyWith(position: event.position));
    } else if (state is PlayerPaused) {
      emit((state as PlayerPaused).copyWith(position: event.position));
    }
  }

  void _onUpdateDuration(
    PlayerUpdateDuration event,
    Emitter<PlayerState> emit,
  ) {
    // KEY FIX: when skipping while audio is already playing, playingStream
    // never re-emits true, so _onUpdatePlayingState never exits PlayerLoading.
    // durationStream fires reliably when a new song loads — use it instead.
    if (state is PlayerLoading) {
      final loadingState = state as PlayerLoading;
      if (loadingState.song != null) {
        final isPlaying = _audioService.player.playing;
        if (isPlaying) {
          emit(
            PlayerPlaying(
              song: loadingState.song!,
              queue: loadingState.queue ?? [loadingState.song!],
              currentIndex: _audioService.currentIndex,
              position: Duration.zero,
              duration: event.duration,
              repeatMode: _audioService.repeatMode,
              isShuffleEnabled: _audioService.isShuffleEnabled,
            ),
          );
        } else {
          emit(
            PlayerPaused(
              song: loadingState.song!,
              queue: loadingState.queue ?? [loadingState.song!],
              currentIndex: _audioService.currentIndex,
              position: Duration.zero,
              duration: event.duration,
              repeatMode: _audioService.repeatMode,
              isShuffleEnabled: _audioService.isShuffleEnabled,
            ),
          );
        }
      }
      return;
    }

    if (state is PlayerPlaying) {
      emit((state as PlayerPlaying).copyWith(duration: event.duration));
    } else if (state is PlayerPaused) {
      emit((state as PlayerPaused).copyWith(duration: event.duration));
    }
  }

  void _onUpdatePlayingState(
    PlayerUpdatePlayingState event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerInitial || state is PlayerStopped) return;

    final bool currentlyPlaying = event.isPlaying;

    // PlayerLoading → PlayerPlaying: audio just started for a new song
    if (currentlyPlaying && state is PlayerLoading) {
      final loadingState = state as PlayerLoading;
      if (loadingState.song != null) {
        final currentDuration = _audioService.player.duration ?? Duration.zero;
        emit(
          PlayerPlaying(
            song: loadingState.song!,
            queue: loadingState.queue ?? [loadingState.song!],
            currentIndex: _audioService.currentIndex,
            position: Duration.zero,
            duration: currentDuration,
            repeatMode: _audioService.repeatMode,
            isShuffleEnabled: _audioService.isShuffleEnabled,
          ),
        );
      }
      return;
    }

    // PlayerPaused → PlayerPlaying: system resume (headphones, lock screen, etc.)
    if (currentlyPlaying && state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      // Resume ticker if not already running (e.g., system-initiated resume)
      _startListenTicker();
      emit(
        PlayerPlaying(
          song: pausedState.song,
          queue: pausedState.queue,
          currentIndex: pausedState.currentIndex,
          position: pausedState.position,
          duration: pausedState.duration,
          repeatMode: pausedState.repeatMode,
          isShuffleEnabled: pausedState.isShuffleEnabled,
          volume: pausedState.volume,
        ),
      );
    }
    // PlayerPlaying → PlayerPaused: system pause (headphones disconnect, etc.)
    else if (!currentlyPlaying && state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
      // Stop ticker — counter preserved for when we resume
      _stopListenTicker();
      emit(
        PlayerPaused(
          song: playingState.song,
          queue: playingState.queue,
          currentIndex: playingState.currentIndex,
          position: playingState.position,
          duration: playingState.duration,
          repeatMode: playingState.repeatMode,
          isShuffleEnabled: playingState.isShuffleEnabled,
          volume: playingState.volume,
        ),
      );
    }
  }

  Future<void> _onAddToQueue(
    PlayerAddToQueue event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioService.addToQueue(event.song);
    if (state is PlayerPlaying) {
      emit((state as PlayerPlaying).copyWith(queue: _audioService.playlist));
    } else if (state is PlayerPaused) {
      emit((state as PlayerPaused).copyWith(queue: _audioService.playlist));
    }
  }

  Future<void> _onRemoveFromQueue(
    PlayerRemoveFromQueue event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioService.removeFromQueue(event.index);
    if (state is PlayerPlaying) {
      emit(
        (state as PlayerPlaying).copyWith(
          queue: _audioService.playlist,
          currentIndex: _audioService.currentIndex,
        ),
      );
    } else if (state is PlayerPaused) {
      emit(
        (state as PlayerPaused).copyWith(
          queue: _audioService.playlist,
          currentIndex: _audioService.currentIndex,
        ),
      );
    }
  }

  Future<void> _onClearQueue(
    PlayerClearQueue event,
    Emitter<PlayerState> emit,
  ) async {
    _resetListenTicker();
    _currentSongId = null;
    _audioService.clearQueue();
    emit(const PlayerStopped());
  }

  Future<void> _onIndexChanged(
    PlayerIndexChanged event,
    Emitter<PlayerState> emit,
  ) async {
    Song? currentSong = _audioService.currentSong;
    if (currentSong == null) return;

    final bool songChanged = (_currentSongId != currentSong.id);

    if (songChanged) {
      _resetListenTicker();
      _currentSongId = currentSong.id;
      await _streamRepository.logRecentlyPlayed(songId: _currentSongId!);
    }

    // Fetch artist details if not present
    if (currentSong.artistUserId != null && currentSong.artist == null) {
      final Artist? artist = await _artistService.getArtistDetails(
        currentSong.artistUserId!,
      );
      if (artist != null) {
        currentSong = currentSong.copyWith(artist: artist);
      }
    }

    final isPlaying = _audioService.player.playing;

    // Always emit a concrete state immediately so the UI is never stuck.
    // position: Duration.zero resets the seek bar for the new song.
    // durationStream will fire shortly with the actual duration and update it.
    if (isPlaying) {
      emit(
        PlayerPlaying(
          song: currentSong,
          queue: _audioService.playlist,
          currentIndex: event.index,
          position: Duration.zero,
          duration: _audioService.player.duration ?? Duration.zero,
          repeatMode: _audioService.repeatMode,
          isShuffleEnabled: _audioService.isShuffleEnabled,
        ),
      );
      // Start the listen ticker for the new song (only if song actually changed)
      if (songChanged) _startListenTicker();
    } else {
      emit(
        PlayerPaused(
          song: currentSong,
          queue: _audioService.playlist,
          currentIndex: event.index,
          position: Duration.zero,
          duration: _audioService.player.duration ?? Duration.zero,
          repeatMode: _audioService.repeatMode,
          isShuffleEnabled: _audioService.isShuffleEnabled,
        ),
      );
    }
  }

  Future<void> _onSetVolume(
    PlayerSetVolume event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioService.setVolume(event.volume);
    if (state is PlayerPlaying) {
      emit((state as PlayerPlaying).copyWith(volume: event.volume));
    } else if (state is PlayerPaused) {
      emit((state as PlayerPaused).copyWith(volume: event.volume));
    }
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _resetListenTicker(); // no count on close
    _audioService.dispose();
    return super.close();
  }
}

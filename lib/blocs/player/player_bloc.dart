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

  DateTime? _playStartTime;
  String? _currentSongId;

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

  Future<void> _onPlaySong(
    PlayerPlaySong event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      // Fetch artist details for the song to play if not already present
      Song songToPlay = event.song;
      if (songToPlay.artistUserId != null && songToPlay.artist == null) {
        final Artist? artist = await _artistService.getArtistDetails(
          songToPlay.artistUserId!,
        );
        if (artist != null) {
          songToPlay = songToPlay.copyWith(artist: artist);
        }
      }

      // Update queue with artist details if queue is provided
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
        // Update songToPlay to match the one in the queue if it exists
        final indexInQueue = updatedQueue.indexWhere(
          (s) => s.id == songToPlay.id,
        );
        if (indexInQueue != -1) {
          songToPlay = updatedQueue[indexInQueue];
        }
      }

      // Emit loading state with the song that has artist details
      emit(PlayerLoading(song: songToPlay, queue: updatedQueue));

      // Log previous song stream if exists
      if (_currentSongId != null && _playStartTime != null) {
        final duration = DateTime.now().difference(_playStartTime!).inSeconds;
        await _streamRepository.logStream(
          songId: _currentSongId!,
          durationListened: duration,
        );
      }

      await _audioService.playSong(songToPlay, queue: updatedQueue);

      _currentSongId = songToPlay.id;
      _playStartTime = DateTime.now();

      // Log current song immediately for "Recently Played" history
      await _streamRepository.logStream(
        songId: _currentSongId!,
        durationListened: 0,
      );

      // Check if audio is already playing (might happen if it starts very quickly)
      // If so, transition to PlayerPlaying immediately
      // Otherwise, wait for _onUpdatePlayingState to handle the transition
      final isPlaying = _audioService.player.playing;
      if (isPlaying) {
        // Get current position and duration if available
        final position = _audioService.player.position;
        final duration = _audioService.player.duration ?? Duration.zero;

        emit(
          PlayerPlaying(
            song: songToPlay,
            queue: updatedQueue ?? [songToPlay],
            currentIndex: _audioService.currentIndex,
            position: position,
            duration: duration,
            repeatMode: _audioService.repeatMode,
            isShuffleEnabled: _audioService.isShuffleEnabled,
          ),
        );
      }
      // If not playing yet, _onUpdatePlayingState will handle the transition when playingStream emits true
    } catch (e) {
      emit(PlayerError('Failed to play song: $e'));
    }
  }

  Future<void> _onPlay(PlayerPlay event, Emitter<PlayerState> emit) async {
    if (state is PlayerPaused) {
      await _audioService.play();
      final pausedState = state as PlayerPaused;
      _playStartTime = DateTime.now();

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
  }

  Future<void> _onPause(PlayerPause event, Emitter<PlayerState> emit) async {
    // Snapshot the current playing state BEFORE awaiting, to avoid race conditions
    if (state is! PlayerPlaying) return;

    final playingState = state as PlayerPlaying;

    await _audioService.pause();

    // Log stream when paused
    if (_currentSongId != null && _playStartTime != null) {
      final duration = DateTime.now().difference(_playStartTime!).inSeconds;
      if (duration > 5) {
        await _streamRepository.logStream(
          songId: _currentSongId!,
          durationListened: duration,
        );
      }
    }

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
    // Log stream when stopped
    if (_currentSongId != null && _playStartTime != null) {
      final duration = DateTime.now().difference(_playStartTime!).inSeconds;
      if (duration > 5) {
        await _streamRepository.logStream(
          songId: _currentSongId!,
          durationListened: duration,
        );
      }
    }

    await _audioService.stop();
    _currentSongId = null;
    _playStartTime = null;
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
      // State update is handled by _onIndexChanged via currentIndexStream
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
      // State update is handled by _onIndexChanged via currentIndexStream
    } catch (e) {
      emit(PlayerError('Failed to skip to previous: $e'));
    }
  }

  void _onToggleRepeat(PlayerToggleRepeat event, Emitter<PlayerState> emit) {
    _audioService.toggleRepeatMode();

    if (state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
      emit(playingState.copyWith(repeatMode: _audioService.repeatMode));
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(pausedState.copyWith(repeatMode: _audioService.repeatMode));
    }
  }

  void _onToggleShuffle(PlayerToggleShuffle event, Emitter<PlayerState> emit) {
    _audioService.toggleShuffle();

    if (state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
      emit(
        playingState.copyWith(isShuffleEnabled: _audioService.isShuffleEnabled),
      );
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(
        pausedState.copyWith(isShuffleEnabled: _audioService.isShuffleEnabled),
      );
    }
  }

  void _onUpdatePosition(
    PlayerUpdatePosition event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
      emit(playingState.copyWith(position: event.position));
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(pausedState.copyWith(position: event.position));
    }
  }

  void _onUpdateDuration(
    PlayerUpdateDuration event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
      emit(playingState.copyWith(duration: event.duration));
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(pausedState.copyWith(duration: event.duration));
    }
  }

  void _onUpdatePlayingState(
    PlayerUpdatePlayingState event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerInitial || state is PlayerStopped) return;

    final bool currentlyPlaying = event.isPlaying;

    // Handle transition from PlayerLoading to PlayerPlaying
    if (currentlyPlaying && state is PlayerLoading) {
      final loadingState = state as PlayerLoading;
      if (loadingState.song != null) {
        _playStartTime = DateTime.now();
        // Try to use the current player's duration if it's already known,
        // otherwise fall back to zero and let the duration stream update it.
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

    if (currentlyPlaying && state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      _playStartTime = DateTime.now();
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
    } else if (!currentlyPlaying && state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
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
      final playingState = state as PlayerPlaying;
      emit(playingState.copyWith(queue: _audioService.playlist));
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(pausedState.copyWith(queue: _audioService.playlist));
    }
  }

  Future<void> _onRemoveFromQueue(
    PlayerRemoveFromQueue event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioService.removeFromQueue(event.index);

    if (state is PlayerPlaying) {
      final playingState = state as PlayerPlaying;
      emit(
        playingState.copyWith(
          queue: _audioService.playlist,
          currentIndex: _audioService.currentIndex,
        ),
      );
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(
        pausedState.copyWith(
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
    _audioService.clearQueue();
    _currentSongId = null;
    _playStartTime = null;
    emit(const PlayerStopped());
  }

  Future<void> _onIndexChanged(
    PlayerIndexChanged event,
    Emitter<PlayerState> emit,
  ) async {
    Song? currentSong = _audioService.currentSong;
    if (currentSong == null) return;

    // Check if song actually changed to avoid redundant updates
    // (except for initial load or if we want to ensure state consistency)
    if (_currentSongId == currentSong.id && state is PlayerPlaying) {
      // Logic to handle seek/restart within same song if needed,
      // but generally we can skip full reload if ID matches.
      // However, if we went Next -> Previous -> Next, we might be back at same song
      // but we still want to update UI if it was transient.
      // For now, let's allow update to ensure UI is in sync.
      // But verify if we need to log stream.
    }

    // Log previous song stream if ID changes
    if (_currentSongId != null &&
        _currentSongId != currentSong.id &&
        _playStartTime != null) {
      final duration = DateTime.now().difference(_playStartTime!).inSeconds;
      await _streamRepository.logStream(
        songId: _currentSongId!,
        durationListened: duration,
      );
      _playStartTime = DateTime.now(); // Reset start time for new song
    } else if (_playStartTime == null) {
      _playStartTime = DateTime.now();
    }

    _currentSongId = currentSong.id;

    // Log current song immediately for "Recently Played" history
    await _streamRepository.logStream(
      songId: _currentSongId!,
      durationListened: 0,
    );

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

    // We emit PlayerPlaying or PlayerPaused based on current state or service state
    // If service says playing, we emit playing.

    if (isPlaying) {
      emit(
        PlayerPlaying(
          song: currentSong,
          queue: _audioService.playlist,
          currentIndex: event.index,
          position: Duration.zero, // Reset position visuals for new song
          duration: _audioService.player.duration ?? Duration.zero,
          repeatMode: _audioService.repeatMode,
          isShuffleEnabled: _audioService.isShuffleEnabled,
        ),
      );
    } else {
      // If paused, we still update the song view
      emit(
        PlayerPaused(
          song: currentSong,
          queue: _audioService.playlist,
          currentIndex: event.index,
          position: Duration.zero,
          duration: Duration.zero,
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
      final playingState = state as PlayerPlaying;
      emit(playingState.copyWith(volume: event.volume));
    } else if (state is PlayerPaused) {
      final pausedState = state as PlayerPaused;
      emit(pausedState.copyWith(volume: event.volume));
    }
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    _currentIndexSubscription?.cancel();

    // Log final stream before closing
    if (_currentSongId != null && _playStartTime != null) {
      final duration = DateTime.now().difference(_playStartTime!).inSeconds;
      if (duration > 5) {
        _streamRepository.logStream(
          songId: _currentSongId!,
          durationListened: duration,
        );
      }
    }

    _audioService.dispose();
    return super.close();
  }
}

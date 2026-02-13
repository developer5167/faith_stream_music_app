import 'package:equatable/equatable.dart';
import '../../models/song.dart';
import '../../services/audio_player_service.dart';

abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

class PlayerInitial extends PlayerState {
  const PlayerInitial();
}

class PlayerLoading extends PlayerState {
  final Song? song;
  final List<Song>? queue;

  const PlayerLoading({this.song, this.queue});

  @override
  List<Object?> get props => [song, queue];
}

class PlayerPlaying extends PlayerState {
  final Song song;
  final List<Song> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool isShuffleEnabled;
  final double volume;

  const PlayerPlaying({
    required this.song,
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.duration,
    required this.repeatMode,
    required this.isShuffleEnabled,
    this.volume = 1.0,
  });

  @override
  List<Object?> get props => [
    song,
    queue,
    currentIndex,
    position,
    duration,
    repeatMode,
    isShuffleEnabled,
    volume,
  ];

  PlayerPlaying copyWith({
    Song? song,
    List<Song>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    RepeatMode? repeatMode,
    bool? isShuffleEnabled,
    double? volume,
  }) {
    return PlayerPlaying(
      song: song ?? this.song,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      volume: volume ?? this.volume,
    );
  }
}

class PlayerPaused extends PlayerState {
  final Song song;
  final List<Song> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool isShuffleEnabled;
  final double volume;

  const PlayerPaused({
    required this.song,
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.duration,
    required this.repeatMode,
    required this.isShuffleEnabled,
    this.volume = 1.0,
  });

  @override
  List<Object?> get props => [
    song,
    queue,
    currentIndex,
    position,
    duration,
    repeatMode,
    isShuffleEnabled,
    volume,
  ];

  PlayerPaused copyWith({
    Song? song,
    List<Song>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    RepeatMode? repeatMode,
    bool? isShuffleEnabled,
    double? volume,
  }) {
    return PlayerPaused(
      song: song ?? this.song,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      volume: volume ?? this.volume,
    );
  }
}

class PlayerStopped extends PlayerState {
  const PlayerStopped();
}

class PlayerError extends PlayerState {
  final String message;

  const PlayerError(this.message);

  @override
  List<Object?> get props => [message];
}

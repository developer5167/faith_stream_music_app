import 'package:equatable/equatable.dart';
import '../../models/song.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerPlaySong extends PlayerEvent {
  final Song song;
  final List<Song>? queue;

  const PlayerPlaySong(this.song, {this.queue});

  @override
  List<Object?> get props => [song, queue];
}

class PlayerPlay extends PlayerEvent {
  const PlayerPlay();
}

class PlayerPause extends PlayerEvent {
  const PlayerPause();
}

class PlayerStop extends PlayerEvent {
  const PlayerStop();
}

class PlayerSeek extends PlayerEvent {
  final Duration position;

  const PlayerSeek(this.position);

  @override
  List<Object?> get props => [position];
}

class PlayerSkipNext extends PlayerEvent {
  const PlayerSkipNext();
}

class PlayerSkipPrevious extends PlayerEvent {
  const PlayerSkipPrevious();
}

class PlayerToggleRepeat extends PlayerEvent {
  const PlayerToggleRepeat();
}

class PlayerToggleShuffle extends PlayerEvent {
  const PlayerToggleShuffle();
}

class PlayerUpdatePosition extends PlayerEvent {
  final Duration position;

  const PlayerUpdatePosition(this.position);

  @override
  List<Object?> get props => [position];
}

class PlayerUpdateDuration extends PlayerEvent {
  final Duration duration;

  const PlayerUpdateDuration(this.duration);

  @override
  List<Object?> get props => [duration];
}

class PlayerUpdatePlayingState extends PlayerEvent {
  final bool isPlaying;

  const PlayerUpdatePlayingState(this.isPlaying);

  @override
  List<Object?> get props => [isPlaying];
}

class PlayerAddToQueue extends PlayerEvent {
  final Song song;

  const PlayerAddToQueue(this.song);

  @override
  List<Object?> get props => [song];
}

class PlayerRemoveFromQueue extends PlayerEvent {
  final int index;

  const PlayerRemoveFromQueue(this.index);

  @override
  List<Object?> get props => [index];
}

class PlayerClearQueue extends PlayerEvent {
  const PlayerClearQueue();
}

class PlayerSetVolume extends PlayerEvent {
  final double volume;

  const PlayerSetVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

class PlayerIndexChanged extends PlayerEvent {
  final int index;

  const PlayerIndexChanged(this.index);

  @override
  List<Object?> get props => [index];
}

import 'package:faith_stream_music_app/models/artist.dart';
import 'package:faith_stream_music_app/models/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../blocs/player/player_state.dart';
import '../../services/audio_player_service.dart';
import '../../utils/constants.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PlayerBloc, PlayerState>(
        buildWhen: (previous, current) {
          // Rebuild on any state change to ensure UI updates immediately
          return true;
        },
        builder: (context, state) {
          if (state is! PlayerPlaying &&
              state is! PlayerPaused &&
              !(state is PlayerLoading && state.song != null)) {
            return const Center(child: Text('No song playing'));
          }

          final song = state is PlayerLoading
              ? state.song!
              : (state is PlayerPlaying
                    ? state.song
                    : (state as PlayerPaused).song);
          final position = state is PlayerPlaying
              ? (state).position
              : (state is PlayerPaused ? (state).position : Duration.zero);
          final duration = state is PlayerPlaying
              ? (state).duration
              : (state is PlayerPaused ? (state).duration : Duration.zero);
          final isPlaying = state is PlayerPlaying;
          final repeatMode = state is PlayerPlaying
              ? (state).repeatMode
              : (state is PlayerPaused ? (state).repeatMode : RepeatMode.off);
          final isShuffleEnabled = state is PlayerPlaying
              ? (state).isShuffleEnabled
              : (state is PlayerPaused ? (state).isShuffleEnabled : false);
          final isLoading = state is PlayerLoading;

          return _buildPlayerUI(
            context,
            song,
            position,
            duration,
            isPlaying,
            repeatMode,
            isShuffleEnabled,
            isLoading: isLoading,
          );
        },
      ),
    );
  }

  Widget _buildPlayerUI(
    BuildContext context,
    Song song,
    Duration position,
    Duration duration,
    bool isPlaying,
    RepeatMode repeatMode,
    bool isShuffleEnabled, {
    bool isLoading = false,
  }) {
    final Artist? artist = song.artist; // Get the artist object

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBrown.withOpacity(0.8),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSizes.paddingXl),
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Now Playing',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        // TODO: Show more options
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingLg),

              // Album art
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingXl,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: song.coverImageUrl != null
                        ? Image.network(
                            song.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primaryBrown.withOpacity(0.2),
                                child: const Icon(
                                  Icons.music_note,
                                  size: 100,
                                  color: AppColors.primaryBrown,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.primaryBrown.withOpacity(0.2),
                            child: const Icon(
                              Icons.music_note,
                              size: 100,
                              color: AppColors.primaryBrown,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.paddingXl),

              // Song info
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLg,
                ),
                child: Column(
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (artist?.profilePicUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSizes.paddingXs,
                            ),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(
                                artist!.profilePicUrl!,
                              ),
                              onBackgroundImageError: (exception, stackTrace) {
                                // Handle image loading error silently
                              },
                              child: artist.profilePicUrl == null
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            song.displayArtist,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLg,
                ),
                child: Column(
                  children: [
                    _SeekBar(
                      position: position,
                      duration: duration,
                      isPlaying: isPlaying,
                      isLoading: isLoading,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            _formatDuration(duration),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingLg),

              // Main controls
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingXl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: isShuffleEnabled
                            ? AppColors.primaryBrown
                            : Colors.grey,
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<PlayerBloc>().add(
                                const PlayerToggleShuffle(),
                              );
                            },
                    ),

                    // Previous
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 40),
                      color: AppColors.primaryBrown,
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<PlayerBloc>().add(
                                const PlayerSkipPrevious(),
                              );
                            },
                    ),

                    // Play/Pause
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryBrown,
                      ),
                      child: isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 40,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  context.read<PlayerBloc>().add(
                                    const PlayerPause(),
                                  );
                                } else {
                                  context.read<PlayerBloc>().add(
                                    const PlayerPlay(),
                                  );
                                }
                              },
                            ),
                    ),

                    // Next
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 40),
                      color: AppColors.primaryBrown,
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<PlayerBloc>().add(
                                const PlayerSkipNext(),
                              );
                            },
                    ),

                    // Repeat
                    IconButton(
                      icon: Icon(
                        repeatMode == RepeatMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: repeatMode != RepeatMode.off
                            ? AppColors.primaryBrown
                            : Colors.grey,
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<PlayerBloc>().add(
                                const PlayerToggleRepeat(),
                              );
                            },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingLg),

              // Secondary controls
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingXl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: isLoading
                          ? null
                          : () {
                              // TODO: Add to favorites
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.playlist_add),
                      onPressed: isLoading
                          ? null
                          : () {
                              // TODO: Add to playlist
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music),
                      onPressed: isLoading
                          ? null
                          : () {
                              // TODO: Show queue
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: isLoading
                          ? null
                          : () {
                              // TODO: Share song
                            },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingLg),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '$minutes:${twoDigits(seconds)}';
  }
}

class _SeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;

  const _SeekBar({
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isLoading,
  });

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  bool _isDragging = false;
  double? _dragValue;
  bool _wasPlayingBeforeDrag = false;

  @override
  Widget build(BuildContext context) {
    final durationMs = widget.duration.inMilliseconds.toDouble();
    final positionMs = widget.position.inMilliseconds.toDouble();

    final max = durationMs > 0
        ? durationMs
        : (positionMs > 0 ? positionMs : 1.0); // avoid max=0

    final currentValue = _isDragging
        ? (_dragValue ?? positionMs)
        : (durationMs > 0 ? positionMs : 0.0);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: AppColors.primaryBrown,
        inactiveTrackColor: Colors.grey[300],
        thumbColor: AppColors.primaryBrown,
        overlayColor: AppColors.primaryBrown.withOpacity(0.2),
      ),
      child: Slider(
        value: currentValue.clamp(0.0, max),
        min: 0,
        max: max,
        onChangeStart: (value) {
          if (widget.isLoading) return;

          setState(() {
            _isDragging = true;
            _dragValue = value;
            _wasPlayingBeforeDrag = widget.isPlaying;
          });

          if (widget.isPlaying) {
            context.read<PlayerBloc>().add(const PlayerPause());
          }
        },
        onChanged: (value) {
          if (!_isDragging || widget.isLoading) return;
          setState(() {
            _dragValue = value;
          });
        },
        onChangeEnd: (value) {
          if (!_isDragging || widget.isLoading) return;

          final targetMs = (_dragValue ?? value).toInt();
          final targetPosition = Duration(milliseconds: targetMs);

          context.read<PlayerBloc>().add(PlayerSeek(targetPosition));

          if (_wasPlayingBeforeDrag && !widget.isLoading) {
            context.read<PlayerBloc>().add(const PlayerPlay());
          }

          setState(() {
            _isDragging = false;
            _dragValue = null;
          });
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../blocs/player/player_state.dart';
import '../../utils/constants.dart';
import '../screens/now_playing_screen.dart';
import '../../config/app_theme.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        // Show mini-player if playing, paused, or loading a song
        if (state is PlayerPlaying ||
            state is PlayerPaused ||
            (state is PlayerLoading && state.song != null)) {
          final song = state is PlayerLoading
              ? state.song!
              : (state is PlayerPlaying
                    ? state.song
                    : (state as PlayerPaused).song);
          final position = state is PlayerPlaying
              ? (state as PlayerPlaying).position
              : (state is PlayerPaused
                    ? (state as PlayerPaused).position
                    : Duration.zero); // Default to zero for loading
          final duration = state is PlayerPlaying
              ? (state as PlayerPlaying).duration
              : (state is PlayerPaused
                    ? (state as PlayerPaused).duration
                    : Duration.zero); // Default to zero for loading
          final isPlaying = state is PlayerPlaying;
          final isLoading = state is PlayerLoading;

          final progress = duration.inMilliseconds > 0
              ? position.inMilliseconds / duration.inMilliseconds
              : 0.0;

          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FractionallySizedBox(
                  heightFactor: 1.0,
                  child: NowPlayingScreen(),
                ),
              );
            },
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Progress bar
                  LinearProgressIndicator(
                    value: isLoading
                        ? 0.0
                        : progress, // Show no progress during loading
                    minHeight: 2,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(
                      0.1,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                    ),
                  ),
                  // Player controls
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMd,
                      ),
                      child: Row(
                        children: [
                          // Album art
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: song.coverImageUrl != null
                                ? Image.network(
                                    song.coverImageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 48,
                                        height: 48,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.2),
                                        child: Icon(
                                          Icons.music_note,
                                          color: theme.colorScheme.primary,
                                          size: 24,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
                                    child: Icon(
                                      Icons.music_note,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: AppSizes.paddingSm),

                          // Song info
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song.displayArtist,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Controls
                          if (isLoading)
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark
                                      ? AppTheme.darkPrimary
                                      : AppTheme.lightPrimary,
                                ),
                              ),
                            )
                          else ...[
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              color: theme.colorScheme.onSurface,
                              onPressed: () {
                                context.read<PlayerBloc>().add(
                                  const PlayerSkipPrevious(),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 32,
                              ),
                              color: theme.colorScheme.onSurface,
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
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              color: theme.colorScheme.onSurface,
                              onPressed: () {
                                context.read<PlayerBloc>().add(
                                  const PlayerSkipNext(),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

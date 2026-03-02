import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../blocs/player/player_state.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../utils/constants.dart';
import '../screens/now_playing_screen.dart';
import '../../config/app_theme.dart';
import 'cover_image.dart'; // New import

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
                            child: CoverImage(
                              url: song.coverImageUrl,
                              width: 48,
                              height: 48,
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
                            // Skip Previous — premium only
                            Builder(
                              builder: (context) {
                                final profileState = context
                                    .read<ProfileBloc>()
                                    .state;
                                final isPremium =
                                    profileState is ProfileLoaded &&
                                    (profileState.subscription?.isActive ??
                                        false);
                                return IconButton(
                                  icon: Icon(
                                    Icons.skip_previous,
                                    color: isPremium
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.3),
                                  ),
                                  onPressed: isPremium
                                      ? () => context.read<PlayerBloc>().add(
                                          const PlayerSkipPrevious(),
                                        )
                                      : () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Upgrade to Premium to skip songs',
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
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
                            // Skip Next — premium only
                            Builder(
                              builder: (context) {
                                final profileState = context
                                    .read<ProfileBloc>()
                                    .state;
                                final isPremium =
                                    profileState is ProfileLoaded &&
                                    (profileState.subscription?.isActive ??
                                        false);
                                return IconButton(
                                  icon: Icon(
                                    Icons.skip_next,
                                    color: isPremium
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.3),
                                  ),
                                  onPressed: isPremium
                                      ? () => context.read<PlayerBloc>().add(
                                          const PlayerSkipNext(),
                                        )
                                      : () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Upgrade to Premium to skip songs',
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
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

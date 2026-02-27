import 'package:faith_stream_music_app/models/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../blocs/player/player_state.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../services/audio_player_service.dart';
import '../../config/app_theme.dart';
import '../widgets/playlist_selection_sheet.dart';
import '../widgets/gradient_background.dart';
import '../widgets/ad_overlay.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _isDragging = false;
  double _dragValue = 0;
  bool _wasPlayingBeforeDrag = false;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocBuilder<PlayerBloc, PlayerState>(
          builder: (context, state) {
            if (state is! PlayerPlaying &&
                state is! PlayerPaused &&
                !(state is PlayerLoading && state.song != null)) {
              return const Center(
                child: Text(
                  'No song playing',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            final song = state is PlayerLoading
                ? state.song!
                : (state is PlayerPlaying
                      ? state.song
                      : (state as PlayerPaused).song);

            final position = state is PlayerPlaying
                ? state.position
                : (state is PlayerPaused ? state.position : Duration.zero);

            final duration = state is PlayerPlaying
                ? state.duration
                : (state is PlayerPaused ? state.duration : Duration.zero);

            final isPlaying = state is PlayerPlaying;
            final repeatMode = state is PlayerPlaying
                ? state.repeatMode
                : (state is PlayerPaused ? state.repeatMode : RepeatMode.off);

            final isShuffleEnabled = state is PlayerPlaying
                ? state.isShuffleEnabled
                : (state is PlayerPaused ? state.isShuffleEnabled : false);

            final isLoading = state is PlayerLoading;

            return _buildScrollableUI(
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
      ),
    );
  }

  Widget _buildScrollableUI(
    BuildContext context,
    Song song,
    Duration position,
    Duration duration,
    bool isPlaying,
    RepeatMode repeatMode,
    bool isShuffleEnabled, {
    bool isLoading = false,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Player section (fills the whole screen) ────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: screenHeight,
            child: _buildPlayerUI(
              context,
              song,
              position,
              duration,
              isPlaying,
              repeatMode,
              isShuffleEnabled,
              isLoading: isLoading,
            ),
          ),
        ),

        // ── Scroll hint ────────────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildScrollHint(context)),

        // ── Lyrics section ─────────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildLyricsSection(context, song)),
      ],
    );
  }

  /// A small visual cue at the bottom that tells the user they can scroll down
  Widget _buildScrollHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white38,
            size: 28,
          ),
          Text(
            'Lyrics',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLyricsSection(BuildContext context, Song song) {
    final theme = Theme.of(context);
    final hasLyrics = song.lyrics != null && song.lyrics!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.lyrics_outlined,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Lyrics',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
          const SizedBox(height: 16),

          // Lyrics content
          if (hasLyrics)
            Text(
              song.lyrics!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 2.0,
                fontSize: 15,
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.lyrics_outlined,
                      color: Colors.white24,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No lyrics available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    final profileState = context.watch<ProfileBloc>().state;
    final isPremium =
        profileState is ProfileLoaded &&
        profileState.subscription != null &&
        profileState.subscription!.isActive;

    return SafeArea(
      bottom: false, // CustomScrollView handles bottom padding/lyrics
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurface,
                    size: 32,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'PLAYING FROM ALBUM',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        song.albumTitle ?? 'Single',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Spacer to balance the back button
              ],
            ),
          ),

          const Spacer(),

          // Album Art
          Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: isPremium
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: song.coverImageUrl != null
                              ? Image.network(
                                  song.coverImageUrl!,
                                  width: size.width * 0.85,
                                  height: size.width * 0.85,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholderArt(size),
                                )
                              : _buildPlaceholderArt(size),
                        )
                      : AdOverlay(
                          key: ValueKey('ad_${song.id}'),
                          songId: song.id,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: song.coverImageUrl != null
                                ? Image.network(
                                    song.coverImageUrl!,
                                    width: size.width * 0.85,
                                    height: size.width * 0.85,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderArt(size),
                                  )
                                : _buildPlaceholderArt(size),
                          ),
                        ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),

          const Spacer(),

          // Song Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.displayArtist,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                BlocBuilder<LibraryBloc, LibraryState>(
                  builder: (context, state) {
                    final isFavorite =
                        state is LibraryLoaded && state.isFavorite(song.id);
                    return IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? AppTheme.darkPrimary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                        size: 28,
                      ),
                      onPressed: () {
                        context.read<LibraryBloc>().add(
                          LibraryToggleFavorite(song),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: isPremium
                        ? theme.colorScheme.onSurface
                        : Colors.grey,
                    inactiveTrackColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.1,
                    ),
                    thumbColor: isPremium
                        ? theme.colorScheme.onSurface
                        : Colors.grey,
                    overlayColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.1,
                    ),
                  ),
                  child: Slider(
                    value: _isDragging
                        ? _dragValue
                        : position.inSeconds.toDouble().clamp(
                            0.0,
                            (duration.inSeconds.toDouble() > 0
                                ? duration.inSeconds.toDouble()
                                : 1.0),
                          ),
                    max: duration.inSeconds.toDouble() > 0
                        ? duration.inSeconds.toDouble()
                        : 1.0,
                    onChangeStart: isPremium
                        ? (value) {
                            setState(() {
                              _isDragging = true;
                              _dragValue = value;
                              _wasPlayingBeforeDrag = isPlaying;
                            });
                            if (isPlaying) {
                              context.read<PlayerBloc>().add(
                                const PlayerPause(),
                              );
                            }
                          }
                        : null,
                    onChanged: isPremium
                        ? (value) {
                            setState(() {
                              _dragValue = value;
                            });
                          }
                        : null,
                    onChangeEnd: isPremium
                        ? (value) {
                            context.read<PlayerBloc>().add(
                              PlayerSeek(Duration(seconds: value.toInt())),
                            );
                            if (_wasPlayingBeforeDrag) {
                              context.read<PlayerBloc>().add(
                                const PlayerPlay(),
                              );
                            }
                            setState(() {
                              _isDragging = false;
                            });
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(
                          _isDragging
                              ? Duration(seconds: _dragValue.toInt())
                              : position,
                        ),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: isShuffleEnabled
                        ? (isDark
                              ? AppTheme.darkPrimary
                              : AppTheme.lightPrimary)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () => context.read<PlayerBloc>().add(
                    const PlayerToggleShuffle(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: isPremium
                        ? theme.colorScheme.onSurface
                        : Colors.grey.withOpacity(0.5),
                    size: 48,
                  ),
                  onPressed: isPremium
                      ? () => context.read<PlayerBloc>().add(
                          const PlayerSkipPrevious(),
                        )
                      : null,
                ),
                GestureDetector(
                  onTap: () {
                    if (isPlaying) {
                      context.read<PlayerBloc>().add(const PlayerPause());
                    } else {
                      context.read<PlayerBloc>().add(const PlayerPlay());
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.onSurface,
                    ),
                    child: Center(
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: theme.colorScheme.surface,
                              strokeWidth: 3,
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: theme.colorScheme.surface,
                              size: 48,
                            ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: isPremium
                        ? theme.colorScheme.onSurface
                        : Colors.grey.withOpacity(0.5),
                    size: 48,
                  ),
                  onPressed: isPremium
                      ? () => context.read<PlayerBloc>().add(
                          const PlayerSkipNext(),
                        )
                      : null,
                ),
                IconButton(
                  icon: Icon(
                    repeatMode == RepeatMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: repeatMode != RepeatMode.off
                        ? (isDark
                              ? AppTheme.darkPrimary
                              : AppTheme.lightPrimary)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () => context.read<PlayerBloc>().add(
                    const PlayerToggleRepeat(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bottom Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.playlist_add_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PlaylistSelectionSheet(song: song),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    Share.share(
                      'Check out ${song.title} by ${song.displayArtist} on FaithStream!',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPlaceholderArt(Size size) {
    return Container(
      width: size.width * 0.85,
      height: size.width * 0.85,
      color: Colors.white10,
      child: const Icon(
        Icons.music_note_rounded,
        size: 80,
        color: Colors.white24,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return "$minutes:${twoDigits(seconds)}";
  }
}

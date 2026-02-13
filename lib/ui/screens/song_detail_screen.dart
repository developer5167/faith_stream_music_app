import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../utils/constants.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../blocs/player/player_state.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../services/artist_service.dart';
import 'artist_profile_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Artist? _artist;
  bool _isLoadingArtist = false;

  @override
  void initState() {
    super.initState();
    _initArtist();
  }

  Future<void> _initArtist() async {
    // If artist is already attached to the song, just use it
    if (widget.song.artist != null) {
      _artist = widget.song.artist;
      return;
    }

    // If we don't have an artistUserId, we can't fetch artist details
    if (widget.song.artistUserId == null) return;

    setState(() {
      _isLoadingArtist = true;
    });

    try {
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final artistService = ArtistService(apiClient);

      final artist =
          await artistService.getArtistDetails(widget.song.artistUserId!);

      if (mounted && artist != null) {
        setState(() {
          _artist = artist;
          _isLoadingArtist = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingArtist = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingArtist = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with image background
          SliverAppBar(
            expandedHeight: size.height * 0.5,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Album/Song cover image
                  if (widget.song.coverImageUrl != null)
                    Image.network(
                      widget.song.coverImageUrl!,
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
                  else
                    Container(
                      color: AppColors.primaryBrown.withOpacity(0.2),
                      child: const Icon(
                        Icons.music_note,
                        size: 100,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Song details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artist name (tap to open artist details)
                  Builder(
                    builder: (context) {
                      final Artist? artist = _artist ?? widget.song.artist;

                      void _openArtistProfile() {
                        if (artist == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) =>
                                ArtistProfileScreen(artist: artist),
                          ),
                        );
                      }

                      return InkWell(
                        onTap: artist != null ? _openArtistProfile : null,
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          children: [
                            // Artist profile image
                            if (artist?.profilePicUrl != null)
                              CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    NetworkImage(artist!.profilePicUrl!),
                                onBackgroundImageError: (_, __) {},
                              )
                            else if (_isLoadingArtist)
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryGold,
                                  ),
                                ),
                              )
                            else
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primaryGold,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                            const SizedBox(width: AppSizes.paddingSm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Artist',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                                Text(
                                  artist?.name ?? widget.song.displayArtist,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingLg),

                  // Play button (integrated with global player state)
                  Center(
                    child: BlocBuilder<PlayerBloc, PlayerState>(
                      builder: (context, playerState) {
                        final isCurrentPlayingSong =
                            (playerState is PlayerPlaying &&
                                playerState.song.id == widget.song.id);
                        final isCurrentPausedSong =
                            (playerState is PlayerPaused &&
                                playerState.song.id == widget.song.id);

                        final bool isCurrentSong =
                            isCurrentPlayingSong || isCurrentPausedSong;

                        final bool isPlaying = isCurrentPlayingSong;

                        final icon =
                            isPlaying ? Icons.pause : Icons.play_arrow;
                        final label = isCurrentSong
                            ? (isPlaying ? 'Pause' : 'Resume')
                            : 'Play Now';

                        return ElevatedButton.icon(
                          onPressed: () {
                            // If this song is already the current one, just play/pause
                            if (isCurrentSong) {
                              if (isPlaying) {
                                context
                                    .read<PlayerBloc>()
                                    .add(const PlayerPause());
                              } else {
                                context
                                    .read<PlayerBloc>()
                                    .add(const PlayerPlay());
                              }
                              return;
                            }

                            // Ensure we pass a song that includes artist details
                            final artistForSong =
                                _artist ?? widget.song.artist;
                            final songToPlay = artistForSong != null
                                ? widget.song.copyWith(artist: artistForSong)
                                : widget.song;

                            context
                                .read<PlayerBloc>()
                                .add(PlayerPlaySong(songToPlay));
                          },
                          icon: Icon(icon, size: 32),
                          label: Text(
                            label,
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMd),

                  // Action buttons
                  BlocBuilder<LibraryBloc, LibraryState>(
                    builder: (context, libraryState) {
                      final isFavorite =
                          libraryState is LibraryLoaded &&
                          libraryState.isFavorite(widget.song.id);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            context,
                            icon: isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: isFavorite ? 'Liked' : 'Like',
                            color: isFavorite ? Colors.red : null,
                            onTap: () {
                              context.read<LibraryBloc>().add(
                                LibraryToggleFavorite(widget.song),
                              );
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.playlist_add,
                            label: 'Add to Playlist',
                            onTap: () {
                              _showAddToPlaylistDialog(context);
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.share,
                            label: 'Share',
                            onTap: () {
                              // TODO: Share song
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingLg),

                  const Divider(),
                  const SizedBox(height: AppSizes.paddingMd),

                  // Song information
                  _buildInfoRow(
                    context,
                    'Album',
                    widget.song.albumTitle ?? 'Single',
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _buildInfoRow(
                    context,
                    'Genre',
                    widget.song.genre ?? 'Unknown',
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _buildInfoRow(
                    context,
                    'Language',
                    widget.song.language ?? 'Unknown',
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _buildInfoRow(
                    context,
                    'Streams',
                    '${widget.song.streamCount}',
                  ),

                  if (widget.song.description != null &&
                      widget.song.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.paddingLg),
                    const Divider(),
                    const SizedBox(height: AppSizes.paddingMd),
                    Text(
                      'About',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Text(
                      widget.song.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSizes.paddingXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingSm),
        child: Column(
          children: [
            Icon(icon, color: color ?? AppColors.primaryBrown, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state is! LibraryLoaded) {
            return AlertDialog(
              title: const Text('Add to Playlist'),
              content: const Text('Loading playlists...'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text('Add to Playlist'),
            content: state.playlists.isEmpty
                ? const Text('No playlists available. Create one first!')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: state.playlists.map((playlist) {
                        return ListTile(
                          leading: const Icon(Icons.playlist_play),
                          title: Text(playlist.name),
                          subtitle: Text(playlist.displaySongCount),
                          onTap: () {
                            context.read<LibraryBloc>().add(
                              LibraryAddSongToPlaylist(
                                playlistId: playlist.id,
                                songId: widget.song.id,
                              ),
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to ${playlist.name}'),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

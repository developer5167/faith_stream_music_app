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
import '../widgets/gradient_background.dart';

import '../../services/sharing_service.dart';
import '../../services/song_service.dart';

class SongDetailScreen extends StatefulWidget {
  final Song? song;
  final String? songId;

  const SongDetailScreen({super.key, this.song, this.songId});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Song? _song;
  Artist? _artist;
  bool _isLoadingSong = false;
  bool _isLoadingArtist = false;

  @override
  void initState() {
    super.initState();
    _song = widget.song;
    _initData();
  }

  Future<void> _initData() async {
    if (_song == null && widget.songId != null) {
      await _loadSong(widget.songId!);
    }
    _initArtist();
  }

  Future<void> _loadSong(String id) async {
    setState(() => _isLoadingSong = true);
    try {
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final songService = SongService(apiClient);

      final songData = await songService.getSong(id);
      if (mounted && songData != null) {
        setState(() {
          _song = Song.fromJson(songData);
          _isLoadingSong = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSong = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading song: $e')));
      }
    }
  }

  Future<void> _initArtist() async {
    final song = _song;
    if (song == null) return;

    // If artist is already attached to the song, just use it
    if (song.artist != null) {
      _artist = song.artist;
      return;
    }

    // If we don't have an artistUserId, we can't fetch artist details
    if (song.artistUserId == null) return;

    setState(() {
      _isLoadingArtist = true;
    });

    try {
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final artistService = ArtistService(apiClient);

      final artist = await artistService.getArtistDetails(song.artistUserId!);

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

    if (_isLoadingSong) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_song == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: Text('Song not found')),
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // App Bar with immersive image background
            SliverAppBar(
              expandedHeight: size.height * 0.45,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _song!.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Album/Song cover image
                    if (_song!.coverImageUrl != null)
                      Image.network(
                        _song!.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.05,
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: 100,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.1,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: theme.colorScheme.onSurface.withOpacity(0.05),
                        child: Icon(
                          Icons.music_note,
                          size: 100,
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                    // Immersive gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                            theme.scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Song content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Artist Section
                    _buildArtistSection(theme),
                    const SizedBox(height: 32),

                    // Play button (Premium Pill Design)
                    _buildPlayButton(theme),
                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActionButtons(theme),
                    const SizedBox(height: 32),

                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Metadata Section
                    _buildMetadataSection(theme),

                    // About Section
                    if (_song!.description != null &&
                        _song!.description!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      Text(
                        'About',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _song!.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 100), // Space for mini player
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistSection(ThemeData theme) {
    final Artist? artist = _artist ?? _song!.artist;

    void _openArtistProfile() {
      if (artist == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ArtistProfileScreen(artist: artist),
        ),
      );
    }

    return InkWell(
      onTap: artist != null ? _openArtistProfile : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Artist profile image
            if (artist?.profilePicUrl != null)
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(artist!.profilePicUrl!),
                onBackgroundImageError: (_, __) {},
              )
            else if (_isLoadingArtist)
              const SizedBox(
                width: 44,
                height: 44,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.person, color: theme.colorScheme.primary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artist',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    artist?.name ?? _song!.displayArtist,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(ThemeData theme) {
    return Center(
      child: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, playerState) {
          final isCurrentPlayingSong =
              (playerState is PlayerPlaying &&
              playerState.song.id == _song!.id);
          final isCurrentPausedSong =
              (playerState is PlayerPaused && playerState.song.id == _song!.id);

          final bool isCurrentSong =
              isCurrentPlayingSong || isCurrentPausedSong;
          final bool isPlaying = isCurrentPlayingSong;

          final icon = isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded;
          final label = isCurrentSong
              ? (isPlaying ? 'Pause' : 'Resume')
              : 'Play Now';

          return Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                if (isCurrentSong) {
                  context.read<PlayerBloc>().add(
                    isPlaying ? const PlayerPause() : const PlayerPlay(),
                  );
                  return;
                }

                final artistForSong = _artist ?? _song!.artist;
                final songToPlay = artistForSong != null
                    ? _song!.copyWith(artist: artistForSong)
                    : _song!;

                context.read<PlayerBloc>().add(PlayerPlaySong(songToPlay));
              },
              icon: Icon(icon, size: 32),
              label: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, libraryState) {
        final isFavorite =
            libraryState is LibraryLoaded && libraryState.isFavorite(_song!.id);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionIcon(
              theme,
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              isFavorite ? 'Liked' : 'Like',
              color: isFavorite ? Colors.red : null,
              onTap: () {
                context.read<LibraryBloc>().add(LibraryToggleFavorite(_song!));
              },
            ),
            _buildActionIcon(
              theme,
              Icons.playlist_add_rounded,
              'Add to Playlist',
              onTap: () => _showAddToPlaylistDialog(context),
            ),
            _buildActionIcon(
              theme,
              Icons.ios_share_rounded,
              'Share',
              onTap: () {
                SharingService().shareSong(
                  id: _song!.id,
                  title: _song!.title,
                  artist: _song!.displayArtist,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionIcon(
    ThemeData theme,
    IconData icon,
    String label, {
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: color ?? theme.colorScheme.onSurface.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(theme, 'Album', _song!.albumTitle ?? 'Single'),
          const Divider(height: 24),
          _buildInfoRow(theme, 'Genre', _song!.genre ?? 'Christian'),
          const Divider(height: 24),
          _buildInfoRow(theme, 'Language', _song!.language ?? 'English'),
          const Divider(height: 24),
          _buildInfoRow(theme, 'Streams', '${_song!.streamCount} plays'),
        ],
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
                                songId: _song!.id,
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

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

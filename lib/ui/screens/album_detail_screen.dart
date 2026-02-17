import 'package:faith_stream_music_app/blocs/player/player_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../utils/constants.dart';
import '../../services/album_service.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_state.dart';
import '../../config/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import '../screens/now_playing_screen.dart';
import '../../services/artist_service.dart';
import 'artist_profile_screen.dart';
import '../widgets/gradient_background.dart';
import '../widgets/song_card.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Song> _tracks = [];
  bool _isLoadingTracks = true;
  Artist? _albumArtist;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchTracks();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final albumService = AlbumService(apiClient);

      final isFav = await albumService.checkIsFavorite(
        widget.album.id.toString(),
      );
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final albumService = AlbumService(apiClient);

      if (_isFavorite) {
        await albumService.removeFromFavorites(widget.album.id.toString());
      } else {
        await albumService.addToFavorites(widget.album.id.toString());
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  Future<void> _fetchTracks() async {
    try {
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final albumService = AlbumService(apiClient);
      final artistService = ArtistService(apiClient);

      final tracksData = await albumService.getAlbumTracks(
        widget.album.id.toString(),
      );

      final List<Song> fetchedSongs = [];
      Artist? firstTrackArtist;

      for (var json in tracksData) {
        Song song = Song.fromJson(json).copyWith(
          coverImageUrl: json['cover_image_url'] ?? widget.album.coverImageUrl,
        );

        if (song.artistUserId != null && song.artist == null) {
          final artist = await artistService.getArtistDetails(
            song.artistUserId!,
          );
          if (artist != null) {
            song = song.copyWith(artist: artist);
            if (firstTrackArtist == null) {
              firstTrackArtist = artist;
            }
          }
        } else if (song.artist != null && firstTrackArtist == null) {
          firstTrackArtist = song.artist;
        }

        fetchedSongs.add(song);
      }

      if (mounted) {
        setState(() {
          _tracks = fetchedSongs;
          _albumArtist = firstTrackArtist;
          _isLoadingTracks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTracks = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load tracks: $e')));
      }
    }
  }

  void _playAlbum() {
    if (_tracks.isEmpty) return;

    context.read<PlayerBloc>().add(
      PlayerPlaySong(_tracks.first, queue: _tracks),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing album ${widget.album.title}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const MiniPlayerBar(),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: size.height * 0.45,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.album.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 10),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.album.coverImageUrl != null)
                      Image.network(
                        widget.album.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.05,
                            ),
                            child: Icon(
                              Icons.album,
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
                          Icons.album,
                          size: 100,
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
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

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Artist info
                    InkWell(
                      onTap: () {
                        if (_albumArtist != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ArtistProfileScreen(artist: _albumArtist!),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.darkPrimary,
                            backgroundImage: _albumArtist?.profilePicUrl != null
                                ? NetworkImage(_albumArtist!.profilePicUrl!)
                                : null,
                            child: _albumArtist?.profilePicUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _albumArtist?.name ??
                                      widget.album.displayArtist,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'Album • ${widget.album.releaseType?.toUpperCase() ?? 'ALBUM'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? AppTheme.darkPrimary
                                  : Colors.white54,
                            ),
                            onPressed: _toggleFavorite,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Play and actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _tracks.isNotEmpty ? _playAlbum : null,
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 28,
                            ),
                            label: const Text('Play All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildSmallActionButton(
                          context,
                          Icons.share_outlined,
                          () {},
                        ),
                        const SizedBox(width: 8),
                        _buildSmallActionButton(
                          context,
                          Icons.download_outlined,
                          () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Tracks',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingTracks)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_tracks.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'No tracks found',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.54,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      BlocBuilder<PlayerBloc, PlayerState>(
                        builder: (context, state) {
                          String? currentSongId;
                          if (state is PlayerPlaying)
                            currentSongId = state.song.id;
                          if (state is PlayerPaused)
                            currentSongId = state.song.id;
                          if (state is PlayerLoading)
                            currentSongId = state.song?.id;

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tracks.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final track = _tracks[index];
                              final isCurrent = currentSongId == track.id;

                              return SongCard(
                                song: track,
                                isFavorite:
                                    false, // We'll handle this if library state is provided
                                onTap: () {
                                  if (isCurrent) {
                                    showModalBottomSheet(
                                      context: context,
                                      useSafeArea: true,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          const FractionallySizedBox(
                                            heightFactor: 1.0,
                                            child: NowPlayingScreen(),
                                          ),
                                    );
                                  } else {
                                    final trackWithArtist = track.artist != null
                                        ? track
                                        : track.copyWith(artist: _albumArtist);
                                    context.read<PlayerBloc>().add(
                                      PlayerPlaySong(
                                        trackWithArtist,
                                        queue: _tracks,
                                      ),
                                    );
                                  }
                                },
                                onPlayTap: () {
                                  final trackWithArtist = track.artist != null
                                      ? track
                                      : track.copyWith(artist: _albumArtist);
                                  context.read<PlayerBloc>().add(
                                    PlayerPlaySong(
                                      trackWithArtist,
                                      queue: _tracks,
                                    ),
                                  );
                                },
                                // Colors will be handled by SongCard's internal state if we passed isCurrent
                              );
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                    Divider(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                    const SizedBox(height: 16),

                    if (widget.album.description != null &&
                        widget.album.description!.isNotEmpty) ...[
                      Text(
                        'About',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.album.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    _buildInfoRow(
                      context,
                      'Released',
                      widget.album.createdAt != null
                          ? _formatDate(widget.album.createdAt!)
                          : 'Unknown',
                    ),
                    _buildInfoRow(
                      context,
                      'Language',
                      widget.album.language ?? 'Unknown',
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.38),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

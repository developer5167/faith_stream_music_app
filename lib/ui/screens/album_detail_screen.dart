import 'package:faith_stream_music_app/blocs/player/player_event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../models/artist.dart'; // Import Artist model
import '../../utils/constants.dart';
import '../../services/album_service.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_state.dart';
import '../widgets/mini_player_bar.dart';
import '../screens/now_playing_screen.dart';
import 'package:lottie/lottie.dart';
import '../../services/artist_service.dart'; // Import ArtistService

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

  @override
  void initState() {
    super.initState();
    _fetchTracks();
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

        // Fetch artist details if artistUserId is present and artist object is null
        if (song.artistUserId != null && song.artist == null) {
          final artist = await artistService.getArtistDetails(
            song.artistUserId!,
          );
          if (artist != null) {
            song = song.copyWith(artist: artist);
            // Store the first track's artist as the album artist
            if (firstTrackArtist == null) {
              firstTrackArtist = artist;
            }
          }
        } else if (song.artist != null && firstTrackArtist == null) {
          // If artist is already in the song object, use it
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

    // The _tracks list is already enriched with artist details during _fetchTracks
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

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar with album cover
              SliverAppBar(
                expandedHeight: size.height * 0.45,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.album.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Album cover image
                      if (widget.album.coverImageUrl != null)
                        Image.network(
                          widget.album.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.primaryBrown.withOpacity(0.2),
                              child: const Icon(
                                Icons.album,
                                size: 120,
                                color: AppColors.primaryBrown,
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          color: AppColors.primaryBrown.withOpacity(0.2),
                          child: const Icon(
                            Icons.album,
                            size: 120,
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

              // Album details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artist info
                      Row(
                        children: [
                          if (_albumArtist?.profilePicUrl != null)
                            ClipOval(
                              child: Image.network(
                                _albumArtist!.profilePicUrl!,
                                fit: BoxFit.cover,
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBrown.withOpacity(
                                        0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 24,
                                      color: AppColors.primaryBrown,
                                    ),
                                  );
                                },
                              ),
                            )
                          else if (_isLoadingTracks)
                            const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBrown.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 24,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                          const SizedBox(width: AppSizes.paddingSm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Album by',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              Text(
                                _albumArtist?.name ??
                                    widget.album.displayArtist,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingLg),

                      // Play all button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _tracks.isNotEmpty ? _playAlbum : null,
                          icon: const Icon(Icons.play_arrow, size: 32),
                          label: const Text(
                            'Play Album',
                            style: TextStyle(fontSize: 18),
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
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            context,
                            icon: Icons.favorite_border,
                            label: 'Like',
                            onTap: () {},
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.playlist_add,
                            label: 'Add to Library',
                            onTap: () {},
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.share,
                            label: 'Share',
                            onTap: () {},
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.download,
                            label: 'Download',
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingLg),

                      const Divider(),
                      const SizedBox(height: AppSizes.paddingMd),

                      // Album information
                      _buildInfoRow(
                        context,
                        'Release Type',
                        widget.album.releaseType?.toUpperCase() ?? 'ALBUM',
                      ),
                      const SizedBox(height: AppSizes.paddingSm),
                      _buildInfoRow(
                        context,
                        'Language',
                        widget.album.language ?? 'Unknown',
                      ),
                      if (widget.album.createdAt != null) ...[
                        const SizedBox(height: AppSizes.paddingSm),
                        _buildInfoRow(
                          context,
                          'Released',
                          _formatDate(widget.album.createdAt!),
                        ),
                      ],

                      if (widget.album.description != null &&
                          widget.album.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.paddingLg),
                        const Divider(),
                        const SizedBox(height: AppSizes.paddingMd),
                        Text(
                          'About this album',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        Text(
                          widget.album.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSizes.paddingLg),
                      const Divider(),
                      const SizedBox(height: AppSizes.paddingMd),

                      // Songs in album section
                      Text(
                        'Songs in this album',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSm),

                      if (_isLoadingTracks)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSizes.paddingLg),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_tracks.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.paddingLg),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.music_note,
                                    size: 48,
                                    color: AppColors.primaryBrown,
                                  ),
                                  const SizedBox(height: AppSizes.paddingSm),
                                  Text(
                                    'No songs found in this album.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        BlocBuilder<PlayerBloc, PlayerState>(
                          buildWhen: (previous, current) {
                            // Rebuild when state changes to/from loading, playing, or paused
                            return true;
                          },
                          builder: (context, state) {
                            String? currentSongId;
                            bool isPlaying = false;
                            bool isLoadingSong = false;

                            if (state is PlayerPlaying) {
                              currentSongId = state.song.id;
                              isPlaying = true;
                            } else if (state is PlayerPaused) {
                              currentSongId = state.song.id;
                              isPlaying = false;
                            } else if (state is PlayerLoading &&
                                state.song != null) {
                              currentSongId = state.song!.id;
                              isLoadingSong = true;
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tracks.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1, indent: 72),
                              itemBuilder: (context, index) {
                                final track = _tracks[index];
                                final isCurrentTrack =
                                    currentSongId == track.id;

                                return ListTile(
                                  leading: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          track.coverImageUrl ??
                                              widget.album.coverImageUrl ??
                                              '',
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    color: Colors.grey[200],
                                                    width: 48,
                                                    height: 48,
                                                    child: const Icon(
                                                      Icons.music_note,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      if (isCurrentTrack &&
                                          (isPlaying || isLoadingSong))
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: isLoadingSong
                                              ? const Center(
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  ),
                                                )
                                              : Lottie.asset(
                                                  'assets/lottie/playing.json',
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  frameRate: FrameRate(120),
                                                ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isCurrentTrack
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrentTrack
                                          ? AppColors.primaryBrown
                                          : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    track.displayArtist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: isCurrentTrack && !isLoadingSong
                                      ? IconButton(
                                          icon: Icon(
                                            isPlaying
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_fill,
                                            color: AppColors.primaryBrown,
                                            size: 32,
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
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.more_vert),
                                          onPressed: () {},
                                        ),
                                  onTap: () {
                                    if (isCurrentTrack) {
                                      // If it's the current track (playing, paused, or loading), open the full screen player
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
                                      // If it's a different song, play it
                                      // Ensure the track has artist details before playing
                                      final trackToPlay = track.artist != null
                                          ? track
                                          : track.copyWith(
                                              artist: _albumArtist,
                                            );
                                      context.read<PlayerBloc>().add(
                                        PlayerPlaySong(
                                          trackToPlay,
                                          queue: _tracks,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 100), // Space for mini player
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Positioned MiniPlayerBar
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayerBar(),
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
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingSm),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBrown, size: 28),
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

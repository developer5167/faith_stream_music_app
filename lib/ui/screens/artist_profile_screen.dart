import 'package:faith_stream_music_app/blocs/player/player_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../utils/constants.dart';
import '../../services/artist_service.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../blocs/player/player_bloc.dart';
import '../widgets/mini_player_bar.dart';
import 'album_detail_screen.dart';

class ArtistProfileScreen extends StatefulWidget {
  final Artist artist;

  const ArtistProfileScreen({super.key, required this.artist});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  bool _isFavorite = false;
  List<Song> _popularSongs = [];
  List<dynamic> _albums = [];
  bool _isLoadingSongs = true;
  bool _isLoadingAlbums = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storageService = context.read<StorageService>();
    final apiClient = ApiClient(storageService);
    final artistService = ArtistService(apiClient);

    setState(() {
      _isLoadingSongs = true;
      _isLoadingAlbums = true;
    });

    // Check favorite status
    _checkFavoriteStatus(artistService);

    // Fetch songs
    _fetchSongs(artistService);

    // Fetch albums
    _fetchAlbums(artistService);

    // Refresh artist details to get latest counts if possible
    // Note: The artist object passed in might be stale.
    // We should ideally fetch the artist details again, but existing `getArtistDetails` returns `Artist?`.
    // Let's try to update the artist object if we can.
    try {
      final updatedArtist = await artistService.getArtistDetails(
        widget.artist.id,
      );
      if (updatedArtist != null && mounted) {
        setState(() {
          // We can't update widget.artist, but we can use local state variables for counts
          // or just rely on the fact that we are displaying fetched content lists.
          // For now, let's update the counts based on the fetched lists + updated artist data.
          // Actually, `_fetchSongs` and `_fetchAlbums` populate lists.
          // We can use `_popularSongs.length` and `_albums.length` for the counts if the API returns *all* of them.
          // But pagination exists.
          // Best to use the updated artist object's counts if available.
        });
      }
    } catch (e) {
      debugPrint('Error updating artist details: $e');
    }
  }

  Future<void> _checkFavoriteStatus(ArtistService artistService) async {
    try {
      final isFav = await artistService.checkIsFavorite(widget.artist.id);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    } catch (e) {
      debugPrint('Error checking artist favorite: $e');
    }
  }

  Future<void> _fetchSongs(ArtistService artistService) async {
    try {
      final songsData = await artistService.getArtistSongs(widget.artist.id);
      final List<Song> songs = [];
      for (var json in songsData) {
        songs.add(Song.fromJson(json));
      }
      if (mounted) {
        setState(() {
          _popularSongs = songs;
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching artist songs: $e');
      if (mounted) setState(() => _isLoadingSongs = false);
    }
  }

  Future<void> _fetchAlbums(ArtistService artistService) async {
    try {
      final albumsData = await artistService.getArtistAlbums(widget.artist.id);
      if (mounted) {
        setState(() {
          _albums = albumsData;
          _isLoadingAlbums = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching artist albums: $e');
      if (mounted) setState(() => _isLoadingAlbums = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final storageService = context.read<StorageService>();
      final apiClient = ApiClient(storageService);
      final artistService = ArtistService(apiClient);

      if (_isFavorite) {
        await artistService.removeFromFavorites(widget.artist.id);
      } else {
        await artistService.addToFavorites(widget.artist.id);
      }

      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite
                  ? 'Added to favorite artists'
                  : 'Removed from favorite artists',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Use local lists length if available/loaded, otherwise fallback to widget.artist counts
    final songCount = _popularSongs.isNotEmpty
        ? _popularSongs.length
        : (widget.artist.totalSongs ?? 0);
    final albumCount = _albums.isNotEmpty
        ? _albums.length
        : (widget.artist.totalAlbums ?? 0);

    return Scaffold(
      bottomNavigationBar: const MiniPlayerBar(),
      body: CustomScrollView(
        slivers: [
          // App Bar with artist profile image
          SliverAppBar(
            expandedHeight: size.height * 0.4,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.artist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Artist profile/cover image
                  if (widget.artist.bannerImageUrl != null)
                    Image.network(
                      widget.artist.bannerImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primaryBrown.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
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
                        Icons.person,
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

          // Artist details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context,
                        icon: Icons.music_note,
                        label: 'Songs',
                        value: '$songCount',
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.album,
                        label: 'Albums',
                        value: '$albumCount',
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.people, // Changed icon
                        label: 'Followers',
                        value: '${widget.artist.totalFollowers ?? 0}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLg),

                  // Action buttons (Only Favorite now)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          label: Text(
                            _isFavorite ? 'Favorited' : 'Add to Favorites',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      // Removed "Follow" and "More" button rows from previous implementation logic
                      // To be safe, I'm replacing the entire section including "More actions"
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingSm),

                  // Share button only (removed More)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIconButton(
                        context,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {
                          // TODO: Share artist profile
                        },
                      ),
                    ],
                  ),

                  if (widget.artist.bio != null &&
                      widget.artist.bio!.isNotEmpty) ...[
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
                      widget.artist.bio!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSizes.paddingLg),
                  const Divider(),
                  const SizedBox(height: AppSizes.paddingMd),

                  // Popular songs section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Songs',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all songs
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingSm),

                  if (_isLoadingSongs)
                    const Center(child: CircularProgressIndicator())
                  else if (_popularSongs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingLg),
                        child: Center(
                          child: Text(
                            'No songs found',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _popularSongs.length > 5
                          ? 5
                          : _popularSongs.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final song = _popularSongs[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              song.coverImageUrl ??
                                  widget.artist.profilePicUrl ??
                                  '',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey[200],
                                    width: 48,
                                    height: 48,
                                    child: const Icon(Icons.music_note),
                                  ),
                            ),
                          ),
                          title: Text(song.title),
                          subtitle: Text(song.albumTitle ?? 'Single'),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_circle_fill),
                            color: AppColors.primaryBrown,
                            onPressed: () {
                              context.read<PlayerBloc>().add(
                                PlayerPlaySong(song, queue: _popularSongs),
                              );
                            },
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: AppSizes.paddingMd),

                  // Albums section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Albums',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all albums
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingSm),

                  if (_isLoadingAlbums)
                    const Center(child: CircularProgressIndicator())
                  else if (_albums.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingLg),
                        child: Center(
                          child: Text(
                            'No albums found',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _albums.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final albumData = _albums[index];
                          final album = Album.fromJson(albumData);
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AlbumDetailScreen(album: album),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      album.coverImageUrl ?? '',
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 140,
                                              height: 140,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.album,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    album.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    album.displayDate,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: AppSizes.paddingXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingSm,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBrown, size: 32),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBrown,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
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
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

import 'package:faith_stream_music_app/blocs/auth/auth_bloc.dart';
import 'package:faith_stream_music_app/blocs/auth/auth_state.dart';
import 'package:faith_stream_music_app/blocs/player/player_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../utils/constants.dart';
import '../../services/artist_service.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_state.dart';
import '../../config/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/gradient_background.dart';
import '../widgets/song_card.dart';
import '../widgets/premium_card.dart';
import 'album_detail_screen.dart';

import '../../services/sharing_service.dart';

class ArtistProfileScreen extends StatefulWidget {
  final Artist? artist;
  final String? artistId;

  const ArtistProfileScreen({super.key, this.artist, this.artistId});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  Artist? _artist;
  bool _isFavorite = false;
  List<Song> _popularSongs = [];
  List<dynamic> _albums = [];
  bool _isLoadingSongs = true;
  bool _isLoadingAlbums = true;
  bool _isLoadingArtist = false;

  @override
  void initState() {
    super.initState();
    _artist = widget.artist;
    _loadData();
  }

  Future<void> _loadData() async {
    final storageService = context.read<StorageService>();
    final apiClient = ApiClient(storageService);
    final artistService = ArtistService(apiClient);

    if (_artist == null && widget.artistId != null) {
      await _loadArtist(widget.artistId!, artistService);
    }

    if (_artist != null) {
      setState(() {
        _isLoadingSongs = true;
        _isLoadingAlbums = true;
      });

      _checkFavoriteStatus(artistService);
      _fetchSongs(artistService);
      _fetchAlbums(artistService);
    }
  }

  Future<void> _loadArtist(String id, ArtistService artistService) async {
    setState(() => _isLoadingArtist = true);
    try {
      final artist = await artistService.getArtistDetails(id);
      if (mounted && artist != null) {
        setState(() {
          _artist = artist;
          _isLoadingArtist = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingArtist = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading artist: $e')));
      }
    }
  }

  Future<void> _checkFavoriteStatus(ArtistService artistService) async {
    try {
      final isFollowing = await artistService.checkFollowing(_artist!.id);
      if (mounted) {
        setState(() => _isFavorite = isFollowing);
      }
    } catch (e) {
      debugPrint('Error checking artist follow status: $e');
    }
  }

  Future<void> _fetchSongs(ArtistService artistService) async {
    try {
      final songsData = await artistService.getArtistSongs(_artist!.id);
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
      final albumsData = await artistService.getArtistAlbums(_artist!.id);
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
        await artistService.unfollowArtist(_artist!.id);
      } else {
        await artistService.followArtist(_artist!.id);
      }

      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Artist followed' : 'Artist unfollowed',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update follow status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;
    final isOwnProfile = currentUserId == _artist!.id;

    if (_isLoadingArtist) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_artist == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: Text('Artist not found')),
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const MiniPlayerBar(),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: size.height * 0.4,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _artist!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_artist!.bannerImageUrl != null)
                      Image.network(
                        _artist!.bannerImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white24,
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.white10,
                        child: const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white24,
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
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
                    // Stats section
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatBadge(
                            context,
                            Icons.music_note_rounded,
                            '${_artist!.totalSongs ?? 0} Songs',
                          ),
                          const SizedBox(width: 8),
                          _buildStatBadge(
                            context,
                            Icons.album_rounded,
                            '${_artist!.totalAlbums ?? 0} Albums',
                          ),
                          const SizedBox(width: 8),
                          _buildStatBadge(
                            context,
                            Icons.people_rounded,
                            '${_artist!.totalFollowers ?? 0} Followers',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        if (!isOwnProfile) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _toggleFavorite,
                              icon: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                              ),
                              label: Text(
                                _isFavorite ? 'Following' : 'Follow Artist',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFavorite
                                    ? theme.colorScheme.onSurface.withOpacity(
                                        0.1,
                                      )
                                    : theme.colorScheme.primary,
                                foregroundColor: _isFavorite
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.share_outlined,
                              color: theme.colorScheme.onSurface,
                              size: 20,
                            ),
                            onPressed: () {
                              SharingService().shareArtist(
                                id: _artist!.id,
                                name: _artist!.name,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_artist!.bio != null && _artist!.bio!.isNotEmpty) ...[
                      Text(
                        'About',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _artist!.bio!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Popular Songs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Popular Songs',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'See All',
                            style: TextStyle(color: AppTheme.darkPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingSongs)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_popularSongs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No songs found',
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
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _popularSongs.length > 5
                                ? 5
                                : _popularSongs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final song = _popularSongs[index];
                              return SongCard(
                                song: song,
                                isFavorite: false,
                                onTap: () {
                                  context.read<PlayerBloc>().add(
                                    PlayerPlaySong(song, queue: _popularSongs),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 32),

                    // Albums
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Albums',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'See All',
                            style: TextStyle(color: AppTheme.darkPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingAlbums)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_albums.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No albums found',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.54,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _albums.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final album = Album.fromJson(_albums[index]);
                            return PremiumCard(
                              title: album.title,
                              subtitle: album.displayDate,
                              imageUrl: album.coverImageUrl,
                              width: 150,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AlbumDetailScreen(album: album),
                                  ),
                                );
                              },
                            );
                          },
                        ),
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

  Widget _buildStatBadge(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../utils/constants.dart';
import '../widgets/song_card.dart';
import '../widgets/album_card.dart';
import '../widgets/artist_card.dart';
import 'song_detail_screen.dart';
import 'album_detail_screen.dart';
import 'artist_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Song> _filteredSongs = [];
  List<Album> _filteredAlbums = [];
  List<Artist> _filteredArtists = [];

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      if (_isSearching) {
        _performSearch(_searchController.text);
      } else {
        _clearSearch();
      }
    });
  }

  void _performSearch(String query) {
    final homeState = context.read<HomeBloc>().state;
    if (homeState is HomeLoaded) {
      final feed = homeState.feed;
      final lowerQuery = query.toLowerCase();

      // Filter songs
      _filteredSongs = feed.songs.where((song) {
        return song.title.toLowerCase().contains(lowerQuery) ||
            song.displayArtist.toLowerCase().contains(lowerQuery) ||
            (song.genre?.toLowerCase().contains(lowerQuery) ?? false) ||
            (song.albumTitle?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();

      // Filter albums
      _filteredAlbums = feed.albums.where((album) {
        return album.title.toLowerCase().contains(lowerQuery) ||
            album.displayArtist.toLowerCase().contains(lowerQuery);
      }).toList();

      // Filter artists
      _filteredArtists = feed.artists.where((artist) {
        return artist.name.toLowerCase().contains(lowerQuery) ||
            (artist.name.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
  }

  void _clearSearch() {
    _filteredSongs = [];
    _filteredAlbums = [];
    _filteredArtists = [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search songs, albums, artists...',
            border: InputBorder.none,
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _isSearching
          ? Column(
              children: [
                // Tab bar
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryBrown,
                  indicatorColor: AppColors.primaryBrown,
                  tabs: [
                    Tab(text: 'Songs (${_filteredSongs.length})'),
                    Tab(text: 'Albums (${_filteredAlbums.length})'),
                    Tab(text: 'Artists (${_filteredArtists.length})'),
                  ],
                ),
                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSongsList(),
                      _buildAlbumsList(),
                      _buildArtistsList(),
                    ],
                  ),
                ),
              ],
            )
          : _buildInitialState(),
    );
  }

  Widget _buildInitialState() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 Trending Searches',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTrendingChip('Gospel'),
              _buildTrendingChip('Worship'),
              _buildTrendingChip('Praise'),
              _buildTrendingChip('Christian'),
              _buildTrendingChip('Contemporary'),
            ],
          ),
          const SizedBox(height: AppSizes.paddingLg),
          Text(
            '💡 Search Tips',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          _buildSearchTip('Search by song title, artist name, or genre'),
          _buildSearchTip('Use the tabs to filter results'),
          _buildSearchTip('Tap on any result to view details'),
        ],
      ),
    );
  }

  Widget _buildTrendingChip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.primaryBrown.withOpacity(0.1),
      labelStyle: const TextStyle(
        color: AppColors.primaryBrown,
        fontWeight: FontWeight.w500,
      ),
      onPressed: () {
        _searchController.text = label;
      },
    );
  }

  Widget _buildSearchTip(String tip) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.primaryGold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_filteredSongs.isEmpty) {
      return _buildEmptyState('No songs found');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      itemCount: _filteredSongs.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.paddingSm),
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        return BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, libraryState) {
            final isFavorite =
                libraryState is LibraryLoaded &&
                libraryState.isFavorite(song.id);

            return SongCard(
              song: song,
              showFavoriteButton: true,
              isFavorite: isFavorite,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SongDetailScreen(song: song),
                  ),
                );
              },
              onPlayTap: () {
                context.read<PlayerBloc>().add(
                  PlayerPlaySong(song, queue: _filteredSongs),
                );
              },
              onFavoriteTap: () {
                context.read<LibraryBloc>().add(LibraryToggleFavorite(song));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumsList() {
    if (_filteredAlbums.isEmpty) {
      return _buildEmptyState('No albums found');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSizes.paddingSm,
        mainAxisSpacing: AppSizes.paddingSm,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredAlbums.length,
      itemBuilder: (context, index) {
        final album = _filteredAlbums[index];
        return AlbumCard(
          album: album,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumDetailScreen(album: album),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArtistsList() {
    if (_filteredArtists.isEmpty) {
      return _buildEmptyState('No artists found');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      itemCount: _filteredArtists.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.paddingSm),
      itemBuilder: (context, index) {
        final artist = _filteredArtists[index];
        return ArtistCard(
          artist: artist,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArtistProfileScreen(artist: artist),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_state.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../blocs/search/search_bloc.dart';
import '../../blocs/search/search_event.dart';
import '../../blocs/search/search_state.dart';
import '../../utils/constants.dart';
import '../../config/app_theme.dart';
import '../widgets/song_card.dart';
import '../widgets/album_card.dart';
import '../widgets/artist_card.dart';
import 'album_detail_screen.dart';
import 'artist_profile_screen.dart';
import '../widgets/gradient_background.dart';

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
        context.read<SearchBloc>().add(
          SearchQueryChanged(_searchController.text),
        );
      } else {
        context.read<SearchBloc>().add(SearchClear());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 80,
          title: Container(
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
              ),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search songs, albums, artists...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.38),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        body: _isSearching
            ? BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SearchError) {
                    return _buildEmptyState(context, 'Error performing search');
                  }

                  if (state is SearchLoaded) {
                    _filteredSongs = state.songs;
                    _filteredAlbums = state.albums;
                    _filteredArtists = state.artists;

                    return Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: isDark
                              ? AppTheme.darkPrimary
                              : AppTheme.lightPrimary,
                          unselectedLabelColor: theme.colorScheme.onSurface
                              .withOpacity(0.38),
                          indicatorColor: isDark
                              ? AppTheme.darkPrimary
                              : AppTheme.lightPrimary,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          tabs: [
                            Tab(text: 'Songs (${_filteredSongs.length})'),
                            Tab(text: 'Albums (${_filteredAlbums.length})'),
                            Tab(text: 'Artists (${_filteredArtists.length})'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildSongsList(context),
                              _buildAlbumsList(context),
                              _buildArtistsList(context),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Initial or empty
                  return _buildEmptyState(context, 'Start typing to search');
                },
              )
            : _buildInitialState(),
      ),
    );
  }

  Widget _buildInitialState() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Categories',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _buildCategoryCard(
                'Gospel',
                Colors.indigo,
                Icons.church,
                context,
              ),
              _buildCategoryCard(
                'Contemporary Christian',
                Colors.blue,
                Icons.speaker,
                context,
              ),
              _buildCategoryCard(
                'Worship',
                Colors.purple,
                Icons.volunteer_activism,
                context,
              ),
              _buildCategoryCard(
                'Praise',
                Colors.orange,
                Icons.auto_awesome,
                context,
              ),
              _buildCategoryCard(
                'Hymns',
                Colors.green,
                Icons.menu_book,
                context,
              ),
              _buildCategoryCard(
                'Christian Rock',
                Colors.red,
                Icons.electric_bolt,
                context,
              ),
              _buildCategoryCard(
                'Christian Pop',
                Colors.pink,
                Icons.music_note,
                context,
              ),
              _buildCategoryCard(
                'Christian Hip Hop',
                Colors.deepOrange,
                Icons.mic,
                context,
              ),
              _buildCategoryCard(
                'Southern Gospel',
                Colors.brown,
                Icons.home,
                context,
              ),
              _buildCategoryCard(
                'Traditional',
                Colors.teal,
                Icons.account_balance,
                context,
              ),
              _buildCategoryCard(
                'Instrumental',
                Colors.blueGrey,
                Icons.piano,
                context,
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'Trending Searches',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTrendingChip(context, 'Gospel'),
              _buildTrendingChip(context, 'Hymns'),
              _buildTrendingChip(context, 'Choir'),
              _buildTrendingChip(context, 'Morning Worship'),
              _buildTrendingChip(context, 'Inspiration'),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildCategoryCard(
    String label,
    Color color,
    IconData icon,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(icon, size: 80, color: Colors.white12),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.05),
      side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        fontSize: 13,
      ),
      onPressed: () {
        _searchController.text = label;
      },
    );
  }

  Widget _buildSongsList(BuildContext context) {
    if (_filteredSongs.isEmpty) {
      return _buildEmptyState(context, 'No songs found');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      itemCount: _filteredSongs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        return BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, libraryState) {
            final isFavorite =
                libraryState is LibraryLoaded &&
                libraryState.isFavorite(song.id);

            return SongCard(
              song: song,
              isFavorite: isFavorite,
              onTap: () {
                context.read<PlayerBloc>().add(
                  PlayerPlaySong(song, queue: _filteredSongs),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumsList(BuildContext context) {
    if (_filteredAlbums.isEmpty) {
      return _buildEmptyState(context, 'No albums found');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
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

  Widget _buildArtistsList(BuildContext context) {
    if (_filteredArtists.isEmpty) {
      return _buildEmptyState(context, 'No artists found');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      itemCount: _filteredArtists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
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

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.38),
            ),
          ),
        ],
      ),
    );
  }
}

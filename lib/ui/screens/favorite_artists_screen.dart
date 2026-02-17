import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_state.dart';
import '../../blocs/library/library_event.dart';
import '../../utils/constants.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/artist_card.dart';
import 'artist_profile_screen.dart';

class FavoriteArtistsScreen extends StatelessWidget {
  const FavoriteArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Fav Artists')),
      bottomNavigationBar: const MiniPlayerBar(),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state is LibraryArtistsLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is LibraryLoaded) {
            final artists = state.favoriteArtists;

            if (artists.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<LibraryBloc>().add(LibraryLoadFavoriteArtists());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: Column(
                children: [
                  // Header with Play All
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    child: Row(
                      children: [
                        Text(
                          '${artists.length} Artists',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Artists grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: AppSizes.paddingMd,
                            mainAxisSpacing: AppSizes.paddingMd,
                          ),
                      itemCount: artists.length,
                      itemBuilder: (context, index) {
                        final artist = artists[index];
                        return ArtistCard(
                          artist: artist,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ArtistProfileScreen(artist: artist),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 100,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          const Text(
            'No Favorite Artists',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          Text(
            'Artists you favorite will appear here.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

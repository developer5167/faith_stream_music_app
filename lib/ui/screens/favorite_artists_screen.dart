import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_state.dart';
import '../../blocs/library/library_event.dart';
import '../../utils/constants.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/gradient_background.dart';
import '../widgets/premium_card.dart';
import 'artist_profile_screen.dart';

class FavoriteArtistsScreen extends StatelessWidget {
  const FavoriteArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Favorite Artists',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
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
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        child: Text(
                          '${artists.length} artists you follow',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMd,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final artist = artists[index];
                          return PremiumCard(
                            title: artist.name,
                            subtitle: 'Artist',
                            imageUrl:
                                artist.profilePicUrl ?? artist.bannerImageUrl,
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
                        }, childCount: artists.length),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
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
            Icons.person_outline_rounded,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
          ),
          const SizedBox(height: 24),
          Text(
            'No favorite artists yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow your favorite artists to see them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.38),
            ),
          ),
        ],
      ),
    );
  }
}

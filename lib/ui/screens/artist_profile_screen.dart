import 'package:flutter/material.dart';
import '../../models/artist.dart';
import '../../utils/constants.dart';

class ArtistProfileScreen extends StatelessWidget {
  final Artist artist;

  const ArtistProfileScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with artist profile image
          SliverAppBar(
            expandedHeight: size.height * 0.4,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Artist profile/cover image
                  if (artist.bannerImageUrl != null)
                    Image.network(
                      artist.bannerImageUrl!,
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
                        value: '${artist.totalSongs}',
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.album,
                        label: 'Albums',
                        value: '${artist.totalAlbums}',
                      ),
                      _buildStatCard(
                        context,
                        icon: Icons.favorite,
                        label: 'Followers',
                        value: 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLg),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Play artist's top songs
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Playing ${artist.name}\'s songs...',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
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
                      const SizedBox(width: AppSizes.paddingSm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Follow artist
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Follow feature coming soon!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Follow'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBrown,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(
                              color: AppColors.primaryBrown,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingSm),

                  // More actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIconButton(
                        context,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {
                          // TODO: Share artist profile
                        },
                      ),
                      _buildIconButton(
                        context,
                        icon: Icons.more_horiz,
                        label: 'More',
                        onTap: () {
                          // TODO: Show more options
                        },
                      ),
                    ],
                  ),

                  if (artist.bio != null && artist.bio!.isNotEmpty) ...[
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
                      artist.bio!,
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

                  // TODO: Fetch and display artist's songs
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
                              'Songs list coming soon...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

                  // TODO: Fetch and display artist's albums
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLg),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.album,
                              size: 48,
                              color: AppColors.primaryBrown,
                            ),
                            const SizedBox(height: AppSizes.paddingSm),
                            Text(
                              'Albums list coming soon...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../utils/constants.dart';
import 'create_album_screen.dart';
import 'upload_song_screen.dart';
import 'manage_songs_screen.dart';

class ArtistDashboardScreen extends StatelessWidget {
  const ArtistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded || state is ProfileOperationSuccess) {
          final profileState = state is ProfileOperationSuccess
              ? state.previousState
              : state as ProfileLoaded;

          return _buildDashboard(context, profileState);
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildDashboard(BuildContext context, ProfileLoaded state) {
    final theme = Theme.of(context);
    final artistStatus = state.artistStatus;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Artist Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.mic,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.music_note,
                        title: 'Total Songs',
                        value: artistStatus?['total_songs']?.toString() ?? '0',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMd),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.play_circle,
                        title: 'Total Streams',
                        value:
                            artistStatus?['total_streams']?.toString() ?? '0',
                        color: Colors
                            .green, // Keep green for success/streams but maybe use theme.colorScheme.secondary
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMd),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.album,
                        title: 'Albums',
                        value: artistStatus?['total_albums']?.toString() ?? '0',
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMd),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.currency_rupee,
                        title: 'Earnings',
                        value:
                            '₹${artistStatus?['total_earnings']?.toString() ?? '0'}',
                        color: Colors
                            .purple, // Keep purple as a distinct stat color
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingXl),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),

                _buildActionTile(
                  context,
                  icon: Icons.upload_file,
                  title: 'Upload New Song',
                  subtitle: 'Share your latest music',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UploadSongScreen(),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.library_music,
                  title: 'Manage Songs',
                  subtitle: 'View and edit your uploaded songs',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ManageSongsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.album,
                  title: 'Create Album',
                  subtitle: 'Organize your songs into albums',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateAlbumScreen(),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  context,
                  icon: Icons.analytics,
                  title: 'View Analytics',
                  subtitle: 'Track your performance and earnings',
                  color: Colors.green,
                  onTap: () {
                    // TODO: Navigate to analytics
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Analytics feature coming soon!'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSizes.paddingXl),

                // Recent Activity Section
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLg),
                    child: Column(
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 60,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: AppSizes.paddingMd),
                        Text(
                          'No Recent Activity',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        Text(
                          'Upload your first song to see activity here',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

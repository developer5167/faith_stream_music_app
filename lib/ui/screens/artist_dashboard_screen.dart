import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../utils/constants.dart';
import 'create_album_screen.dart';
import 'upload_song_screen.dart';
import 'manage_songs_screen.dart';
import 'earnings_screen.dart';

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

    // ── Stat formatting helpers ───────────────────────────────────────────
    String fmtCount(String key) {
      final val = int.tryParse(artistStatus?[key]?.toString() ?? '0') ?? 0;
      if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
      if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
      return val.toString();
    }

    String fmtEarnings() {
      final val =
          double.tryParse(artistStatus?['total_earnings']?.toString() ?? '0') ??
          0.0;
      if (val >= 100000) return '₹${(val / 100000).toStringAsFixed(1)}L';
      if (val >= 1000) return '₹${(val / 1000).toStringAsFixed(1)}K';
      return '₹${val.toStringAsFixed(0)}';
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              'Artist Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                        value: fmtCount('total_songs'),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMd),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.play_circle,
                        title: 'Total Streams',
                        value: fmtCount('total_streams'),
                        color: Colors.green,
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
                        value: fmtCount('total_albums'),
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMd),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.people,
                        title: 'Followers',
                        value: fmtCount('follower_count'),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMd),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EarningsScreen(),
                          ),
                        ),
                        child: _buildStatCard(
                          context,
                          icon: Icons.currency_rupee,
                          title: 'Earnings',
                          value: fmtEarnings(),
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMd),
                _buildStrikesCard(context, state.user.copyrightStrikes),
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
                  title: 'Earnings & Payouts',
                  subtitle: 'View earnings, request payout',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EarningsScreen()),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrikesCard(BuildContext context, int strikes) {
    Color cardColor;
    IconData iconData;
    String title = 'Copyright Strikes: $strikes/3';
    String message;

    if (strikes == 0) {
      cardColor = Colors.green.shade700;
      iconData = Icons.check_circle;
      message =
          'Great job adhering to our platform guidelines! You have 0 copyright strikes. Keep up the good work.';
    } else if (strikes == 1) {
      cardColor = Colors.yellow.shade800;
      iconData = Icons.warning_amber_rounded;
      message =
          'You have received 1 copyright strike. Please ensure you own the rights to the music you upload to avoid further action.';
    } else if (strikes == 2) {
      cardColor = Colors.orange.shade800;
      iconData = Icons.error_outline;
      message =
          'Warning: You have 2 copyright strikes. If you reach 3 strikes, your artist account and all uploaded content will be permanently deleted and you will lose access forever.';
    } else {
      cardColor = Colors.red.shade800;
      iconData = Icons.block;
      message =
          'CRITICAL: You have reached 3 copyright strikes. Your account is flagged for deletion and you will no longer have access to upload or manage music.';
    }

    return Card(
      elevation: 2,
      color: cardColor.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: cardColor, size: 32),
            const SizedBox(width: AppSizes.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

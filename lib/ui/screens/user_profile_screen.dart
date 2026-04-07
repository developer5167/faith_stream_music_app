import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../utils/constants.dart';
import '../../repositories/user_repository.dart';
import '../widgets/gradient_background.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProfileBloc>().add(ProfileLoad());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProfileLoaded || state is ProfileOperationSuccess) {
          final profileState = state is ProfileOperationSuccess
              ? state.previousState
              : state as ProfileLoaded;

          return _buildProfileContent(context, profileState);
        }

        return const Scaffold(body: Center(child: Text('Loading profile...')));
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, ProfileLoaded state) {
    final theme = Theme.of(context);
    final user = state.user;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<ProfileBloc>().add(ProfileLoad());
            // Wait a bit for the bloc to emit new state
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user.name),
                      if (state.subscription?.isActive ?? false) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.workspace_premium,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          backgroundImage: user.profilePicUrl != null
                              ? NetworkImage(user.profilePicUrl!)
                              : null,
                          child: user.profilePicUrl == null
                              ? Text(
                                  user.name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.push('/edit-profile', extra: user);
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info
                      _buildInfoCard(
                        context,
                        icon: Icons.email,
                        title: 'Email',
                        value: user.email,
                      ),
                      if (user.phone != null)
                        _buildInfoCard(
                          context,
                          icon: Icons.phone,
                          title: 'Phone',
                          value: user.phone!,
                        ),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        _buildInfoCard(
                          context,
                          icon: Icons.info_outline,
                          title: 'Bio',
                          value: user.bio!,
                        ),


                      // Subscription status section
                      _buildSubscriptionCard(context, state.subscription),

                      const SizedBox(height: AppSizes.paddingLg),

                      // Artist status section
                      _buildArtistSection(context, user),

                      const SizedBox(height: AppSizes.paddingLg),

                      // Navigation Actions
                      _buildActionCard(
                        context,
                        icon: Icons.notifications,
                        title: 'Notifications',
                        onTap: () {
                          context.push('/notifications');
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () async {
                          final url = Uri.parse(
                            'https://faithstream.sotersystems.in/legal/privacy-policy.html',
                          );
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not launch Privacy Policy',
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () => context.push('/support'),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.gavel_outlined,
                        title: 'Report Copyright Infringement',
                        onTap: () async {
                          final url = Uri.parse(
                            'https://faithstream.sotersystems.in/legal/copyright.html',
                          );
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          } catch (_) {}
                        },
                      ),

                      const SizedBox(height: AppSizes.paddingLg),

                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showLogoutConfirmation(context);
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingLg),

                      // Danger Zone — Account Deletion (App Store required)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Danger Zone',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  if (user.isArtist) {
                                    _showArtistDeleteAccountConfirmation(context);
                                  } else {
                                    _showDeleteAccountConfirmation(context);
                                  }
                                },
                                icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                                label: const Text('Delete My Account'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Permanently removes your account and all personal data. This cannot be undone.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingLg),

                      // App Version
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Center(
                              child: Text(
                                'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),

                      const SizedBox(height: AppSizes.paddingXl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      color: Colors.white.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: AppSizes.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, dynamic subscription) {
    final theme = Theme.of(context);
    final isActive = subscription?.isActive ?? false;
    final planName = subscription?.planName ?? 'Free';

    int daysLeft = 0;
    if (isActive && subscription?.endDate != null) {
      daysLeft = subscription.endDate.difference(DateTime.now()).inDays;
    }

    return Card(
      margin: EdgeInsets.zero,
      color: isActive
          ? const Color(0xFF6A0DAD).withOpacity(0.1)
          : Colors.white.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.amber.withOpacity(0.5) : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/premium');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.workspace_premium : Icons.stars,
                color: isActive ? Colors.amber : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isActive ? 'Premium Member' : 'Free Plan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.amber : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? '$planName • $daysLeft days remaining'
                          : 'Upgrade for ad-free listening',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      color: Colors.white.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : theme.colorScheme.onSurface,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildArtistSection(BuildContext context, user) {
    final theme = Theme.of(context);
    if (user.isArtist) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            context.push('/artist-dashboard');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white, size: 32),
                const SizedBox(width: AppSizes.paddingMd),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Artist Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your songs, albums and more',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white),
              ],
            ),
          ),
        ),
      );
    } else if (user.isArtistPending) {
      return Card(
        color: theme.colorScheme.errorContainer.withOpacity(0.2),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Row(
            children: [
              Icon(Icons.pending, color: theme.colorScheme.error, size: 32),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artist Request Pending',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your artist request is under review',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        color: theme.colorScheme.primary.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            context.push('/artist-registration');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Row(
              children: [
                Icon(Icons.star, color: theme.colorScheme.secondary, size: 32),
                const SizedBox(width: AppSizes.paddingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Become an Artist',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share your music with the world',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete your account and anonymize all your personal data. Your uploaded songs and artist content will remain on the platform.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Type DELETE to confirm:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              style: const TextStyle(color: Colors.white, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim() != 'DELETE') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type DELETE to confirm.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              final repo = context.read<UserRepository>();
              final result = await repo.deleteAccount();
              if (context.mounted) {
                if (result.success) {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: ${result.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showArtistDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Artist Formal Deletion', style: TextStyle(color: Colors.orange, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'As an Approved Artist, your account contains intellectual property (songs/albums) and generates royalties. Therefore, your account deletion must be processed manually by our Support Team.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Important Financial Notice:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              '• Please withdraw any available funds via the dashboard prior to deletion.\n'
              '• Any funds remaining below the payout threshold will be forfeited.\n'
              '• If you delete your account but choose to leave your music on FaithStream, you explicitly waive your right to all future royalties, which will be retained by the platform.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'To proceed, please tap \"Contact Support\" and submit a formal catalog takedown & account closure request.',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              context.push('/support'); // Navigate to support screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

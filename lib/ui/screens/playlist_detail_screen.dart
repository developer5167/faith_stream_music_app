import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/playlist.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../utils/constants.dart';
import '../widgets/song_card.dart';
import '../widgets/mini_player_bar.dart';
import 'song_detail_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        // Find the updated playlist from the state
        Playlist currentPlaylist = playlist;
        if (state is LibraryLoaded) {
          final updatedPlaylist = state.playlists.firstWhere(
            (p) => p.id == playlist.id,
            orElse: () => playlist,
          );
          currentPlaylist = updatedPlaylist;
        }

        return _buildContent(context, currentPlaylist);
      },
    );
  }

  Widget _buildContent(BuildContext context, Playlist currentPlaylist) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      bottomNavigationBar: const MiniPlayerBar(),
      body: CustomScrollView(
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: size.height * 0.4,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                currentPlaylist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryBrown, AppColors.primaryGold],
                      ),
                    ),
                  ),
                  // Playlist icon
                  Center(
                    child: Icon(
                      Icons.queue_music,
                      size: 120,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  // Bottom gradient overlay
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
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditPlaylistDialog(context, currentPlaylist);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, currentPlaylist);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit Playlist'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Delete Playlist',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Playlist info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentPlaylist.description != null &&
                      currentPlaylist.description!.isNotEmpty) ...[
                    Text(
                      currentPlaylist.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentPlaylist.displaySongCount,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingSm),
                      if (currentPlaylist.isPublic) ...[
                        Icon(
                          Icons.public,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Public',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Private',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingMd),

                  // Play all button
                  if (currentPlaylist.songs.isNotEmpty)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<PlayerBloc>().add(
                            PlayerPlaySong(
                              currentPlaylist.songs.first,
                              queue: currentPlaylist.songs,
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text(
                          'Play All',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Songs list
          if (currentPlaylist.songs.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context))
          else
            SliverPadding(
              padding: const EdgeInsets.only(
                left: AppSizes.paddingMd,
                right: AppSizes.paddingMd,
                top: AppSizes.paddingMd,
                bottom: 100, // Space for mini player
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = currentPlaylist.songs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
                    child: SongCard(
                      song: song,
                      showRemoveButton: true,
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
                          PlayerPlaySong(song, queue: currentPlaylist.songs),
                        );
                      },
                      onRemoveTap: () {
                        _showRemoveSongConfirmation(
                          context,
                          currentPlaylist,
                          song,
                        );
                      },
                    ),
                  );
                }, childCount: currentPlaylist.songs.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              'No Songs Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              'Add songs to this playlist to start listening.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlaylistDialog(BuildContext context, Playlist currentPlaylist) {
    final nameController = TextEditingController(text: currentPlaylist.name);
    final descriptionController = TextEditingController(
      text: currentPlaylist.description ?? '',
    );
    bool isPublic = currentPlaylist.isPublic;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Playlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Playlist Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSm),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSizes.paddingSm),
                SwitchListTile(
                  title: const Text('Public Playlist'),
                  value: isPublic,
                  onChanged: (value) {
                    setState(() {
                      isPublic = value;
                    });
                  },
                  activeColor: AppColors.primaryBrown,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a playlist name'),
                    ),
                  );
                  return;
                }

                context.read<LibraryBloc>().add(
                  LibraryUpdatePlaylist(
                    playlistId: currentPlaylist.id,
                    name: name,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    isPublic: isPublic,
                  ),
                );

                Navigator.pop(context);
                Navigator.pop(context); // Return to playlists screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Playlist currentPlaylist) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text(
          'Are you sure you want to delete "${currentPlaylist.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LibraryBloc>().add(
                LibraryDeletePlaylist(currentPlaylist.id),
              );
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to playlists screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRemoveSongConfirmation(
    BuildContext context,
    Playlist currentPlaylist,
    dynamic song,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Song'),
        content: Text('Remove "${song.title}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LibraryBloc>().add(
                LibraryRemoveSongFromPlaylist(
                  playlistId: currentPlaylist.id,
                  songId: song.id,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

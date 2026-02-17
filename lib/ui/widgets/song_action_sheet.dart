import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/song.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../utils/constants.dart';
import 'playlist_selection_sheet.dart';

/// A bottom sheet that displays action options for a song
class SongActionSheet extends StatelessWidget {
  final Song song;

  const SongActionSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        bool isFavorite = false;
        if (state is LibraryLoaded) {
          isFavorite = state.isFavorite(song.id);
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Song info header
                Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMd),
                  child: Row(
                    children: [
                      // Song cover
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: song.coverImageUrl != null
                            ? Image.network(
                                song.coverImageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2),
                                    child: Icon(
                                      Icons.music_note,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                child: Icon(
                                  Icons.music_note,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSizes.paddingMd),

                      // Song details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.displayArtist,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Action options
                _buildActionTile(
                  context,
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  iconColor: isFavorite ? Colors.red : null,
                  title: isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                  onTap: () {
                    context.read<LibraryBloc>().add(
                      LibraryToggleFavorite(song),
                    );
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavorite
                              ? 'Removed from favorites'
                              : 'Added to favorites',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                _buildActionTile(
                  context,
                  icon: Icons.playlist_add,
                  title: 'Add to Playlist',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PlaylistSelectionSheet(song: song),
                    );
                  },
                ),

                _buildActionTile(
                  context,
                  icon: Icons.share,
                  title: 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    _shareSong(song);
                  },
                ),

                const SizedBox(height: AppSizes.paddingSm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _shareSong(Song song) {
    final String shareText =
        '🎵 ${song.title}\n'
        '🎤 ${song.displayArtist}\n'
        '\nListen on FaithStream!';

    Share.share(shareText, subject: song.title);
  }
}

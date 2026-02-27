import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../../utils/constants.dart';

/// A bottom sheet for selecting a playlist to add a song to
class PlaylistSelectionSheet extends StatefulWidget {
  final Song song;

  const PlaylistSelectionSheet({super.key, required this.song});

  @override
  State<PlaylistSelectionSheet> createState() => _PlaylistSelectionSheetState();
}

class _PlaylistSelectionSheetState extends State<PlaylistSelectionSheet> {
  final TextEditingController _playlistNameController = TextEditingController();
  bool _showCreatePlaylist = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false, // Sheet handle handles top
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
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

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd,
                  vertical: AppSizes.paddingSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add to Playlist',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Create new playlist button
              if (!_showCreatePlaylist)
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text('Create New Playlist'),
                  onTap: () {
                    setState(() {
                      _showCreatePlaylist = true;
                    });
                  },
                ),

              // Create playlist form
              if (_showCreatePlaylist)
                Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMd),
                  child: Column(
                    children: [
                      TextField(
                        controller: _playlistNameController,
                        decoration: const InputDecoration(
                          labelText: 'Playlist Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.playlist_play),
                        ),
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _createPlaylistAndAddSong(),
                      ),
                      const SizedBox(height: AppSizes.paddingSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showCreatePlaylist = false;
                                _playlistNameController.clear();
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: AppSizes.paddingSm),
                          ElevatedButton(
                            onPressed: _isCreating
                                ? null
                                : _createPlaylistAndAddSong,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                            ),
                            child: _isCreating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Create'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (!_showCreatePlaylist) const Divider(height: 1),

              // Playlist list
              if (!_showCreatePlaylist)
                BlocBuilder<LibraryBloc, LibraryState>(
                  builder: (context, state) {
                    if (state is LibraryLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSizes.paddingLg),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is LibraryLoaded) {
                      final playlists = state.playlists;

                      if (playlists.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingLg),
                          child: Column(
                            children: [
                              Icon(
                                Icons.playlist_play,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: AppSizes.paddingSm),
                              Text(
                                'No playlists yet',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                              const SizedBox(height: AppSizes.paddingSm),
                              Text(
                                'Create your first playlist above',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            return _buildPlaylistTile(context, playlist);
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),

              const SizedBox(height: AppSizes.paddingSm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(BuildContext context, Playlist playlist) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.playlist_play,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: playlist.description != null && playlist.description!.isNotEmpty
          ? Text(
              playlist.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () => _addSongToPlaylist(playlist),
    );
  }

  void _createPlaylistAndAddSong() async {
    final playlistName = _playlistNameController.text.trim();

    if (playlistName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a playlist name'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    // Create the playlist
    context.read<LibraryBloc>().add(LibraryCreatePlaylist(name: playlistName));

    // Wait a bit for the playlist to be created
    await Future.delayed(const Duration(milliseconds: 500));

    // Get the updated state to find the newly created playlist
    final state = context.read<LibraryBloc>().state;
    if (state is LibraryLoaded && state.playlists.isNotEmpty) {
      // Find the playlist by name (it should be the most recent one)
      final newPlaylist = state.playlists.firstWhere(
        (p) => p.name == playlistName,
        orElse: () => state.playlists.last,
      );

      // Add the song to the new playlist
      context.read<LibraryBloc>().add(
        LibraryAddSongToPlaylist(
          playlistId: newPlaylist.id,
          songId: widget.song.id,
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to "$playlistName"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _addSongToPlaylist(Playlist playlist) {
    context.read<LibraryBloc>().add(
      LibraryAddSongToPlaylist(playlistId: playlist.id, songId: widget.song.id),
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to "${playlist.name}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

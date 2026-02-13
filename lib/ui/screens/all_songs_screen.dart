import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/song.dart';
import '../../utils/constants.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../blocs/library/library_bloc.dart';
import '../../blocs/library/library_event.dart';
import '../../blocs/library/library_state.dart';
import '../widgets/song_card.dart';
import 'song_detail_screen.dart';

class AllSongsScreen extends StatelessWidget {
  final String title;
  final List<Song> songs;

  const AllSongsScreen({super.key, required this.title, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: songs.isEmpty
          ? const Center(child: Text('No songs available'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              itemCount: songs.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSizes.paddingSm),
              itemBuilder: (context, index) {
                final song = songs[index];
                return BlocBuilder<LibraryBloc, LibraryState>(
                  builder: (context, libraryState) {
                    final isFavorite =
                        libraryState is LibraryLoaded &&
                        libraryState.isFavorite(song.id);

                    return SongCard(
                      song: song,
                      showFavoriteButton: true,
                      isFavorite: isFavorite,
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
                          PlayerPlaySong(song, queue: songs),
                        );
                      },
                      onFavoriteTap: () {
                        context.read<LibraryBloc>().add(
                          LibraryToggleFavorite(song),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

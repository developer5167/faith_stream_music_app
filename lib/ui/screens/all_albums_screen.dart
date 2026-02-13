import 'package:flutter/material.dart';
import '../../models/album.dart';
import '../../utils/constants.dart';
import '../widgets/album_card.dart';
import 'album_detail_screen.dart';

class AllAlbumsScreen extends StatelessWidget {
  final String title;
  final List<Album> albums;

  const AllAlbumsScreen({super.key, required this.title, required this.albums});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: albums.isEmpty
          ? const Center(child: Text('No albums available'))
          : GridView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.paddingSm,
                mainAxisSpacing: AppSizes.paddingSm,
                childAspectRatio: 0.7,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return AlbumCard(
                  album: album,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlbumDetailScreen(album: album),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

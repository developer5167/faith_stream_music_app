import 'package:flutter/material.dart';
import '../../models/artist.dart';
import '../../utils/constants.dart';
import '../widgets/artist_card.dart';
import 'artist_profile_screen.dart';

class AllArtistsScreen extends StatelessWidget {
  final String title;
  final List<Artist> artists;

  const AllArtistsScreen({
    super.key,
    required this.title,
    required this.artists,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: artists.isEmpty
          ? const Center(child: Text('No artists available'))
          : GridView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.paddingSm,
                mainAxisSpacing: AppSizes.paddingSm,
                childAspectRatio: 0.85,
              ),
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                return ArtistCard(
                  artist: artist,
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
              },
            ),
    );
  }
}

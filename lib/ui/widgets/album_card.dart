import 'package:flutter/material.dart';
import '../../models/album.dart';
import '../widgets/premium_card.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;

  const AlbumCard({super.key, required this.album, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      title: album.title,
      subtitle: album.displayArtist,
      imageUrl: album.coverImageUrl,
      onTap: onTap ?? () {},
    );
  }
}

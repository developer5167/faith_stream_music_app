import 'package:flutter/material.dart';
import '../../models/artist.dart';
import '../../utils/constants.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback? onTap;

  const ArtistCard({super.key, required this.artist, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Artist Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryBrown.withOpacity(0.1),
                backgroundImage: artist.bannerImageUrl != null
                    ? NetworkImage(artist.bannerImageUrl!)
                    : null,
                child: artist.bannerImageUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: AppSizes.paddingSm),

              // Artist Name
              Text(
                artist.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              // Song Count
              if ((int.tryParse(artist.totalSongs.toString()) ?? 0) > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${artist.totalSongs} songs',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

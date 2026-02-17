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
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: artist.profilePicUrl != null
                    ? NetworkImage(artist.profilePicUrl!)
                    : null,
                child: artist.profilePicUrl == null
                    ? Icon(
                        Icons.person,
                        size: 40,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      )
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

              // Counts
              if ((artist.totalSongs ?? 0) > 0 ||
                  (artist.totalAlbums ?? 0) > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${artist.totalSongs ?? 0} songs • ${artist.totalAlbums ?? 0} albums',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

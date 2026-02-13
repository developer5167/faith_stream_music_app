import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../utils/constants.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final bool showRemoveButton;
  final VoidCallback? onRemoveTap;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.onPlayTap,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.showRemoveButton = false,
    this.onRemoveTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingSm),
          child: Row(
            children: [
              // Album Art
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primaryBrown.withOpacity(0.1),
                ),
                child: song.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          song.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.music_note, size: 30),
                        ),
                      )
                    : const Icon(Icons.music_note, size: 30),
              ),
              const SizedBox(width: AppSizes.paddingMd),

              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.displayArtist,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (song.genre != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        song.genre!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              if (showFavoriteButton)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: onFavoriteTap,
                ),
              if (showRemoveButton)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: onRemoveTap,
                ),

              // Play Button
              IconButton(
                icon: Icon(
                  Icons.play_circle_filled,
                  color: AppColors.primaryBrown,
                  size: 36,
                ),
                onPressed: onPlayTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

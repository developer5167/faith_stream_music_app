import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../config/app_theme.dart';

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

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // Album Art
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white10,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      song.coverImageUrl != null &&
                          song.coverImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: song.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Icon(
                            Icons.music_note,
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.24,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.music_note,
                          color: theme.colorScheme.onSurface.withOpacity(0.24),
                        ),
                ),
                const SizedBox(width: 16),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.displayArtist,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.albumTitle != null &&
                          song.albumTitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Album: ${song.albumTitle}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${song.streamCount ?? "0"} plays',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Favorite Action
                if (showFavoriteButton)
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? (theme.brightness == Brightness.dark
                                ? AppTheme.darkPrimary
                                : AppTheme.lightPrimary)
                          : theme.colorScheme.onSurface.withOpacity(0.54),
                      size: 22,
                    ),
                    onPressed: onFavoriteTap,
                  ),

                // Play / Action Button
                if (onPlayTap != null)
                  IconButton(
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.onSurface,
                      size: 28,
                    ),
                    onPressed: onPlayTap,
                  ),

                if (showRemoveButton)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: onRemoveTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../config/app_theme.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;

  // Favourite
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  // Download (premium only)
  final bool showDownloadButton;
  final bool isDownloaded;
  final double? downloadProgress; // 0.0–1.0 while in progress, null = idle
  final VoidCallback? onDownloadTap;

  // Remove (used in downloads screen)
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
    this.showDownloadButton = false,
    this.isDownloaded = false,
    this.downloadProgress,
    this.onDownloadTap,
    this.showRemoveButton = false,
    this.onRemoveTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget coverWidget;
    if (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty) {
      if (song.coverImageUrl!.startsWith('file://')) {
        // Local file
        coverWidget = Image.file(
          File(Uri.parse(song.coverImageUrl!).toFilePath()),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.music_note,
            color: theme.colorScheme.onSurface.withOpacity(0.24),
          ),
        );
      } else {
        // Network image
        coverWidget = CachedNetworkImage(
          imageUrl: song.coverImageUrl!,
          fit: BoxFit.cover,
          memCacheWidth: 168,
          errorWidget: (_, __, ___) => Icon(
            Icons.music_note,
            color: theme.colorScheme.onSurface.withOpacity(0.24),
          ),
        );
      }
    } else {
      coverWidget = Icon(
        Icons.music_note,
        color: theme.colorScheme.onSurface.withOpacity(0.24),
      );
    }

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
                  child: coverWidget,
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

                // ── Favourite button ───────────────────────────────────
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

                // ── Download button (premium) ──────────────────────────
                if (showDownloadButton)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: downloadProgress != null
                        // Downloading — show circular progress
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              value: downloadProgress,
                              strokeWidth: 2.5,
                              color: AppTheme.darkPrimary,
                              backgroundColor: Colors.white12,
                            ),
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isDownloaded
                                  ? Icons.download_done_rounded
                                  : Icons.download_for_offline_outlined,
                              color: isDownloaded
                                  ? Colors.greenAccent
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.54,
                                    ),
                              size: 22,
                            ),
                            onPressed: isDownloaded ? null : onDownloadTap,
                          ),
                  ),

                // ── Play button ────────────────────────────────────────
                if (onPlayTap != null)
                  IconButton(
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.onSurface,
                      size: 28,
                    ),
                    onPressed: onPlayTap,
                  ),

                // ── Remove button (downloads screen) ──────────────────
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

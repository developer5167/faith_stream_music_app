import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a song cover image that works for both:
///  - Remote HTTP/HTTPS URLs (uses CachedNetworkImage)
///  - Local file:// paths (uses Image.file — for offline downloaded songs)
///
/// Falls back to a music_note icon placeholder if the URL is null or loading fails.
class CoverImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const CoverImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback =
        placeholder ??
        Container(
          width: width,
          height: height,
          color: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.music_note_rounded,
            color: theme.colorScheme.primary.withOpacity(0.5),
            size: (width ?? 48) * 0.5,
          ),
        );

    if (url == null || url!.isEmpty) return fallback;

    if (url!.startsWith('file://')) {
      final filePath = Uri.parse(url!).toFilePath();
      return Image.file(
        File(filePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../models/song.dart';
import '../../services/download_service.dart';

/// A self-contained widget that wraps song download logic.
/// Pass it a [song]; it handles premium check, progress state, and
/// the one-time "switching devices loses downloads" warning.
///
/// Usage — drop inside a SongCard's parent or pass props through:
///
/// ```dart
/// SongDownloadHandler(
///   song: song,
///   builder: (context, isDownloaded, progress, onTap) => SongCard(
///     song: song,
///     showDownloadButton: true,
///     isDownloaded: isDownloaded,
///     downloadProgress: progress,
///     onDownloadTap: onTap,
///   ),
/// )
/// ```
class SongDownloadHandler extends StatefulWidget {
  final Song song;
  final Widget Function(
    BuildContext context,
    bool isDownloaded,
    double? downloadProgress,
    VoidCallback? onDownloadTap,
  )
  builder;

  const SongDownloadHandler({
    super.key,
    required this.song,
    required this.builder,
  });

  @override
  State<SongDownloadHandler> createState() => _SongDownloadHandlerState();
}

class _SongDownloadHandlerState extends State<SongDownloadHandler> {
  double? _progress; // null = idle, 0.0-1.0 = downloading

  bool get _isDownloaded =>
      context.read<DownloadService>().isDownloaded(widget.song.id);

  bool get _isPremium {
    final state = context.read<ProfileBloc>().state;
    return state is ProfileLoaded &&
        state.subscription != null &&
        state.subscription!.isActive;
  }

  Future<void> _onDownloadTap() async {
    if (!_isPremium) return;
    if (_isDownloaded) return;

    // One-time device-switch warning
    final prefs = await SharedPreferences.getInstance();
    const warningKey = 'download_device_warning_shown';
    if (!prefs.containsKey(warningKey)) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.phone_android, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Device Downloads',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: const Text(
            'Downloads are saved on this device only. '
            'Switching to another device will not transfer your downloads.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Got It',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await prefs.setBool(warningKey, true);
    }

    // Start download
    if (!mounted) return;
    setState(() => _progress = 0.0);

    final ds = context.read<DownloadService>();
    final success = await ds.downloadSong(
      widget.song,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (mounted) {
      setState(() => _progress = null);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _isPremium;
    final isDownloaded = isPremium && _isDownloaded;
    final progress = isPremium ? _progress : null;
    final onTap = isPremium && !isDownloaded && _progress == null
        ? _onDownloadTap
        : null;

    return widget.builder(context, isDownloaded, progress, onTap);
  }
}

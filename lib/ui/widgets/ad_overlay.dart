import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ad_model.dart';
import '../../services/ads_service.dart';

class AdOverlay extends StatefulWidget {
  final String songId;
  final Widget child; // The original album art

  const AdOverlay({Key? key, required this.songId, required this.child})
    : super(key: key);

  @override
  State<AdOverlay> createState() => _AdOverlayState();
}

class _AdOverlayState extends State<AdOverlay> {
  AdModel? _ad;
  String? _lastFetchedSongId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAdIfNeeded();
    });
  }

  @override
  void didUpdateWidget(AdOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      _fetchAdIfNeeded();
    }
  }

  Future<void> _fetchAdIfNeeded() async {
    if (_lastFetchedSongId == widget.songId) return;

    _lastFetchedSongId = widget.songId;
    final adService = context.read<AdsService>();
    final ad = await adService.getNextAd('COVER_OVERLAY');

    if (ad != null && mounted) {
      setState(() {
        _ad = ad;
      });
      adService.trackAdEvent(ad.id, 'VIEW');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ad == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: GestureDetector(
            onTap: () async {
              context.read<AdsService>().trackAdEvent(_ad!.id, 'CLICK');
              final uri = Uri.parse(_ad!.landingUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Stack(
              children: [
                // Ad Image
                Image.network(
                  _ad!.mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Ad image load error: $error');
                    return Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white30,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
                // Ad Badge Indicator
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                    child: const Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                // Close Ad Button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _ad = null; // Dismiss ad
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

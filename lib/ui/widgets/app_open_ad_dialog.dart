import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ad_model.dart';
import '../../services/ads_service.dart';
import '../../config/app_theme.dart';

/// Shows a Spotify-style interstitial ad dialog.
/// Call [AppOpenAdDialog.showIfAvailable] once per session.
class AppOpenAdDialog {
  /// Session flag — ensures the ad shows at most once per app launch.
  static bool _shownThisSession = false;

  /// Call this after the home screen is fully rendered.
  /// Checks for an APP_OPEN ad and shows it if the user is free.
  static Future<void> showIfAvailable(BuildContext context) async {
    if (_shownThisSession) return;

    final adService = context.read<AdsService>();
    final ad = await adService.getNextAd('APP_OPEN');
    if (ad == null) return;
    if (!context.mounted) return;

    _shownThisSession = true;
    adService.trackAdEvent(ad.id, 'VIEW');

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => _AppOpenAdWidget(ad: ad, adService: adService),
    );
  }

  /// Reset for testing (optional — not needed in production).
  static void resetSession() => _shownThisSession = false;
}

class _AppOpenAdWidget extends StatelessWidget {
  final AdModel ad;
  final AdsService adService;

  const _AppOpenAdWidget({required this.ad, required this.adService});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Ad Card ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sponsored badge
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.darkPrimary.withOpacity(0.4),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'SPONSORED',
                          style: TextStyle(
                            color: AppTheme.darkPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        ad.title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Ad Image
                GestureDetector(
                  onTap: () async {
                    adService.trackAdEvent(ad.id, 'CLICK');
                    final uri = Uri.parse(ad.landingUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Image.network(
                          ad.mediaUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 280,
                              color: const Color(0xFF2A2A2A),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white30,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, _) => Container(
                            height: 280,
                            color: const Color(0xFF2A2A2A),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white24,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                        // "Tap to learn more" hint
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tap to learn more',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 10,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Dismiss Button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Got It',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // "Upgrade to remove ads" nudge
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Remove ads with Premium',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

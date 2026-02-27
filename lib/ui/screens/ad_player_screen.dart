import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/ad_model.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/player/player_event.dart';
import '../../services/ads_service.dart';
import '../../config/app_theme.dart';

class AdPlayerScreen extends StatefulWidget {
  final AdModel ad;

  const AdPlayerScreen({Key? key, required this.ad}) : super(key: key);

  @override
  State<AdPlayerScreen> createState() => _AdPlayerScreenState();
}

class _AdPlayerScreenState extends State<AdPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasTrackedView = false;
  bool _showControls = true;
  Timer? _hideTimer;

  // Timer for the 30s progress bar
  double _progress = 0.0;
  Timer? _progressTimer;
  static const int _adDurationSeconds = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.ad.mediaUrl))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
              _controller.play();
              _startAdTimers();

              if (!_hasTrackedView) {
                context.read<AdsService>().trackAdEvent(widget.ad.id, 'VIEW');
                _hasTrackedView = true;
              }
            }
          });

    // Safety pause to ensure global music is stopped
    context.read<PlayerBloc>().add(const PlayerPause());

    _startHideTimer();
  }

  void _startAdTimers() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _progress += 0.1 / _adDurationSeconds;
          if (_progress >= 1.0) {
            _progress = 1.0;
            _progressTimer?.cancel();
            _finishAd();
          }
        });
      }
    });
  }

  void _finishAd() {
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_isInitialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    context.read<AdsService>().trackAdEvent(widget.ad.id, 'CLICK');
    final uri = Uri.parse(widget.ad.landingUrl);
    if (await canLaunchUrl(uri)) {
      _controller.pause();
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        _controller.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A1A), Colors.black],
              ),
            ),
            child: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video content
                  Center(
                    child: _isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                  ),

                  // Shadow overlay when controls are visible
                  AnimatedOpacity(
                    opacity: _showControls ? 0.6 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(color: Colors.black),
                  ),

                  // Top: Ad Badge
                  Positioned(
                    top: 20,
                    left: 20,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          'SPONSORED VIDEO',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Middle: Dummy Controls
                  Center(
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 48,
                              color: Colors.white70,
                            ),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 32),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.pause_rounded,
                                size: 56,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              size: 48,
                              color: Colors.white70,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom: Progress and Learn More
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress Bar
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: SliderComponentShape.noThumb,
                            overlayShape: SliderComponentShape.noOverlay,
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                          ),
                          child: Slider(value: _progress, onChanged: (_) {}),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(
                                Duration(
                                  seconds: (_progress * _adDurationSeconds)
                                      .toInt(),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(
                                const Duration(seconds: _adDurationSeconds),
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Learn More Button
                        GestureDetector(
                          onTap: _launchUrl,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LEARN MORE',
                                  style: TextStyle(
                                    color: AppTheme.darkPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 18,
                                  color: AppTheme.darkPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

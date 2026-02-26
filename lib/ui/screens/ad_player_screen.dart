import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/ad_model.dart';
import '../../services/ads_service.dart';

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
  int _timeLeft = 0;

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
                _timeLeft = _controller.value.duration.inSeconds;
              });
              _controller.play();

              if (!_hasTrackedView) {
                context.read<AdsService>().trackAdEvent(widget.ad.id, 'VIEW');
                _hasTrackedView = true;
              }
            }
          });

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (_isInitialized) {
      final value = _controller.value;

      if (mounted) {
        setState(() {
          _timeLeft = (value.duration.inSeconds - value.position.inSeconds)
              .clamp(0, value.duration.inSeconds);
        });
      }

      if (value.isInitialized &&
          (value.duration == value.position ||
              value.position > value.duration)) {
        // Video finished
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
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
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    context.read<AdsService>().trackAdEvent(widget.ad.id, 'CLICK');
    final uri = Uri.parse(widget.ad.landingUrl);
    if (await canLaunchUrl(uri)) {
      _controller.pause(); // Pause video while viewing URL
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        _controller.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),

              // Tap overlay for landing URL
              Positioned.fill(
                child: GestureDetector(
                  onTap: _isInitialized ? _launchUrl : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Top row: Ad badge and countdown timer
              if (_isInitialized)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SPONSORED',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Text(
                          'Reward in $_timeLeft s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom: Learn More banner
              if (_isInitialized)
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _launchUrl,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Learn More',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

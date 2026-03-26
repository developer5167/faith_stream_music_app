import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../models/home_feed.dart';
import '../../services/storage_service.dart';
import '../../config/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _hasNavigated = false;
  DateTime? _splashStartTime;

  // Phase 1: FS fades + scales in (0–600ms)
  late AnimationController _introController;
  late Animation<double> _fsFadeAnim;
  late Animation<double> _fsScaleAnim;

  // Phase 2: F slides left, S slides right, aith/tream expand (600–1500ms)
  late AnimationController _expandController;
  late Animation<double> _expandAnim;
  late Animation<double> _slideAnim;

  // Phase 3: Shimmer sheen sweeps across (1500–2700ms)
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  // Phase 4: Fade out
  late AnimationController _fadeOutController;
  late Animation<double> _fadeOutAnim;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fsFadeAnim = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _fsScaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutQuart,
    );
    _slideAnim = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutQuart,
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _shimmerAnim = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeOutAnim = CurvedAnimation(
      parent: _fadeOutController,
      curve: Curves.easeIn,
    );

    _runSequence();

    try {
      context.read<AuthBloc>().add(const AuthCheckRequested());
    } catch (e) {
      _navigateToLogin();
    }

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_hasNavigated) _navigateToLogin();
    });
  }

  Future<void> _runSequence() async {
    if (!mounted) return;
    // Skip FS intro, start expansion immediately
    _introController.value = 1.0;
    await _expandController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _shimmerController.forward();
  }

  Future<void> _ensureMinimumSplashDuration() async {
    if (_splashStartTime != null) {
      final elapsed = DateTime.now().difference(_splashStartTime!);
      const minDuration = Duration(milliseconds: 3800);
      if (elapsed < minDuration) await Future.delayed(minDuration - elapsed);
    }
  }

  void _navigateToLogin() async {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      await _ensureMinimumSplashDuration();
      if (!mounted) return;
      await _fadeOutController.forward();
      if (!mounted) return;
      final storageService = context.read<StorageService>();
      if (storageService.isOnboardingCompleted()) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    }
  }

  void _navigateToHome() async {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      await _ensureMinimumSplashDuration();
      if (!mounted) return;
      await _fadeOutController.forward();
      if (mounted) context.go('/home');
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _expandController.dispose();
    _shimmerController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.bootstrapData != null) {
            final bootstrap = state.bootstrapData!;
            final homeFeed = HomeFeed(
              recentlyPlayed: bootstrap.recentlyPlayed,
              topPlayedSongs: bootstrap.topPlayed,
              trendingSongs: bootstrap.newReleases,
              albums: bootstrap.newAlbums,
              followedArtists: const [],
              topArtists: const [],
              topPlayedArtists: const [],
            );
            context.read<HomeBloc>().add(HomeBootstrapLoaded(homeFeed));
          }
          _navigateToHome();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          _navigateToLogin();
        }
      },
      child: AnimatedBuilder(
        animation: _fadeOutAnim,
        builder: (context, child) =>
            Opacity(opacity: 1.0 - _fadeOutAnim.value, child: child),
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.premiumDarkGradient,
            ),
            child: Stack(
              children: [
                // ── Logo ──────────────────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _introController,
                          _expandController,
                          _shimmerController,
                        ]),
                        builder: (context, _) => _FaithStreamLogo(
                          fsFade: _fsFadeAnim.value,
                          fsScale: _fsScaleAnim.value,
                          expand: _expandAnim.value,
                          slide: _slideAnim.value,
                          shimmer: _shimmerAnim.value,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _expandController,
                        builder: (context, _) => Opacity(
                          opacity: ((_expandAnim.value - 0.6) / 0.4).clamp(
                            0.0,
                            1.0,
                          ),
                          child: Text(
                            'by SOTER SYSTEMS',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 11,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w300,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tagline ────────────────────────────────────────────────
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, _) => Opacity(
                      opacity: _shimmerAnim.value * 0.6,
                      child: Text(
                        'Grace in Every Stream',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo widget — wraps the CustomPainter
// ─────────────────────────────────────────────────────────────────────────────
class _FaithStreamLogo extends StatelessWidget {
  const _FaithStreamLogo({
    required this.fsFade,
    required this.fsScale,
    required this.expand,
    required this.slide,
    required this.shimmer,
  });

  final double fsFade;
  final double fsScale;
  final double expand;
  final double slide;
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LogoPainter(
        fsFade: fsFade,
        fsScale: fsScale,
        expand: expand,
        slide: slide,
        shimmer: shimmer,
      ),
      size: const Size(320, 58),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painter — Netflix-style letter reveal
// ─────────────────────────────────────────────────────────────────────────────
class _LogoPainter extends CustomPainter {
  const _LogoPainter({
    required this.fsFade,
    required this.fsScale,
    required this.expand,
    required this.slide,
    required this.shimmer,
  });

  final double fsFade;
  final double fsScale;
  final double expand;
  final double slide;
  final double shimmer;

  static const double _fontSize = 42.0;

  ui.Paragraph _para(String text) {
    final b =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.left,
              fontSize: _fontSize,
              maxLines: 1,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: Colors.white,
              fontSize: _fontSize,
              fontWeight: ui.FontWeight.w900,
              letterSpacing: -2,
            ),
          )
          ..addText(text);
    final p = b.build();
    p.layout(const ui.ParagraphConstraints(width: 600));
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Measure each piece
    final pF = _para('F');
    final pAith = _para('aith');
    final pS = _para('S');
    final pTream = _para('tream');

    final wF = pF.longestLine;
    final wAith = pAith.longestLine;
    final wS = pS.longestLine;
    final wTream = pTream.longestLine;
    final h = pF.height;
    final yTop = cy - h / 2;

    // --- Positions ---
    // slide=0: "FS" centred, no gap → fX=cx-(wF+wS)/2, sX=fX+wF
    // slide=1: "FaithStream" centred, no gap → fX=cx-total/2, sX=fX+wF+wAith
    final fStart = cx - (wF + wS) / 2;
    final sStart = fStart + wF;
    final fEnd = cx - (wF + wAith + wS + wTream) / 2;
    final sEnd = fEnd + wF + wAith;

    final fX = ui.lerpDouble(fStart, fEnd, slide)!;
    final sX = ui.lerpDouble(sStart, sEnd, slide)!;

    // Scale from center during intro pop-in
    canvas.save();
    if (fsScale < 1.0) {
      canvas.translate(cx, cy);
      canvas.scale(fsScale);
      canvas.translate(-cx, -cy);
    }

    // Fade-in layer
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white.withValues(alpha: fsFade),
    );

    // --- Draw "Faith" (White) ---
    // 'F'
    canvas.drawParagraph(pF, Offset(fX, yTop));
    // 'aith'
    if (expand > 0) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(fX + wF, 0, fX + wF + wAith * expand, size.height),
      );
      canvas.drawParagraph(pAith, Offset(fX + wF, yTop));
      canvas.restore();
    }

    // --- Draw "Stream" (Gradient) ---
    final streamFullWidth = wS + wTream;
    final streamRect = Rect.fromLTWH(sX, yTop, streamFullWidth, h);
    final streamGradient = ui.Gradient.linear(
      Offset(sX, yTop),
      Offset(sX + streamFullWidth, yTop),
      [const Color(0xFF8B5CF6), const Color(0xFFD946EF)],
    );
    final streamPaint = Paint()..shader = streamGradient;

    // Use saveLayer to apply the gradient only to the text (srcIn)
    canvas.saveLayer(streamRect, Paint());
    // Draw 'S'
    canvas.drawParagraph(pS, Offset(sX, yTop));
    // Draw 'tream' (with clipping)
    if (expand > 0) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(
          sX + wS + wTream - wTream * expand,
          0,
          sX + wS + wTream + 2,
          size.height,
        ),
      );
      canvas.drawParagraph(pTream, Offset(sX + wS, yTop));
      canvas.restore();
    }
    // Apply the gradient as a mask
    canvas.drawRect(streamRect, streamPaint..blendMode = BlendMode.srcIn);
    canvas.restore();

    // Shimmer sheen sweeps L→R
    if (shimmer > 0 && shimmer < 1.0) {
      final wordStart = fEnd;
      final wordW = wF + wAith + wS + wTream;
      final sheenX = wordStart + wordW * shimmer * 1.3 - wordW * 0.1;
      final sheenRect = Rect.fromLTWH(sheenX - 28, 0, 56, size.height);

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(wordStart, 0, wordW + 2, size.height));
      canvas.drawRect(
        sheenRect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.6),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(sheenRect)
          ..blendMode = BlendMode.srcATop,
      );
      canvas.restore();
    }

    canvas.restore(); // fade layer
    canvas.restore(); // scale
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.fsFade != fsFade ||
      old.fsScale != fsScale ||
      old.expand != expand ||
      old.slide != slide ||
      old.shimmer != shimmer;
}

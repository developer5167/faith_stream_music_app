import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/storage_service.dart';
import '../../config/app_theme.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  final StorageService storageService;

  const OnboardingScreen({super.key, required this.storageService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      icon: Icons.music_note_rounded,
      title: 'Discover Gospel Music',
      description:
          'Explore thousands of uplifting gospel songs and albums from talented Christian artists around the world.',
      color: AppTheme.brandMagenta,
    ),
    OnboardingPage(
      icon: Icons.headphones_rounded,
      title: 'Stream Unlimited Songs',
      description:
          'Enjoy unlimited streaming of your favorite worship music anytime, anywhere. Download for offline listening.',
      color: AppTheme.brandPurple,
    ),
    OnboardingPage(
      icon: Icons.favorite_rounded,
      title: 'Support Christian Artists',
      description:
          'Your subscription directly supports gospel artists. Help them continue creating inspiring music.',
      color: AppTheme.brandMagenta,
    ),
    OnboardingPage(
      icon: Icons.mic_rounded,
      title: 'Create & Share Your Music',
      description:
          'Are you an artist? Join our platform to upload your songs, reach millions, and earn from your music.',
      color: AppTheme.brandPurple,
    ),
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    await widget.storageService.setOnboardingCompleted();
    if (mounted) {
      context.go('/login');
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.premiumDarkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], index);
                  },
                ),
              ),

              // Dots & Button Section
              Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.brandIndigo.withOpacity(0.5),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildIndicator(index == _currentPage),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Next/Get Started button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: _nextPage,
                        text: _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ).animate().shimmer(
                        delay: 2000.ms,
                        duration: 1500.ms,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with Bloom Effect
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      page.color.withOpacity(0.35),
                      page.color.withOpacity(0.0),
                    ],
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(duration: 2.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
              
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: page.color.withOpacity(0.2), width: 1),
                ),
                child: Icon(page.icon, size: 48, color: page.color),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.5, 0.5)),

          const SizedBox(height: 60),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: Colors.white.withOpacity(0.6),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 32 : 6,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.brandMagenta : Colors.white24,
        borderRadius: BorderRadius.circular(3),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppTheme.brandMagenta.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ] : [],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

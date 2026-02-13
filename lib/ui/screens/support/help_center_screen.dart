import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_HelpArticle> _filteredArticles = [];

  final List<_HelpArticle> _allArticles = [
    _HelpArticle(
      category: 'Getting Started',
      title: 'How do I create an account?',
      content:
          'To create an account, tap on the "Sign Up" button on the login screen. Fill in your details including email, password, and display name. You\'ll receive a verification email to activate your account.',
      icon: Icons.person_add,
    ),
    _HelpArticle(
      category: 'Account Management',
      title: 'How do I reset my password?',
      content:
          'On the login screen, tap "Forgot Password". Enter your registered email address and you\'ll receive a password reset link. Click the link in the email and follow the instructions to set a new password.',
      icon: Icons.lock_reset,
    ),
    _HelpArticle(
      category: 'Subscriptions',
      title: 'What are the subscription plans?',
      content:
          'We offer monthly and yearly subscription plans with unlimited streaming, offline downloads, and ad-free listening. Visit the Premium section in your profile to view current pricing and features.',
      icon: Icons.star,
    ),
    _HelpArticle(
      category: 'Subscriptions',
      title: 'How do I cancel my subscription?',
      content:
          'Go to Profile > Subscription Settings > Cancel Subscription. Your premium features will remain active until the end of your current billing period. You can resubscribe at any time.',
      icon: Icons.cancel_presentation,
    ),
    _HelpArticle(
      category: 'Playback',
      title: 'Why is my music not playing?',
      content:
          'Check your internet connection first. Ensure you have a stable connection. If the problem persists, try clearing the app cache in settings or restarting the app. For offline songs, verify they\'re downloaded.',
      icon: Icons.play_circle_outline,
    ),
    _HelpArticle(
      category: 'Downloads',
      title: 'How do I download songs for offline listening?',
      content:
          'Premium subscribers can download songs by tapping the download icon next to any song, album, or playlist. Downloaded content can be accessed from the Downloads section in your library.',
      icon: Icons.download,
    ),
    _HelpArticle(
      category: 'Audio Quality',
      title: 'How do I change audio quality?',
      content:
          'Go to Settings > Audio Quality. You can set different quality levels for streaming and downloads. Higher quality provides better sound but uses more data and storage.',
      icon: Icons.high_quality,
    ),
    _HelpArticle(
      category: 'Playlists',
      title: 'How do I create a playlist?',
      content:
          'Go to the Library tab and tap "Create Playlist". Give it a name and add songs by searching or browsing. You can also add songs to playlists from the song menu.',
      icon: Icons.playlist_add,
    ),
    _HelpArticle(
      category: 'Artists',
      title: 'How do I become an artist on FaithStream?',
      content:
          'To upload your music, apply for an artist account through our website. Once approved, you\'ll get access to the Artist Dashboard where you can upload songs, create albums, and track your streams.',
      icon: Icons.mic,
    ),
    _HelpArticle(
      category: 'Payments',
      title: 'What payment methods are accepted?',
      content:
          'We accept major credit/debit cards, UPI, net banking, and mobile wallets through our secure payment partner Razorpay. All transactions are encrypted and secure.',
      icon: Icons.payment,
    ),
    _HelpArticle(
      category: 'Privacy',
      title: 'How is my data protected?',
      content:
          'We use industry-standard encryption to protect your personal information. Your payment details are handled securely through Razorpay. We never share your data with third parties without consent.',
      icon: Icons.security,
    ),
    _HelpArticle(
      category: 'Troubleshooting',
      title: 'The app keeps crashing, what should I do?',
      content:
          'Try clearing the app cache from Settings. If that doesn\'t help, uninstall and reinstall the app. Make sure you\'re running the latest version. Contact support if the issue persists.',
      icon: Icons.bug_report,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredArticles = _allArticles;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterArticles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredArticles = _allArticles;
      } else {
        _filteredArticles = _allArticles.where((article) {
          final titleMatch = article.title.toLowerCase().contains(
            query.toLowerCase(),
          );
          final contentMatch = article.content.toLowerCase().contains(
            query.toLowerCase(),
          );
          final categoryMatch = article.category.toLowerCase().contains(
            query.toLowerCase(),
          );
          return titleMatch || contentMatch || categoryMatch;
        }).toList();
      }
    });
  }

  void _showArticle(_HelpArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArticleBottomSheet(article: article),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group articles by category
    final Map<String, List<_HelpArticle>> groupedArticles = {};
    for (var article in _filteredArticles) {
      groupedArticles.putIfAbsent(article.category, () => []).add(article);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterArticles('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.paddingMd),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _filterArticles,
            ),
          ),

          // Articles List
          Expanded(
            child: _filteredArticles.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    itemCount: groupedArticles.length,
                    itemBuilder: (context, index) {
                      final category = groupedArticles.keys.elementAt(index);
                      final articles = groupedArticles[category]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.paddingMd,
                              horizontal: AppSizes.paddingSm,
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                          ),

                          // Articles in this category
                          ...articles.map((article) {
                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: AppSizes.paddingSm,
                              ),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.paddingMd,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(AppSizes.paddingSm),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBrown.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.paddingSm,
                                    ),
                                  ),
                                  child: Icon(
                                    article.icon,
                                    color: AppColors.primaryBrown,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  article.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textTertiary,
                                ),
                                onTap: () => _showArticle(article),
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: AppSizes.paddingMd),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: AppSizes.paddingLg),
            Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              'Try different keywords or browse all articles',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpArticle {
  final String category;
  final String title;
  final String content;
  final IconData icon;

  _HelpArticle({
    required this.category,
    required this.title,
    required this.content,
    required this.icon,
  });
}

class _ArticleBottomSheet extends StatelessWidget {
  final _HelpArticle article;

  const _ArticleBottomSheet({required this.article});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.paddingLg),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingMd),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSizes.paddingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.paddingMd),
                        ),
                        child: Icon(
                          article.icon,
                          color: AppColors.primaryBrown,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingLg),

                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMd,
                          vertical: AppSizes.paddingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.paddingSm),
                        ),
                        child: Text(
                          article.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingMd),

                      // Title
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingLg),

                      // Content
                      Text(
                        article.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingXl),

                      // Help Footer
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.paddingMd),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: AppSizes.paddingMd),
                            Expanded(
                              child: Text(
                                'Still need help? Contact our support team.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
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
            ],
          ),
        );
      },
    );
  }
}

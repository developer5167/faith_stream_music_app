import 'package:faith_stream_music_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SupportHubScreen extends StatelessWidget {
  const SupportHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Help'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  const Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  Text(
                    'We\'re here to assist you with any questions or concerns',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingLg),

            // Support Options
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMd),

                  // Contact Support Card
                  _SupportOptionCard(
                    icon: Icons.headset_mic,
                    title: 'Contact Support',
                    description:
                        'Create a support ticket and get help from our team',
                    color: AppColors.info,
                    onTap: () => context.push('/support/contact'),
                  ),

                  // My Tickets Card
                  _SupportOptionCard(
                    icon: Icons.confirmation_number_outlined,
                    title: 'My Tickets',
                    description: 'View and track your support tickets',
                    color: AppColors.primaryBrown,
                    onTap: () => context.push('/support/my-tickets'),
                  ),

                  // // File Complaint Card
                  // _SupportOptionCard(
                  //   icon: Icons.report_problem_outlined,
                  //   title: 'File a Complaint',
                  //   description: 'Report inappropriate content or violations',
                  //   color: AppColors.warning,
                  //   onTap: () => context.push('/support/file-complaint'),
                  // ),

                  // // My Complaints Card
                  // _SupportOptionCard(
                  //   icon: Icons.history,
                  //   title: 'My Complaints',
                  //   description: 'Track the status of your complaints',
                  //   color: AppColors.error,
                  //   onTap: () => context.push('/support/my-complaints'),
                  // ),

                  // Help Center Card
                  _SupportOptionCard(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    description: 'Browse FAQs and helpful articles',
                    color: AppColors.success,
                    onTap: () => context.push('/support/help-center'),
                  ),

                  const SizedBox(height: AppSizes.paddingLg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _SupportOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.paddingMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.paddingMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.paddingMd),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: AppSizes.paddingMd),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXs),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../blocs/profile/profile_event.dart';
import '../../utils/constants.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded || state is ProfileOperationSuccess) {
          final profileState = state is ProfileOperationSuccess
              ? state.previousState
              : state as ProfileLoaded;

          final subscription = profileState.subscription;

          // If user has active subscription, show minimal UI or hide tab
          if (subscription != null && subscription.isActive) {
            return _buildActiveSubscription(context, subscription);
          }

          // Show subscription plans
          return _buildSubscriptionPlans(context);
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildActiveSubscription(BuildContext context, subscription) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.primaryGold.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 40),
                        const SizedBox(width: AppSizes.paddingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Premium Active',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subscription.planName,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    const Divider(),
                    const SizedBox(height: AppSizes.paddingMd),
                    _buildInfoRow('Amount', '₹${subscription.amount}/month'),
                    _buildInfoRow(
                      'Valid Until',
                      subscription.endDate != null
                          ? '${subscription.endDate!.day}/${subscription.endDate!.month}/${subscription.endDate!.year}'
                          : 'N/A',
                    ),
                    _buildInfoRow('Status', subscription.status.toUpperCase()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
            Text(
              'Benefits',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            _buildBenefitItem('Ad-free listening experience'),
            _buildBenefitItem('Unlimited song skips'),
            _buildBenefitItem('High quality audio streaming'),
            _buildBenefitItem('Offline downloads (coming soon)'),
            _buildBenefitItem('Early access to new releases'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlans(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium Plans')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Icon(Icons.stars, size: 80, color: AppColors.primaryGold),
                  const SizedBox(height: AppSizes.paddingMd),
                  Text(
                    'Upgrade to Premium',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  Text(
                    'Enjoy ad-free music and exclusive benefits',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingXl),

            // Monthly Plan (Popular)
            _buildPlanCard(
              context,
              planName: 'Premium Monthly',
              price: '₹99',
              period: '/month',
              features: [
                'Ad-free listening',
                'Unlimited skips',
                'High quality audio',
                'Cancel anytime',
              ],
              isPopular: true,
              onTap: () {
                _showSubscriptionConfirmation(context, 'Monthly', 99);
              },
            ),
            const SizedBox(height: AppSizes.paddingMd),

            // Yearly Plan (Best Value)
            _buildPlanCard(
              context,
              planName: 'Premium Yearly',
              price: '₹999',
              period: '/year',
              features: [
                'All Monthly features',
                'Save ₹189 per year',
                'Priority customer support',
                'Exclusive content access',
              ],
              discount: '17% OFF',
              onTap: () {
                _showSubscriptionConfirmation(context, 'Yearly', 999);
              },
            ),
            const SizedBox(height: AppSizes.paddingXl),

            // Benefits Section
            Text(
              'Why Premium?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            _buildFeatureRow(
              Icons.music_off,
              'Ad-Free',
              'Listen without interruptions',
            ),
            _buildFeatureRow(
              Icons.skip_next,
              'Unlimited Skips',
              'Skip songs as many times as you want',
            ),
            _buildFeatureRow(
              Icons.high_quality,
              'High Quality',
              'Stream music in premium audio quality',
            ),
            _buildFeatureRow(
              Icons.download,
              'Download',
              'Listen offline (coming soon)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String planName,
    required String price,
    required String period,
    required List<String> features,
    bool isPopular = false,
    String? discount,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular
            ? BorderSide(color: AppColors.primaryGold, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular || discount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPopular ? AppColors.primaryGold : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    discount ?? 'MOST POPULAR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isPopular || discount != null)
                const SizedBox(height: AppSizes.paddingMd),
              Text(
                planName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                  Text(
                    period,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingLg),
              const Divider(),
              const SizedBox(height: AppSizes.paddingMd),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: AppSizes.paddingSm),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMd),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular
                        ? AppColors.primaryGold
                        : AppColors.primaryBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Subscribe Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: AppSizes.paddingSm),
          Expanded(child: Text(benefit)),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBrown.withOpacity(0.1),
            child: Icon(icon, color: AppColors.primaryBrown),
          ),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionConfirmation(
    BuildContext context,
    String planType,
    int amount,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Subscription'),
        content: Text('Subscribe to Premium $planType plan for ₹$amount?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileBloc>().add(ProfileCreateSubscription());
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Payment integration coming soon! You can test without payment.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBrown,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }
}

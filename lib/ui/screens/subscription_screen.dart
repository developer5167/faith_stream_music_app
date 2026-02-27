import 'dart:io';
import 'package:faith_stream_music_app/ui/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../repositories/user_repository.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;

  // Android-only: Razorpay native SDK
  Razorpay? _razorpay;
  String? _pendingOrderId;

  // iOS-only: track when user leaves to browser
  bool _hasOpenedBrowser = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Only initialise Razorpay SDK on Android
    if (Platform.isAndroid) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _razorpay?.clear();
    super.dispose();
  }

  /// iOS: when user returns from Safari after payment, reload subscription
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isIOS &&
        state == AppLifecycleState.resumed &&
        _hasOpenedBrowser) {
      _hasOpenedBrowser = false;
      if (mounted) {
        // Small delay lets the webhook hit the server first
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.read<ProfileBloc>().add(ProfileLoad());
        });
      }
    }
  }

  // ── Android: Razorpay SDK callbacks ──────────────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<UserRepository>();
      final result = await repo.verifySubscriptionPayment(
        orderId: _pendingOrderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Premium activated! Enjoy ad-free listening.'),
              backgroundColor: Colors.green,
            ),
          );
          context.read<ProfileBloc>().add(ProfileLoad());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error verifying payment: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${response.message ?? 'Unknown error'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _isLoading = false);
  }

  // ── Android: Open native Razorpay checkout ────────────────────────────────

  Future<void> _subscribeAndroid(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      final repo = context.read<UserRepository>();
      final result = await repo.createSubscriptionOrder();

      if (result.success && result.data != null) {
        final data = result.data!;
        _pendingOrderId = data['order_id'] as String?;

        _razorpay!.open({
          'key': data['key_id'],
          'amount': data['amount'],
          'currency': data['currency'] ?? 'INR',
          'order_id': data['order_id'],
          'name': 'FaithStream Premium',
          'description': '1 Month Ad-Free Subscription',
          'prefill': {'contact': '', 'email': ''},
          'theme': {'color': '#6A0DAD'},
        });
        // isLoading reset in callbacks
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(SnackBar(content: Text(result.message)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── iOS: Create payment link and open in external browser ─────────────────

  Future<void> _subscribeIOS(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      final repo = context.read<UserRepository>();
      final result = await repo
          .createSubscription(); // reuses the /create-link endpoint

      if (result.success && result.data != null) {
        final paymentUrl = result.data!['payment_url'] as String?;
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          final uri = Uri.parse(paymentUrl);
          if (await canLaunchUrl(uri)) {
            _hasOpenedBrowser = true;
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not open payment page')),
            );
          }
        }
      } else {
        messenger.showSnackBar(SnackBar(content: Text(result.message)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Unified entry point ───────────────────────────────────────────────────

  Future<void> _subscribe(BuildContext context) {
    return Platform.isIOS ? _subscribeIOS(context) : _subscribeAndroid(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profileState = state is ProfileLoaded
            ? state
            : state is ProfileOperationSuccess
            ? state.previousState
            : null;
        final sub = profileState?.subscription;
        final isActive = sub?.isActive ?? false;

        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Subscription',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh',
                  onPressed: () =>
                      context.read<ProfileBloc>().add(ProfileLoad()),
                ),
              ],
            ),
            body: RefreshIndicator(
              color: const Color(0xFF6A0DAD),
              backgroundColor: Colors.black,
              onRefresh: () async {
                context.read<ProfileBloc>().add(ProfileLoad());
                // Wait a moment for the bloc to process
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Hero header ───────────────────────────────────────
                    Column(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          size: 72,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isActive ? 'You\'re on Premium!' : 'Go Premium',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isActive
                              ? 'Thank you for supporting FaithStream'
                              : 'Unlock the full FaithStream experience',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    if (isActive && sub != null)
                      _ActiveSubscriptionCard(subscription: sub)
                    else ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text(
                          'Choose Your Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Free plan
                      _PlanCard(
                        name: 'Free',
                        price: '₹0',
                        period: 'forever',
                        features: const [
                          _Feature('Ads between songs', false),
                          _Feature('0 skips', false),
                          _Feature('Offline downloads', false),
                        ],
                        isHighlighted: false,
                        isCurrentPlan: !isActive,
                        onSelect: null,
                        isLoading: false,
                      ),

                      // Premium plan
                      _PlanCard(
                        name: 'Premium',
                        price: '₹99',
                        period: '/month',
                        features: const [
                          _Feature('Ad-free listening', true),
                          _Feature('Unlimited skips', true),
                          _Feature('Background play', true),
                          _Feature('Offline downloads', true),
                        ],
                        isHighlighted: true,
                        isCurrentPlan: false,
                        onSelect: _isLoading ? null : () => _subscribe(context),
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Payment processed securely via Razorpay. '
                          'Your browser will open to complete the payment. '
                          'Subscription activates instantly after payment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Active subscription card ──────────────────────────────────────────────────

class _ActiveSubscriptionCard extends StatelessWidget {
  final dynamic subscription;
  const _ActiveSubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final endDate = subscription.endDate as DateTime?;
    final daysLeft = endDate != null
        ? endDate.difference(DateTime.now()).inDays
        : 0;
    final progress = endDate != null
        ? ((30 - daysLeft) / 30).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A0DAD), Color(0xFF9C27B0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A0DAD).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Premium Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (endDate != null) ...[
            Text(
              'Expires on ${_fmt(endDate)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 6),
            Text(
              '$daysLeft days remaining',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          for (final f in [
            'Ad-free listening',
            'Unlimited skips',
            'Background play',
            'Offline downloads',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _Feature {
  final String label;
  final bool included;
  const _Feature(this.label, this.included);
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final List<_Feature> features;
  final bool isHighlighted;
  final bool isCurrentPlan;
  final VoidCallback? onSelect;
  final bool isLoading;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    required this.isHighlighted,
    required this.isCurrentPlan,
    required this.onSelect,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color.fromARGB(255, 1, 45, 17)
            : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? Color.fromARGB(255, 1, 45, 17)
              : Colors.white12,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan name + price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isHighlighted ? Colors.amber : Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isHighlighted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'BEST',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: price,
                        style: TextStyle(
                          color: isHighlighted ? Colors.amber : Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: period,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Features
            for (final f in features)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      f.included ? Icons.check_circle : Icons.cancel,
                      color: f.included ? Colors.green : Colors.white24,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      f.label,
                      style: TextStyle(
                        color: f.included ? Colors.white : Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // CTA Button
            if (onSelect != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 1, 69, 26),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          Platform.isIOS ? 'Get Started' : 'Subscribe Now',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],

            if (isCurrentPlan && onSelect == null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white38, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Current Plan',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

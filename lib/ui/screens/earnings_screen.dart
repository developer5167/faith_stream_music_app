import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/payout/payout_bloc.dart';
import '../../blocs/payout/payout_event.dart';
import '../../blocs/payout/payout_state.dart';
import '../../models/payout.dart';
import '../../services/api_client.dart';
import '../../services/payout_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import 'bank_details_screen.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  static Future<PayoutBloc> _createBloc() async {
    final storage = StorageService(
      const FlutterSecureStorage(),
      await SharedPreferences.getInstance(),
    );
    return PayoutBloc(PayoutService(ApiClient(storage)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PayoutBloc>(
      future: _createBloc(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BlocProvider(
          create: (_) => snapshot.data!..add(const PayoutLoadEarnings()),
          child: const _EarningsView(),
        );
      },
    );
  }
}

class _EarningsView extends StatelessWidget {
  const _EarningsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PayoutBloc, PayoutState>(
      listener: (context, state) {
        if (state is PayoutActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is PayoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final earningsState = _resolveEarningsState(state);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'My Earnings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (earningsState != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () =>
                      context.read<PayoutBloc>().add(const PayoutRefresh()),
                ),
            ],
          ),
          body: state is PayoutLoading
              ? const Center(child: CircularProgressIndicator())
              : earningsState == null
              ? _buildError(context, state)
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<PayoutBloc>().add(const PayoutRefresh());
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    children: [
                      _buildWalletCard(context, earningsState),
                      const SizedBox(height: 20),
                      _buildActionButtons(context, earningsState),
                      const SizedBox(height: 20),
                      _buildMonthlyEarnings(context, earningsState),
                      const SizedBox(height: 20),
                      _buildPayoutHistory(context, earningsState),
                    ],
                  ),
                ),
        );
      },
    );
  }

  PayoutEarningsLoaded? _resolveEarningsState(PayoutState state) {
    if (state is PayoutEarningsLoaded) return state;
    if (state is PayoutActionInProgress) return state.previousState;
    if (state is PayoutActionSuccess) return state.updatedState;
    if (state is PayoutError) return state.previousState;
    return null;
  }

  Widget _buildError(BuildContext context, PayoutState state) {
    final message = state is PayoutError
        ? state.message
        : 'Unable to load earnings';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<PayoutBloc>().add(const PayoutLoadEarnings()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, PayoutEarningsLoaded state) {
    final wallet = state.earnings.wallet;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B21A8).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${wallet.balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildWalletStat(
                    'Total Earned',
                    '₹${wallet.totalEarned.toStringAsFixed(2)}',
                    Icons.trending_up,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: _buildWalletStat(
                    'Total Paid Out',
                    '₹${wallet.totalPaidOut.toStringAsFixed(2)}',
                    Icons.payments_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PayoutEarningsLoaded state) {
    final hasBankDetails = state.bankDetails != null;
    final balance = state.earnings.wallet.balance;
    final hasPendingRequest = state.earnings.payoutRequests.any(
      (r) => r.isPending || r.isProcessing,
    );

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.account_balance,
            label: hasBankDetails ? 'View Bank Details' : 'Add Bank/UPI',
            color: const Color(0xFF4F46E5),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<PayoutBloc>(),
                  child: BankDetailsScreen(existingDetails: state.bankDetails),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.send_to_mobile,
            label: hasPendingRequest ? 'Request Pending' : 'Withdraw',
            color: balance >= 100 && !hasPendingRequest
                ? const Color(0xFF059669)
                : Colors.grey.shade700,
            onTap: balance >= 100 && hasBankDetails && !hasPendingRequest
                ? () => _showWithdrawDialog(context, balance)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(onTap != null ? 0.15 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(onTap != null ? 0.4 : 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: onTap != null ? color : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyEarnings(
    BuildContext context,
    PayoutEarningsLoaded state,
  ) {
    final earnings = state.earnings.monthlyEarnings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Earnings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (earnings.isEmpty)
          _buildEmptyCard(
            'No earnings recorded yet.\nEarnings are calculated on the 1st of each month.',
          )
        else
          ...earnings.map((e) => _buildEarningRow(e)),
      ],
    );
  }

  Widget _buildEarningRow(MonthlyEarning earning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6B21A8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Color(0xFFA855F7),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earning.month,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${earning.totalStreams} streams',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${earning.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: earning.isPaid
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  earning.status,
                  style: TextStyle(
                    color: earning.isPaid ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutHistory(BuildContext context, PayoutEarningsLoaded state) {
    final requests = state.earnings.payoutRequests;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payout Requests',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (requests.isEmpty)
          _buildEmptyCard(
            'No withdrawal requests yet.\nRequest a payout once your balance reaches ₹100.',
          )
        else
          ...requests.map((r) => _buildRequestRow(r)),
      ],
    );
  }

  Widget _buildRequestRow(PayoutRequest request) {
    Color statusColor = Colors.orange;
    if (request.isCompleted) statusColor = Colors.green;
    if (request.isFailed) statusColor = Colors.red;
    if (request.isProcessing) statusColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.send_to_mobile, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${request.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _formatDate(request.requestedAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                if (request.failureReason != null)
                  Text(
                    request.failureReason!,
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              request.status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showWithdrawDialog(BuildContext context, double balance) {
    final controller = TextEditingController(text: balance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Request Withdrawal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Available Balance: ₹${balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF6B21A8)),
                ),
                helperText: 'Minimum withdrawal: ₹100',
                helperStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B21A8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount >= 100) {
                context.read<PayoutBloc>().add(PayoutRequestWithdrawal(amount));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Request Payout'),
          ),
        ],
      ),
    );
  }
}

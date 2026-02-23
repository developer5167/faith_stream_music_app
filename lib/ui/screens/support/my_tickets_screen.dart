import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/support_ticket.dart';
import '../../../services/api_client.dart';
import '../../../services/storage_service.dart';
import '../../../services/support_service.dart';
import '../../../utils/constants.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/ticket_card.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late final SupportService _supportService;
  List<SupportTicket>? _tickets;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final storageService = StorageService(
      const FlutterSecureStorage(),
      await SharedPreferences.getInstance(),
    );
    final apiClient = ApiClient(storageService);
    _supportService = SupportService(apiClient);
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tickets = await _supportService.getMyTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showTicketDetails(SupportTicket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TicketDetailsBottomSheet(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/support/contact'),
            tooltip: 'Create New Ticket',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_error != null) {
      return ErrorDisplay(message: _error!, onRetry: _loadTickets);
    }

    if (_tickets == null || _tickets!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: AppColors.primaryBrown,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMd),
        itemCount: _tickets!.length,
        itemBuilder: (context, index) {
          final ticket = _tickets![index];
          return TicketCard(
            ticket: ticket,
            onTap: () => _showTicketDetails(ticket),
          );
        },
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
            Icon(
              Icons.confirmation_number_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppSizes.paddingLg),
            Text(
              'No Support Tickets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              'You haven\'t created any support tickets yet.\nNeed help? Contact our support team.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: AppSizes.paddingXl),
            ElevatedButton.icon(
              onPressed: () => context.push('/support/contact'),
              icon: const Icon(Icons.headset_mic),
              label: const Text('Contact Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLg,
                  vertical: AppSizes.paddingMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailsBottomSheet extends StatelessWidget {
  final SupportTicket ticket;

  const _TicketDetailsBottomSheet({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.paddingLg),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: AppSizes.paddingMd,
                ),
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
                      // Subject
                      Text(
                        ticket.subject,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),

                      // Status and Category Row
                      Row(
                        children: [
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMd,
                              vertical: AppSizes.paddingXs,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                ticket.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.paddingSm,
                              ),
                            ),
                            child: Text(
                              ticket.status.displayText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(ticket.status),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSm),

                          // Category
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMd,
                              vertical: AppSizes.paddingXs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.paddingSm,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(ticket.category),
                                  size: 14,
                                  color: AppColors.primaryBrown,
                                ),
                                const SizedBox(width: AppSizes.paddingXs),
                                Text(
                                  ticket.category.displayText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBrown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.paddingLg),

                      // Description
                      Text(
                        'Your Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSm),
                      Text(
                        ticket.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),

                      // Admin Response
                      if (ticket.adminResponse != null) ...[
                        const SizedBox(height: AppSizes.paddingLg),
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingMd),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.paddingMd,
                            ),
                            border: Border.all(
                              color: AppColors.primaryGold.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.support_agent,
                                    size: 20,
                                    color: AppColors.primaryGold,
                                  ),
                                  const SizedBox(width: AppSizes.paddingSm),
                                  Text(
                                    'Support Team Response',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.paddingSm),
                              Text(
                                ticket.adminResponse!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSizes.paddingLg),

                      // Timestamps
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Created',
                        value: _formatDate(ticket.createdAt),
                      ),
                      const SizedBox(height: AppSizes.paddingSm),
                      _InfoRow(
                        icon: Icons.update,
                        label: 'Last Updated',
                        value: _formatDate(ticket.updatedAt),
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

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return AppColors.warning;
      case TicketStatus.inProgress:
        return AppColors.info;
      case TicketStatus.resolved:
        return AppColors.success;
      case TicketStatus.closed:
        return Colors.grey.shade700;
    }
  }

  IconData _getCategoryIcon(TicketCategory category) {
    switch (category) {
      case TicketCategory.account:
        return Icons.person_outline;
      case TicketCategory.payment:
        return Icons.payment;
      case TicketCategory.technical:
        return Icons.build_outlined;
      case TicketCategory.other:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: AppSizes.paddingSm),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}

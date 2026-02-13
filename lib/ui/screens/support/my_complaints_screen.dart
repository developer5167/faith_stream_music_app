import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/complaint.dart';
import '../../../services/api_client.dart';
import '../../../services/complaint_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/constants.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  late final ComplaintService _complaintService;
  List<Complaint>? _complaints;
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
    _complaintService = ComplaintService(apiClient);
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final complaints = await _complaintService.getMyComplaints();
      if (mounted) {
        setState(() {
          _complaints = complaints;
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

  void _showComplaintDetails(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComplaintDetailsBottomSheet(complaint: complaint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/support/file-complaint'),
            tooltip: 'File New Complaint',
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
      return ErrorDisplay(message: _error!, onRetry: _loadComplaints);
    }

    if (_complaints == null || _complaints!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      color: AppColors.primaryBrown,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMd),
        itemCount: _complaints!.length,
        itemBuilder: (context, index) {
          final complaint = _complaints![index];
          return ComplaintCard(
            complaint: complaint,
            onTap: () => _showComplaintDetails(complaint),
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
              Icons.description_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppSizes.paddingLg),
            Text(
              'No Complaints Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              'You haven\'t filed any complaints.\nIf you encounter any issues, feel free to report them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.paddingXl),
            ElevatedButton.icon(
              onPressed: () => context.push('/support/file-complaint'),
              icon: const Icon(Icons.add),
              label: const Text('File a Complaint'),
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

class _ComplaintDetailsBottomSheet extends StatelessWidget {
  final Complaint complaint;

  const _ComplaintDetailsBottomSheet({required this.complaint});

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
                      // Title
                      Text(
                        complaint.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),

                      // Status
                      Row(
                        children: [
                          Text(
                            'Status: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingMd,
                              vertical: AppSizes.paddingXs,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                complaint.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.paddingSm,
                              ),
                            ),
                            child: Text(
                              complaint.status.displayText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(complaint.status),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.paddingLg),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSm),
                      Text(
                        complaint.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      // Content Type
                      if (complaint.contentType != null) ...[
                        const SizedBox(height: AppSizes.paddingLg),
                        Text(
                          'Content Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSm),
                        Text(
                          complaint.contentType!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],

                      // Admin Notes
                      if (complaint.adminNotes != null) ...[
                        const SizedBox(height: AppSizes.paddingLg),
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingMd),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBrown.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(
                              AppSizes.paddingMd,
                            ),
                            border: Border.all(
                              color: AppColors.primaryBrown.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings,
                                    size: 20,
                                    color: AppColors.primaryBrown,
                                  ),
                                  const SizedBox(width: AppSizes.paddingSm),
                                  Text(
                                    'Admin Response',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryBrown,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.paddingSm),
                              Text(
                                complaint.adminNotes!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
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
                        value: _formatDate(complaint.createdAt),
                      ),
                      const SizedBox(height: AppSizes.paddingSm),
                      _InfoRow(
                        icon: Icons.update,
                        label: 'Last Updated',
                        value: _formatDate(complaint.updatedAt),
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

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return AppColors.warning;
      case ComplaintStatus.inReview:
        return AppColors.info;
      case ComplaintStatus.resolved:
        return AppColors.success;
      case ComplaintStatus.rejected:
        return AppColors.error;
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
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

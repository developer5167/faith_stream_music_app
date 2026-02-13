import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/complaint.dart';
import '../../utils/constants.dart';
import 'status_badge.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback? onTap;

  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.paddingMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.paddingMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSm),
                  StatusBadge.forComplaintStatus(complaint.status),
                ],
              ),
              const SizedBox(height: AppSizes.paddingSm),

              // Description
              Text(
                complaint.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.paddingMd),

              // Content Info (if available)
              if (complaint.contentType != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
                  child: Row(
                    children: [
                      Icon(
                        _getIconForContentType(complaint.contentType!),
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: AppSizes.paddingXs),
                      Text(
                        complaint.contentType!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Admin Notes (if available and resolved/rejected)
              if (complaint.adminNotes != null &&
                  (complaint.status == ComplaintStatus.resolved ||
                      complaint.status == ComplaintStatus.rejected))
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingSm),
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSizes.paddingSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 16,
                        color: AppColors.primaryBrown,
                      ),
                      const SizedBox(width: AppSizes.paddingXs),
                      Expanded(
                        child: Text(
                          complaint.adminNotes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Timestamp
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSizes.paddingXs),
                  Text(
                    timeago.format(complaint.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (complaint.status != ComplaintStatus.pending) ...[
                    const SizedBox(width: AppSizes.paddingMd),
                    Icon(
                      Icons.update,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSizes.paddingXs),
                    Text(
                      'Updated ${timeago.format(complaint.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'song':
        return Icons.music_note;
      case 'album':
        return Icons.album;
      case 'artist':
        return Icons.person;
      case 'playlist':
        return Icons.playlist_play;
      default:
        return Icons.info_outline;
    }
  }
}

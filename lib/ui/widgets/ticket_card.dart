import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/support_ticket.dart';
import '../../utils/constants.dart';
import 'status_badge.dart';

class TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

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
              // Subject and Status Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
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
                  StatusBadge.forTicketStatus(ticket.status),
                ],
              ),
              const SizedBox(height: AppSizes.paddingSm),

              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSm,
                  vertical: AppSizes.paddingXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.paddingSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIconForCategory(ticket.category),
                      size: 14,
                      color: AppColors.primaryBrown,
                    ),
                    const SizedBox(width: AppSizes.paddingXs),
                    Text(
                      ticket.category.displayText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingSm),

              // Description
              Text(
                ticket.description,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Admin Response (if available)
              if (ticket.adminResponse != null) ...[
                const SizedBox(height: AppSizes.paddingMd),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingSm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.paddingSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.support_agent,
                            size: 16,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(width: AppSizes.paddingXs),
                          Text(
                            'Admin Response',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingXs),
                      Text(
                        ticket.adminResponse!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.paddingMd),

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
                    timeago.format(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (ticket.status != TicketStatus.open) ...[
                    const SizedBox(width: AppSizes.paddingMd),
                    Icon(Icons.update, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: AppSizes.paddingXs),
                    Text(
                      'Updated ${timeago.format(ticket.updatedAt)}',
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

  IconData _getIconForCategory(TicketCategory category) {
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
}

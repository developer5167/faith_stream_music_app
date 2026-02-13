import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../models/support_ticket.dart';
import '../../utils/constants.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  // Factory constructor for complaint status
  factory StatusBadge.forComplaintStatus(ComplaintStatus status) {
    Color bgColor;
    Color txtColor;

    switch (status) {
      case ComplaintStatus.pending:
        bgColor = AppColors.warning.withOpacity(0.1);
        txtColor = AppColors.warning;
        break;
      case ComplaintStatus.inReview:
        bgColor = AppColors.info.withOpacity(0.1);
        txtColor = AppColors.info;
        break;
      case ComplaintStatus.resolved:
        bgColor = AppColors.success.withOpacity(0.1);
        txtColor = AppColors.success;
        break;
      case ComplaintStatus.rejected:
        bgColor = AppColors.error.withOpacity(0.1);
        txtColor = AppColors.error;
        break;
    }

    return StatusBadge(
      text: status.displayText,
      backgroundColor: bgColor,
      textColor: txtColor,
    );
  }

  // Factory constructor for ticket status
  factory StatusBadge.forTicketStatus(TicketStatus status) {
    Color bgColor;
    Color txtColor;

    switch (status) {
      case TicketStatus.open:
        bgColor = AppColors.warning.withOpacity(0.1);
        txtColor = AppColors.warning;
        break;
      case TicketStatus.inProgress:
        bgColor = AppColors.info.withOpacity(0.1);
        txtColor = AppColors.info;
        break;
      case TicketStatus.resolved:
        bgColor = AppColors.success.withOpacity(0.1);
        txtColor = AppColors.success;
        break;
      case TicketStatus.closed:
        bgColor = Colors.grey.withOpacity(0.1);
        txtColor = Colors.grey.shade700;
        break;
    }

    return StatusBadge(
      text: status.displayText,
      backgroundColor: bgColor,
      textColor: txtColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingXs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.paddingMd),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

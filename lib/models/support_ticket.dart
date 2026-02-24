import 'package:equatable/equatable.dart';

enum TicketCategory {
  account,
  payment,
  technical,
  other;

  static TicketCategory fromString(String category) {
    switch (category.toUpperCase()) {
      case 'ACCOUNT':
        return TicketCategory.account;
      case 'PAYMENT':
        return TicketCategory.payment;
      case 'TECHNICAL':
        return TicketCategory.technical;
      case 'OTHER':
        return TicketCategory.other;
      default:
        return TicketCategory.other;
    }
  }

  String get displayText {
    switch (this) {
      case TicketCategory.account:
        return 'Account';
      case TicketCategory.payment:
        return 'Payment';
      case TicketCategory.technical:
        return 'Technical';
      case TicketCategory.other:
        return 'Other';
    }
  }

  String toApiString() {
    switch (this) {
      case TicketCategory.account:
        return 'ACCOUNT';
      case TicketCategory.payment:
        return 'PAYMENT';
      case TicketCategory.technical:
        return 'TECHNICAL';
      case TicketCategory.other:
        return 'OTHER';
    }
  }
}

enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  static TicketStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return TicketStatus.open;
      case 'IN_PROGRESS':
        return TicketStatus.inProgress;
      case 'RESOLVED':
        return TicketStatus.resolved;
      case 'CLOSED':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  String get displayText {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  String toApiString() {
    switch (this) {
      case TicketStatus.open:
        return 'OPEN';
      case TicketStatus.inProgress:
        return 'IN_PROGRESS';
      case TicketStatus.resolved:
        return 'RESOLVED';
      case TicketStatus.closed:
        return 'CLOSED';
    }
  }
}

class SupportTicket extends Equatable {
  final String id;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketStatus status;
  final String? adminResponse;
  final String? adminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.status,
    this.adminResponse,
    this.adminId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      subject: json['subject'] as String? ?? 'No Subject',
      description:
          json['message'] as String? ?? json['description'] as String? ?? '',
      category: TicketCategory.fromString(json['category'] as String? ?? ''),
      status: TicketStatus.fromString(json['status'] as String? ?? ''),
      adminResponse:
          json['admin_reply'] as String? ?? json['admin_response'] as String?,
      adminId: json['admin_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'category': category.toApiString(),
      'status': status.toApiString(),
      'admin_response': adminResponse,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SupportTicket copyWith({
    String? id,
    String? subject,
    String? description,
    TicketCategory? category,
    TicketStatus? status,
    String? adminResponse,
    String? adminId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    subject,
    description,
    category,
    status,
    adminResponse,
    adminId,
    createdAt,
    updatedAt,
  ];
}

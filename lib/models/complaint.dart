import 'package:equatable/equatable.dart';

enum ComplaintStatus {
  pending,
  inReview,
  resolved,
  rejected;

  static ComplaintStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ComplaintStatus.pending;
      case 'in_review':
        return ComplaintStatus.inReview;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'rejected':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.pending;
    }
  }

  String get displayText {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.inReview:
        return 'In Review';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  String toApiString() {
    switch (this) {
      case ComplaintStatus.pending:
        return 'pending';
      case ComplaintStatus.inReview:
        return 'in_review';
      case ComplaintStatus.resolved:
        return 'resolved';
      case ComplaintStatus.rejected:
        return 'rejected';
    }
  }
}

class Complaint extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? contentId;
  final String? contentType;
  final ComplaintStatus status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Complaint({
    required this.id,
    required this.title,
    required this.description,
    this.contentId,
    this.contentType,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      contentId: json['content_id']?.toString(),
      contentType: json['content_type'] as String?,
      status: ComplaintStatus.fromString(json['status'] as String? ?? ''),
      adminNotes: json['admin_notes'] as String?,
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
      'title': title,
      'description': description,
      'content_id': contentId,
      'content_type': contentType,
      'status': status.toApiString(),
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Complaint copyWith({
    String? id,
    String? title,
    String? description,
    String? contentId,
    String? contentType,
    ComplaintStatus? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    contentId,
    contentType,
    status,
    adminNotes,
    createdAt,
    updatedAt,
  ];
}

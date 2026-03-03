import 'package:equatable/equatable.dart';

enum ComplaintStatus {
  pending,
  open,
  inReview,
  resolved,
  rejected;

  static ComplaintStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return ComplaintStatus.pending;
      case 'OPEN':
        return ComplaintStatus.open;
      case 'IN_REVIEW':
        return ComplaintStatus.inReview;
      case 'RESOLVED':
        return ComplaintStatus.resolved;
      case 'REJECTED':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.pending;
    }
  }

  String get displayText {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.open:
        return 'Open';
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
        return 'PENDING';
      case ComplaintStatus.open:
        return 'OPEN';
      case ComplaintStatus.inReview:
        return 'IN_REVIEW';
      case ComplaintStatus.resolved:
        return 'RESOLVED';
      case ComplaintStatus.rejected:
        return 'REJECTED';
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
  final String? artistName;
  final String? songName;
  final String? albumName;
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
    this.artistName,
    this.songName,
    this.albumName,
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
      artistName: json['artist_name'] as String?,
      songName: json['song_name'] as String?,
      albumName: json['album_name'] as String?,
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
      'artist_name': artistName,
      'song_name': songName,
      'album_name': albumName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
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
    artistName,
    songName,
    albumName,
    createdAt,
    updatedAt,
  ];
}

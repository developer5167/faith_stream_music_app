import '../models/complaint.dart';
import '../services/api_client.dart';
import '../utils/exceptions.dart';

class ComplaintService {
  final ApiClient _apiClient;

  ComplaintService(this._apiClient);

  // File a new complaint
  Future<Complaint> fileComplaint({
    required String title,
    required String description,
    String? contentId,
    String? contentType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/complaints',
        data: {
          'title': title,
          'description': description,
          if (contentId != null) 'content_id': contentId,
          if (contentType != null) 'content_type': contentType,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final complaintData = response.data is Map
            ? (response.data['complaint'] ??
                  response.data['data'] ??
                  response.data)
            : null;
        if (complaintData != null && complaintData is Map<String, dynamic>) {
          return Complaint.fromJson(complaintData);
        } else if (response.data is Map<String, dynamic> &&
            response.data['id'] != null) {
          return Complaint.fromJson(response.data);
        }

        // If the backend returns a generic success message without data, try parsing anyway or throw
        throw AppException('Complaint filed but no data returned');
      }

      throw AppException(
        (response.data is Map)
            ? response.data['message'] ?? 'Failed to file complaint'
            : 'Failed to file complaint',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get user's complaints
  Future<List<Complaint>> getMyComplaints() async {
    try {
      final response = await _apiClient.get('/complaints/my');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .map(
                (json) => Complaint.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
        } else if (data is Map &&
            data['success'] == true &&
            data['data'] is List) {
          final List<dynamic> complaintsJson = data['data'];
          return complaintsJson
              .map(
                (json) => Complaint.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
        }
      }

      throw AppException(
        (response.data is Map)
            ? response.data['message'] ?? 'Failed to fetch complaints'
            : 'Failed to fetch complaints',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get a single complaint by ID
  Future<Complaint> getComplaintById(String complaintId) async {
    try {
      final response = await _apiClient.get('/complaints/$complaintId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['data'] != null) {
          return Complaint.fromJson(Map<String, dynamic>.from(data['data']));
        } else if (data is Map && data['id'] != null) {
          return Complaint.fromJson(Map<String, dynamic>.from(data));
        }
      }

      throw AppException(
        (response.data is Map)
            ? response.data['message'] ?? 'Failed to fetch complaint'
            : 'Failed to fetch complaint',
      );
    } catch (e) {
      rethrow;
    }
  }
}

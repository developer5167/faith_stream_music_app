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

      if (response.statusCode == 201 && response.data['success'] == true) {
        return Complaint.fromJson(response.data['data']);
      } else {
        throw AppException(
          response.data['message'] ?? 'Failed to file complaint',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user's complaints
  Future<List<Complaint>> getMyComplaints() async {
    try {
      final response = await _apiClient.get('/complaints/my');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> complaintsJson = response.data['data'];
        return complaintsJson
            .map((json) => Complaint.fromJson(json))
            .toList();
      } else {
        throw AppException(
          response.data['message'] ?? 'Failed to fetch complaints',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get a single complaint by ID
  Future<Complaint> getComplaintById(String complaintId) async {
    try {
      final response = await _apiClient.get('/complaints/$complaintId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Complaint.fromJson(response.data['data']);
      } else {
        throw AppException(
          response.data['message'] ?? 'Failed to fetch complaint',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

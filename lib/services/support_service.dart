import '../models/support_ticket.dart';
import '../services/api_client.dart';
import '../utils/exceptions.dart';

class SupportService {
  final ApiClient _apiClient;

  SupportService(this._apiClient);

  // Create a new support ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required TicketCategory category,
  }) async {
    try {
      final response = await _apiClient.post(
        '/support',
        data: {
          'subject': subject,
          'description': description,
          'category': category.toApiString(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final ticketData = response.data['ticket'] ?? response.data['data'];
        if (ticketData != null) {
          return SupportTicket.fromJson(ticketData);
        }
      }

      throw AppException(
        (response.data is Map)
            ? response.data['message'] ?? 'Failed to create support ticket'
            : 'Failed to create support ticket',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get user's support tickets
  Future<List<SupportTicket>> getMyTickets() async {
    try {
      final response = await _apiClient.get('/support/my');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .map(
                (json) =>
                    SupportTicket.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
        } else if (data is Map &&
            data['success'] == true &&
            data['data'] is List) {
          final List<dynamic> ticketsJson = data['data'];
          return ticketsJson
              .map(
                (json) =>
                    SupportTicket.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
        }
      }

      throw AppException(
        (response.data is Map)
            ? response.data['message'] ?? 'Failed to fetch support tickets'
            : 'Failed to fetch support tickets',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get a single support ticket by ID
  Future<SupportTicket> getTicketById(String ticketId) async {
    try {
      final response = await _apiClient.get('/support/$ticketId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['data'] != null) {
          return SupportTicket.fromJson(
            Map<String, dynamic>.from(data['data']),
          );
        } else if (data is Map && data['id'] != null) {
          return SupportTicket.fromJson(Map<String, dynamic>.from(data));
        }
      }

      throw AppException(
        (response.data is Map)
            ? response.data['message'] ?? 'Failed to fetch support ticket'
            : 'Failed to fetch support ticket',
      );
    } catch (e) {
      rethrow;
    }
  }
}

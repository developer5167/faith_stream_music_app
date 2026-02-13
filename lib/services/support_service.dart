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

      if (response.statusCode == 201 && response.data['success'] == true) {
        return SupportTicket.fromJson(response.data['data']);
      } else {
        throw AppException(
          response.data['message'] ?? 'Failed to create support ticket',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user's support tickets
  Future<List<SupportTicket>> getMyTickets() async {
    try {
      final response = await _apiClient.get('/support/my');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> ticketsJson = response.data['data'];
        return ticketsJson
            .map((json) => SupportTicket.fromJson(json))
            .toList();
      } else {
        throw AppException(
          response.data['message'] ?? 'Failed to fetch support tickets',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get a single support ticket by ID
  Future<SupportTicket> getTicketById(String ticketId) async {
    try {
      final response = await _apiClient.get('/support/$ticketId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return SupportTicket.fromJson(response.data['data']);
      } else {
        throw AppException(
          response.data['message'] ?? 'Failed to fetch support ticket',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

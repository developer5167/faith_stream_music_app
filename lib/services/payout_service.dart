import '../models/payout.dart';
import '../services/api_client.dart';

class PayoutService {
  final ApiClient _apiClient;

  PayoutService(this._apiClient);

  // Get artist earnings: wallet + monthly history + payout requests
  Future<ArtistEarningsData> getEarnings() async {
    final response = await _apiClient.get('/payouts/earnings');
    return ArtistEarningsData.fromJson(
      response.data is Map ? response.data : {},
    );
  }

  // Get saved bank / UPI details
  Future<ArtistBankDetails?> getBankDetails() async {
    final response = await _apiClient.get('/payouts/bank-details');
    final data = response.data;
    if (data == null || (data is Map && data.isEmpty)) return null;
    return ArtistBankDetails.fromJson(data);
  }

  // Save / update bank or UPI details
  Future<ArtistBankDetails> saveBankDetails(ArtistBankDetails details) async {
    final response = await _apiClient.post(
      '/payouts/bank-details',
      data: details.toJson(),
    );
    return ArtistBankDetails.fromJson(
      response.data['details'] ?? response.data,
    );
  }

  // Request a withdrawal
  Future<PayoutRequest> requestWithdrawal(double amount) async {
    final response = await _apiClient.post(
      '/payouts/withdraw',
      data: {'amount': amount},
    );
    return PayoutRequest.fromJson(response.data['request'] ?? response.data);
  }

  // Get artist's own payout request history
  Future<List<PayoutRequest>> getPayoutRequests() async {
    final response = await _apiClient.get('/payouts/requests');
    final List<dynamic> list = response.data is List ? response.data : [];
    return list.map((e) => PayoutRequest.fromJson(e)).toList();
  }
}

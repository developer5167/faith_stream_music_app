// Models for Artist Payout System

class ArtistWallet {
  final String artistUserId;
  final double balance;
  final double totalEarned;
  final double totalPaidOut;
  final DateTime? updatedAt;

  const ArtistWallet({
    required this.artistUserId,
    required this.balance,
    required this.totalEarned,
    required this.totalPaidOut,
    this.updatedAt,
  });

  factory ArtistWallet.fromJson(Map<String, dynamic> json) {
    return ArtistWallet(
      artistUserId: json['artist_user_id']?.toString() ?? '',
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      totalEarned:
          double.tryParse(json['total_earned']?.toString() ?? '0') ?? 0.0,
      totalPaidOut:
          double.tryParse(json['total_paid_out']?.toString() ?? '0') ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  ArtistWallet empty() => const ArtistWallet(
    artistUserId: '',
    balance: 0,
    totalEarned: 0,
    totalPaidOut: 0,
  );
}

class MonthlyEarning {
  final String id;
  final String artistUserId;
  final String month;
  final int totalStreams;
  final double amount;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  const MonthlyEarning({
    required this.id,
    required this.artistUserId,
    required this.month,
    required this.totalStreams,
    required this.amount,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  factory MonthlyEarning.fromJson(Map<String, dynamic> json) {
    return MonthlyEarning(
      id: json['id']?.toString() ?? '',
      artistUserId: json['artist_user_id']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      totalStreams: int.tryParse(json['total_streams']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'])
          : null,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isPaid => status == 'PAID';
}

class ArtistBankDetails {
  final String? id;
  final String artistUserId;
  final String paymentType; // 'UPI' or 'BANK'
  final String? upiId;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountName;
  final String? panNumber;
  final bool isVerified;

  const ArtistBankDetails({
    this.id,
    required this.artistUserId,
    required this.paymentType,
    this.upiId,
    this.accountNumber,
    this.ifscCode,
    this.accountName,
    this.panNumber,
    this.isVerified = false,
  });

  factory ArtistBankDetails.fromJson(Map<String, dynamic> json) {
    return ArtistBankDetails(
      id: json['id']?.toString(),
      artistUserId: json['artist_user_id']?.toString() ?? '',
      paymentType: json['payment_type']?.toString() ?? 'UPI',
      upiId: json['upi_id']?.toString(),
      accountNumber: json['account_number']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      accountName: json['account_name']?.toString(),
      panNumber: json['pan_number']?.toString(),
      isVerified: json['is_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_type': paymentType,
    if (upiId != null) 'upi_id': upiId,
    if (accountNumber != null) 'account_number': accountNumber,
    if (ifscCode != null) 'ifsc_code': ifscCode,
    if (accountName != null) 'account_name': accountName,
    if (panNumber != null) 'pan_number': panNumber,
  };

  bool get isUpi => paymentType == 'UPI';
  bool get isBank => paymentType == 'BANK';
}

class PayoutRequest {
  final String id;
  final String artistUserId;
  final double amount;
  final String status; // PENDING, PROCESSING, COMPLETED, FAILED
  final String? razorpayPayoutId;
  final String? failureReason;
  final DateTime requestedAt;
  final DateTime? processedAt;

  const PayoutRequest({
    required this.id,
    required this.artistUserId,
    required this.amount,
    required this.status,
    this.razorpayPayoutId,
    this.failureReason,
    required this.requestedAt,
    this.processedAt,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) {
    return PayoutRequest(
      id: json['id']?.toString() ?? '',
      artistUserId: json['artist_user_id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      razorpayPayoutId: json['razorpay_payout_id']?.toString(),
      failureReason: json['failure_reason']?.toString(),
      requestedAt:
          DateTime.tryParse(json['requested_at']?.toString() ?? '') ??
          DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'])
          : null,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isProcessing => status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
}

class ArtistEarningsData {
  final ArtistWallet wallet;
  final List<MonthlyEarning> monthlyEarnings;
  final List<PayoutRequest> payoutRequests;

  const ArtistEarningsData({
    required this.wallet,
    required this.monthlyEarnings,
    required this.payoutRequests,
  });

  factory ArtistEarningsData.fromJson(Map<String, dynamic> json) {
    return ArtistEarningsData(
      wallet: json['wallet'] != null
          ? ArtistWallet.fromJson(json['wallet'])
          : const ArtistWallet(
              artistUserId: '',
              balance: 0,
              totalEarned: 0,
              totalPaidOut: 0,
            ),
      monthlyEarnings: (json['monthly_earnings'] as List<dynamic>? ?? [])
          .map((e) => MonthlyEarning.fromJson(e))
          .toList(),
      payoutRequests: (json['payout_requests'] as List<dynamic>? ?? [])
          .map((e) => PayoutRequest.fromJson(e))
          .toList(),
    );
  }
}

import 'package:equatable/equatable.dart';

class Subscription extends Equatable {
  final String id;
  final String userId;
  final String planName;
  final double amount;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? subscriptionId;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planName,
    required this.amount,
    required this.status,
    this.startDate,
    this.endDate,
    this.subscriptionId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      planName: json['plan'] ?? json['plan_name'] ?? 'Premium',
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
      status: json['status']?.toString().toUpperCase() ?? 'INACTIVE',
      startDate: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'])
          : (json['start_date'] != null
                ? DateTime.tryParse(json['start_date'])
                : null),
      endDate: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : (json['end_date'] != null
                ? DateTime.tryParse(json['end_date'])
                : null),
      subscriptionId: json['razorpay_payment_id'] ?? json['subscription_id'],
    );
  }

  bool get isActive =>
      (status == 'ACTIVE' || status == 'active') &&
      (endDate == null || endDate!.isAfter(DateTime.now()));

  @override
  List<Object?> get props => [
    id,
    userId,
    planName,
    amount,
    status,
    startDate,
    endDate,
    subscriptionId,
  ];
}

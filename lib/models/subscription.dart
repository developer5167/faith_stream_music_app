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
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      planName: json['plan_name'] ?? 'Premium',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'inactive',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      subscriptionId: json['subscription_id'],
    );
  }

  bool get isActive =>
      status == 'active' &&
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

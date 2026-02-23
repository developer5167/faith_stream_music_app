import 'package:equatable/equatable.dart';
import '../../models/payout.dart';

abstract class PayoutState extends Equatable {
  const PayoutState();
  @override
  List<Object?> get props => [];
}

class PayoutInitial extends PayoutState {
  const PayoutInitial();
}

class PayoutLoading extends PayoutState {
  const PayoutLoading();
}

class PayoutEarningsLoaded extends PayoutState {
  final ArtistEarningsData earnings;
  final ArtistBankDetails? bankDetails;

  const PayoutEarningsLoaded({required this.earnings, this.bankDetails});

  PayoutEarningsLoaded copyWith({
    ArtistEarningsData? earnings,
    ArtistBankDetails? bankDetails,
  }) => PayoutEarningsLoaded(
    earnings: earnings ?? this.earnings,
    bankDetails: bankDetails ?? this.bankDetails,
  );

  @override
  List<Object?> get props => [earnings, bankDetails];
}

class PayoutActionInProgress extends PayoutState {
  final PayoutEarningsLoaded? previousState;
  const PayoutActionInProgress({this.previousState});
}

class PayoutActionSuccess extends PayoutState {
  final String message;
  final PayoutEarningsLoaded updatedState;
  const PayoutActionSuccess({
    required this.message,
    required this.updatedState,
  });
  @override
  List<Object?> get props => [message, updatedState];
}

class PayoutError extends PayoutState {
  final String message;
  final PayoutEarningsLoaded? previousState;
  const PayoutError(this.message, {this.previousState});
  @override
  List<Object?> get props => [message];
}

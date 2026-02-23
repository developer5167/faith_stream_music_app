import 'package:equatable/equatable.dart';
import '../../models/payout.dart';

abstract class PayoutEvent extends Equatable {
  const PayoutEvent();
  @override
  List<Object?> get props => [];
}

class PayoutLoadEarnings extends PayoutEvent {
  const PayoutLoadEarnings();
}

class PayoutLoadBankDetails extends PayoutEvent {
  const PayoutLoadBankDetails();
}

class PayoutSaveBankDetails extends PayoutEvent {
  final ArtistBankDetails details;
  const PayoutSaveBankDetails(this.details);
  @override
  List<Object?> get props => [details];
}

class PayoutRequestWithdrawal extends PayoutEvent {
  final double amount;
  const PayoutRequestWithdrawal(this.amount);
  @override
  List<Object?> get props => [amount];
}

class PayoutRefresh extends PayoutEvent {
  const PayoutRefresh();
}

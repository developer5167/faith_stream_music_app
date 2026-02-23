import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/payout_service.dart';
import 'payout_event.dart';
import 'payout_state.dart';

class PayoutBloc extends Bloc<PayoutEvent, PayoutState> {
  final PayoutService _payoutService;

  PayoutBloc(this._payoutService) : super(const PayoutInitial()) {
    on<PayoutLoadEarnings>(_onLoadEarnings);
    on<PayoutLoadBankDetails>(_onLoadBankDetails);
    on<PayoutSaveBankDetails>(_onSaveBankDetails);
    on<PayoutRequestWithdrawal>(_onRequestWithdrawal);
    on<PayoutRefresh>(_onRefresh);
  }

  Future<void> _onLoadEarnings(
    PayoutLoadEarnings event,
    Emitter<PayoutState> emit,
  ) async {
    emit(const PayoutLoading());
    try {
      final results = await Future.wait([
        _payoutService.getEarnings(),
        _payoutService.getBankDetails(),
      ]);
      emit(
        PayoutEarningsLoaded(
          earnings: results[0] as dynamic,
          bankDetails: results[1] as dynamic,
        ),
      );
    } catch (e) {
      emit(PayoutError(e.toString()));
    }
  }

  Future<void> _onLoadBankDetails(
    PayoutLoadBankDetails event,
    Emitter<PayoutState> emit,
  ) async {
    final current = state is PayoutEarningsLoaded
        ? state as PayoutEarningsLoaded
        : null;
    try {
      final bankDetails = await _payoutService.getBankDetails();
      if (current != null) {
        emit(current.copyWith(bankDetails: bankDetails));
      }
    } catch (e) {
      emit(PayoutError(e.toString(), previousState: current));
    }
  }

  Future<void> _onSaveBankDetails(
    PayoutSaveBankDetails event,
    Emitter<PayoutState> emit,
  ) async {
    final current = state is PayoutEarningsLoaded
        ? state as PayoutEarningsLoaded
        : null;
    emit(PayoutActionInProgress(previousState: current));
    try {
      final saved = await _payoutService.saveBankDetails(event.details);
      final updatedState =
          current?.copyWith(bankDetails: saved) ??
          PayoutEarningsLoaded(
            earnings: await _payoutService.getEarnings(),
            bankDetails: saved,
          );
      emit(
        PayoutActionSuccess(
          message: 'Bank details saved successfully!',
          updatedState: updatedState,
        ),
      );
    } catch (e) {
      emit(PayoutError(e.toString(), previousState: current));
    }
  }

  Future<void> _onRequestWithdrawal(
    PayoutRequestWithdrawal event,
    Emitter<PayoutState> emit,
  ) async {
    final current = state is PayoutEarningsLoaded
        ? state as PayoutEarningsLoaded
        : null;
    emit(PayoutActionInProgress(previousState: current));
    try {
      await _payoutService.requestWithdrawal(event.amount);
      // Refresh earnings after withdrawal request
      final fresh = await _payoutService.getEarnings();
      final bankDetails = await _payoutService.getBankDetails();
      final updatedState = PayoutEarningsLoaded(
        earnings: fresh,
        bankDetails: bankDetails,
      );
      emit(
        PayoutActionSuccess(
          message:
              'Withdrawal request submitted! Admin will process it shortly.',
          updatedState: updatedState,
        ),
      );
    } catch (e) {
      emit(PayoutError(e.toString(), previousState: current));
    }
  }

  Future<void> _onRefresh(
    PayoutRefresh event,
    Emitter<PayoutState> emit,
  ) async {
    add(const PayoutLoadEarnings());
  }
}

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/home_feed.dart';
import '../../repositories/home_repository.dart';
import '../../repositories/stream_repository.dart';
import 'home_event.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final HomeFeed feed;

  const HomeLoaded(this.feed);

  @override
  List<Object?> get props => [feed];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;
  final StreamRepository _streamRepository;
  StreamSubscription? _streamSubscription;

  HomeBloc({
    required HomeRepository homeRepository,
    required StreamRepository streamRepository,
  }) : _homeRepository = homeRepository,
       _streamRepository = streamRepository,
       super(const HomeInitial()) {
    on<HomeLoadRequested>(_onHomeLoadRequested);
    on<HomeRefreshRequested>(_onHomeRefreshRequested);

    _streamSubscription = _streamRepository.onStreamLogged.listen((_) {
      add(const HomeRefreshRequested());
    });
  }

  Future<void> _onHomeLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      final response = await _homeRepository.getHomeFeed();

      if (response.success && response.data != null) {
        emit(HomeLoaded(response.data!));
      } else {
        emit(HomeError(response.message));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onHomeRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    // Keep current state while refreshing
    try {
      final response = await _homeRepository.getHomeFeed();

      if (response.success && response.data != null) {
        emit(HomeLoaded(response.data!));
      } else {
        emit(HomeError(response.message));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}

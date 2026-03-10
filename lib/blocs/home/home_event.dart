import 'package:equatable/equatable.dart';
import '../../models/home_feed.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

class HomeBootstrapLoaded extends HomeEvent {
  final HomeFeed feed;
  const HomeBootstrapLoaded(this.feed);

  @override
  List<Object> get props => [feed];
}

class HomeReset extends HomeEvent {
  const HomeReset();
}

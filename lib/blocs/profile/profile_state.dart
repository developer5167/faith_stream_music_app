import 'package:equatable/equatable.dart';
import '../../models/user.dart';
import '../../models/subscription.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;
  final Subscription? subscription;
  final Map<String, dynamic>? artistStatus;

  const ProfileLoaded({
    required this.user,
    this.subscription,
    this.artistStatus,
  });

  ProfileLoaded copyWith({
    User? user,
    Subscription? subscription,
    Map<String, dynamic>? artistStatus,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      subscription: subscription ?? this.subscription,
      artistStatus: artistStatus ?? this.artistStatus,
    );
  }

  @override
  List<Object?> get props => [user, subscription, artistStatus];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileOperationSuccess extends ProfileState {
  final String message;
  final ProfileLoaded previousState;

  const ProfileOperationSuccess({
    required this.message,
    required this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}

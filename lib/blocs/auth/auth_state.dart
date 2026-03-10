import 'package:equatable/equatable.dart';
import '../../models/user.dart';
import '../../models/bootstrap_response.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;
  // Optional because explicit sign-ins via /login don't return the full bootstrap layout,
  // only the cold-start app launch does.
  final BootstrapResponse? bootstrapData;

  const AuthAuthenticated({
    required this.user,
    required this.token,
    this.bootstrapData,
  });

  @override
  List<Object?> get props => [user, token, bootstrapData];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

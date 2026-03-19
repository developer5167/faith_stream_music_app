import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String verifiedEmailToken;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.verifiedEmailToken,
  });

  @override
  List<Object?> get props => [name, email, password, verifiedEmailToken];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthUserUpdated extends AuthEvent {
  const AuthUserUpdated();
}

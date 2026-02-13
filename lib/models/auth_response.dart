import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'user.dart';

class AuthResponse extends Equatable {
  final String token;
  final User user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("📦 AuthResponse.fromJson - Input: $json");
      print("📦 Token type: ${json['token'].runtimeType}");
      print("📦 User type: ${json['user'].runtimeType}");
    }

    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }

  @override
  List<Object?> get props => [token, user];
}

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import 'auth_event.dart';

import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final StorageService _storageService;
  final NotificationService _notificationService;

  AuthBloc({
    required AuthRepository authRepository,
    required StorageService storageService,
    required NotificationService notificationService,
  }) : _authRepository = authRepository,
       _storageService = storageService,
       _notificationService = notificationService,
       super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);

    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserUpdated>(_onAuthUserUpdated);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (kDebugMode) {
      print('🔐 Auth Check Started');
    }
    emit(const AuthLoading());

    try {
      final token = await _storageService.getToken();
      final user = _storageService.getUser();

      if (kDebugMode) {
        print('🔐 Token: ${token != null ? "Found" : "Not found"}');
      }
      if (kDebugMode) {
        print(
          '🔐 User: ${user != null ? "Found (${user.name})" : "Not found"}',
        );
      }

      if (token != null && user != null) {
        // Validate token by fetching user
        if (kDebugMode) {
          print('🔐 Validating token with /auth/me...');
        }
        final response = await _authRepository.getMe();

        if (kDebugMode) {
          print(
            '🔐 /auth/me response: success=${response.success}, data=${response.data != null}',
          );
        }

        if (response.success && response.data != null) {
          await _storageService.saveUser(response.data!);
          if (kDebugMode) {
            print('✅ Auth Authenticated - User: ${response.data!.name}');
          }
          emit(AuthAuthenticated(user: response.data!, token: token));

          // Try to register token when opening app and restoring session
          _notificationService.registerToken();
        } else {
          // Token invalid, clear storage
          if (kDebugMode) {
            print(
              '❌ Token invalid, clearing storage. Error: ${response.message}',
            );
          }
          await _storageService.clearAll();
          emit(const AuthUnauthenticated());
        }
      } else {
        if (kDebugMode) {
          print('❌ No token or user found - Unauthenticated');
        }
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Auth Check Error: $e');
      }
      await _storageService.clearAll();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (kDebugMode) {
      print('🔑 Login Started');
    }
    emit(const AuthLoading());

    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      if (kDebugMode) {
        print('🔑 Login Response: success=${response.success}');
      }

      if (response.success && response.data != null) {
        final authResponse = response.data!;
        if (kDebugMode) {
          print('🔑 Saving token and user...');
        }
        await _storageService.saveToken(authResponse.token);
        await _storageService.saveUser(authResponse.user);

        if (kDebugMode) {
          print('✅ Login Success - User: ${authResponse.user.name}');
        }
        if (kDebugMode) {
          print('✅ Token saved: ${authResponse.token.substring(0, 20)}...');
        }

        emit(
          AuthAuthenticated(user: authResponse.user, token: authResponse.token),
        );

        // Register new token with backend on explicit login
        _notificationService.registerToken();
      } else {
        if (kDebugMode) {
          print('❌ Login Failed: ${response.message}');
        }
        emit(AuthError(response.message));
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login Error: $e');
      }
      emit(AuthError(e.toString()));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );

      if (response.success && response.data != null) {
        final authResponse = response.data!;
        await _storageService.saveToken(authResponse.token);
        await _storageService.saveUser(authResponse.user);

        emit(
          AuthAuthenticated(user: authResponse.user, token: authResponse.token),
        );

        // Register token for new accounts
        _notificationService.registerToken();
      } else {
        emit(AuthError(response.message));
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.logout();
      await _storageService.clearAll();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        final response = await _authRepository.getMe();
        if (response.success && response.data != null) {
          await _storageService.saveUser(response.data!);
          emit(AuthAuthenticated(user: response.data!, token: token));
        }
      }
    } catch (e) {
      // Silent fail, keep current state
    }
  }
}

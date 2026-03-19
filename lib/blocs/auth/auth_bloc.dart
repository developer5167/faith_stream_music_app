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
      print('🔐 Auth Check Started (Bootstrap Mode)');
    }
    emit(const AuthLoading());

    try {
      final token = await _storageService.getToken();
      final localUser = _storageService.getUser();

      if (token != null && localUser != null) {
        // Validate token and fetch entire app bootstrap payload concurrently
        if (kDebugMode) {
          print('🔐 Validating token and fetching bootstrap payload...');
        }
        final response = await _authRepository.bootstrap();

        if (response.success && response.data != null) {
          final bootstrap = response.data!;
          // 1. Sync User Profile
          await _storageService.saveUser(bootstrap.user!);
          emit(AuthAuthenticated(user: bootstrap.user!, token: token));

          // 2. Pre-Populate Home Feed
          // We fire the event to the HomeBloc with the pre-assembled feed data
          // so the user does not experience a loading spinner on the home screen!
          // We will pass the data out of AuthBloc so the main provider can distribute it.
          // Note: The UI layer (Splash Screen) will be responsible for triggering HomeBloc,
          // but we will cache the bootstrap data inside AuthAuthenticated state soon.

          // Try to register token when opening app and restoring session
          _notificationService.registerToken();
        } else {
          // Instead of wiping the user out on network failure (500, timeout, offline)
          // we should trust the local token and user cache for immediate entry.
          // The API might just be down for 5 seconds.
          if (kDebugMode) {
            print(
              '⚠️ Bootstrap API failed / offline. Falling back to cached user model.',
            );
          }

          emit(AuthAuthenticated(user: localUser, token: token));
          _notificationService.registerToken();
        }
      } else {
        // Only completely unauthenticated if there is genuinely no cached data
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Auth Check Network Error: $e');
        print('⚠️ Yielding to cached profile data...');
      }

      // If the entire API call crashes, check if we have offline credentials
      final token = await _storageService.getToken();
      final localUser = _storageService.getUser();

      if (token != null && localUser != null) {
        emit(AuthAuthenticated(user: localUser, token: token));
      } else {
        await _storageService.clearAll();
        emit(const AuthUnauthenticated());
      }
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
        await _storageService.saveRefreshToken(authResponse.refreshToken);
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
        verifiedEmailToken: event.verifiedEmailToken,
      );

      if (response.success && response.data != null) {
        final authResponse = response.data!;
        await _storageService.saveToken(authResponse.token);
        await _storageService.saveRefreshToken(authResponse.refreshToken);
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

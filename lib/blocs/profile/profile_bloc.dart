import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/user_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository _userRepository;

  ProfileBloc(this._userRepository) : super(ProfileInitial()) {
    on<ProfileLoad>(_onLoad);
    on<ProfileUpdate>(_onUpdate);
    on<ProfileRequestArtist>(_onRequestArtist);
    on<ProfileCheckArtistStatus>(_onCheckArtistStatus);
    on<ProfileLoadSubscription>(_onLoadSubscription);
    on<ProfileCreateSubscription>(_onCreateSubscription);
    on<ProfileReset>((event, emit) => emit(ProfileInitial()));
  }

  Future<void> _onLoad(ProfileLoad event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());

    try {
      final profileResponse = await _userRepository.getProfile();

      if (profileResponse.success && profileResponse.data != null) {
        // Load subscription status
        final subResponse = await _userRepository.getSubscriptionStatus();

        // Load artist status + dashboard stats if artist
        Map<String, dynamic>? artistStatus;
        if (profileResponse.data!.artistStatus != null) {
          final results = await Future.wait([
            _userRepository.getArtistStatus(),
            _userRepository.getArtistDashboardStats(),
          ]);

          final statusResp = results[0];
          final statsResp = results[1];

          if (statusResp.success) {
            artistStatus = Map<String, dynamic>.from(
              statusResp.data as Map<String, dynamic>,
            );
            // Merge stats into the same map
            if (statsResp.success && statsResp.data != null) {
              artistStatus.addAll(statsResp.data!);
            }
          }
        }

        emit(
          ProfileLoaded(
            user: profileResponse.data!,
            subscription: subResponse.data,
            artistStatus: artistStatus,
          ),
        );
      } else {
        emit(ProfileError(profileResponse.message));
      }
    } catch (e) {
      emit(ProfileError('Failed to load profile: $e'));
    }
  }

  Future<void> _onUpdate(
    ProfileUpdate event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    try {
      final response = await _userRepository.updateProfile(
        name: event.name,
        phone: event.phone,
        bio: event.bio,
        profilePicUrl: event.profilePicUrl,
      );

      if (response.success && response.data != null) {
        emit(currentState.copyWith(user: response.data));

        // Show success message
        emit(
          ProfileOperationSuccess(
            message: response.message,
            previousState: currentState.copyWith(user: response.data),
          ),
        );
      } else {
        emit(ProfileError(response.message));
      }
    } catch (e) {
      emit(ProfileError('Failed to update profile: $e'));
    }
  }

  Future<void> _onRequestArtist(
    ProfileRequestArtist event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    try {
      final response = await _userRepository.requestArtist(
        artistName: event.artistName,
        bio: event.bio,
        govtIdUrl: event.govtIdUrl,
        addressProofUrl: event.addressProofUrl,
        selfieVideoUrl: event.selfieVideoUrl,
        supportingLinks: event.supportingLinks,
      );

      if (response.success) {
        // Reload profile to get updated artist status
        add(ProfileLoad());

        emit(
          ProfileOperationSuccess(
            message: response.message,
            previousState: currentState,
          ),
        );
      } else {
        emit(ProfileError(response.message));
      }
    } catch (e) {
      emit(ProfileError('Failed to request artist status: $e'));
    }
  }

  Future<void> _onCheckArtistStatus(
    ProfileCheckArtistStatus event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    try {
      final results = await Future.wait([
        _userRepository.getArtistStatus(),
        _userRepository.getArtistDashboardStats(),
      ]);

      final statusResp = results[0];
      final statsResp = results[1];

      if (statusResp.success && statusResp.data != null) {
        final merged = Map<String, dynamic>.from(
          statusResp.data as Map<String, dynamic>,
        );
        if (statsResp.success && statsResp.data != null) {
          merged.addAll(statsResp.data!);
        }
        emit(currentState.copyWith(artistStatus: merged));
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onLoadSubscription(
    ProfileLoadSubscription event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    try {
      final response = await _userRepository.getSubscriptionStatus();

      if (response.success) {
        emit(currentState.copyWith(subscription: response.data));
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onCreateSubscription(
    ProfileCreateSubscription event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;

    try {
      final response = await _userRepository.createSubscription();

      if (response.success) {
        emit(
          ProfileOperationSuccess(
            message: 'Subscription created successfully',
            previousState: currentState,
          ),
        );

        // Reload subscription
        add(ProfileLoadSubscription());
      } else {
        emit(ProfileError(response.message));
      }
    } catch (e) {
      emit(ProfileError('Failed to create subscription: $e'));
    }
  }
}

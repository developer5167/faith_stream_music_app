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
  }

  Future<void> _onLoad(ProfileLoad event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());

    try {
      final profileResponse = await _userRepository.getProfile();

      if (profileResponse.success && profileResponse.data != null) {
        // Load subscription status
        final subResponse = await _userRepository.getSubscriptionStatus();

        // Load artist status if applicable
        Map<String, dynamic>? artistStatus;
        if (profileResponse.data!.artistStatus != null) {
          final artistResponse = await _userRepository.getArtistStatus();
          if (artistResponse.success) {
            artistStatus = artistResponse.data;
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
      final response = await _userRepository.getArtistStatus();

      if (response.success && response.data != null) {
        emit(currentState.copyWith(artistStatus: response.data));
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

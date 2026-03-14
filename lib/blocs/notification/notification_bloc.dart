import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/notification.dart';
import '../../repositories/notification_repository.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object> get props => [];
}

class NotificationLoad extends NotificationEvent {
  final bool refresh;
  const NotificationLoad({this.refresh = false});
  @override
  List<Object> get props => [refresh];
}

class NotificationLoadMore extends NotificationEvent {}

class NotificationMarkAsRead extends NotificationEvent {
  final String id;
  const NotificationMarkAsRead(this.id);
  @override
  List<Object> get props => [id];
}

class NotificationMarkAllAsRead extends NotificationEvent {}

// State
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int totalCount;
  final int currentPage;
  final bool hasMore;

  const NotificationLoaded({
    required this.notifications,
    required this.totalCount,
    required this.currentPage,
    required this.hasMore,
  });

  @override
  List<Object> get props => [notifications, totalCount, currentPage, hasMore];

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  final int _limit = 20;

  NotificationBloc(this._repository) : super(NotificationInitial()) {
    on<NotificationLoad>(_onLoad);
    on<NotificationLoadMore>(_onLoadMore);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
  }

  Future<void> _onLoad(NotificationLoad event, Emitter<NotificationState> emit) async {
    if (event.refresh) {
      emit(NotificationLoading());
    } else if (state is NotificationInitial) {
      emit(NotificationLoading());
    }

    try {
      final result = await _repository.getNotifications(page: 1, limit: _limit);
      final List<NotificationModel> notifications = result['notifications'];
      final int total = result['total'];
      
      emit(NotificationLoaded(
        notifications: notifications,
        totalCount: total,
        currentPage: 1,
        hasMore: notifications.length < total,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onLoadMore(NotificationLoadMore event, Emitter<NotificationState> emit) async {
    if (state is! NotificationLoaded) return;
    final currentState = state as NotificationLoaded;
    if (!currentState.hasMore) return;

    try {
      final nextPage = currentState.currentPage + 1;
      final result = await _repository.getNotifications(page: nextPage, limit: _limit);
      final List<NotificationModel> newNotifications = result['notifications'];
      final int total = result['total'];
      
      emit(NotificationLoaded(
        notifications: [...currentState.notifications, ...newNotifications],
        totalCount: total,
        currentPage: nextPage,
        hasMore: (currentState.notifications.length + newNotifications.length) < total,
      ));
    } catch (e) {
      // Keep existing data on error
    }
  }

  Future<void> _onMarkAsRead(NotificationMarkAsRead event, Emitter<NotificationState> emit) async {
    if (state is! NotificationLoaded) return;
    final currentState = state as NotificationLoaded;

    try {
      final success = await _repository.markAsRead(event.id);
      if (success) {
        final updatedNotifications = currentState.notifications.map((n) {
          if (n.id == event.id) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        
        emit(currentState.copyWith(notifications: updatedNotifications));
      }
    } catch (_) {}
  }

  Future<void> _onMarkAllAsRead(NotificationMarkAllAsRead event, Emitter<NotificationState> emit) async {
    if (state is! NotificationLoaded) return;
    final currentState = state as NotificationLoaded;

    try {
      final success = await _repository.markAllAsRead();
      if (success) {
        final updatedNotifications = currentState.notifications.map((n) {
          return n.copyWith(isRead: true);
        }).toList();
        
        emit(currentState.copyWith(notifications: updatedNotifications));
      }
    } catch (_) {}
  }
}

import 'package:equatable/equatable.dart';
import 'package:hai_app/features/notification/data/model/notification_model.dart';


abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object> get props => [];
}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  final int timestamp; 

  const NotificationsLoaded(this.notifications, this.timestamp);

  @override
  List<Object> get props => [notifications, timestamp];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);

  @override
  List<Object> get props => [message];
}
import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final int id;
  final String text;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.text,
    required this.isRead,
  });

  // This method allows us to update a specific field while keeping the rest the same
  NotificationModel copyWith({
    int? id,
    String? text,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, text, isRead];
}
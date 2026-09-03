// lib/features/chat/presentation/cubit/chat_state.dart

import 'package:equatable/equatable.dart';
import 'package:hai_app/features/chat/data/model/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final int timestamp;

  const ChatLoaded(this.messages, this.timestamp);

  @override
  List<Object> get props => [messages, timestamp];
}

class ChatTyping extends ChatState {
  final List<ChatMessage> messages;
  final int timestamp;

  const ChatTyping(this.messages, this.timestamp);

  @override
  List<Object> get props => [messages, timestamp];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}
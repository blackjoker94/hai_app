import 'package:flutter_test/flutter_test.dart';
import 'package:hai_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:hai_app/features/chat/presentation/cubit/chat_state.dart';

void main() {
  group('ChatCubit', () {
    test('initial state is ChatLoading', () {
      final cubit = ChatCubit();
      expect(cubit.state, isA<ChatLoading>());
      cubit.close();
    });

    test('loadChat emits ChatLoaded with initial welcome message', () async {
      final cubit = ChatCubit();
      await cubit.loadChat();
      expect(cubit.state, isA<ChatLoaded>());
      final state = cubit.state as ChatLoaded;
      expect(state.messages.length, 1);
      expect(state.messages.first.isUser, isFalse);
      expect(state.messages.first.text, contains('مرحبًا بحضرتك'));
      cubit.close();
    });

    test('strips think tags from response text if present', () {
      final rawResponse = '<think>\nHere is reasoning\n</think>\nمرحبًا بيك يا فندم';
      final cleaned = rawResponse.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
      expect(cleaned, 'مرحبًا بيك يا فندم');
    });
  });
}

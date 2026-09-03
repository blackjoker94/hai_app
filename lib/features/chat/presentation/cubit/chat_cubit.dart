import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:hai_app/features/chat/data/model/chat_message.dart';
import 'package:hai_app/features/chat/presentation/cubit/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final String _apiKey =
      dotenv.isInitialized ? (dotenv.env['GROQ_API_KEY'] ?? '') : '';

  static const _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _defaultModel = 'openai/gpt-oss-120b';
  late final String _model = dotenv.isInitialized
      ? (dotenv.env['GROQ_MODEL'] ?? _defaultModel)
      : _defaultModel;

  static const _systemPrompt =
      'أنت مساعد ذكي "حي" متخصص في نظام البلاغات الذكية للمشاكل المجتمعية في مصر. '
      'تخصصك هو: القمامة، الفيضانات، وتلف الطرق. '
      'تحدث باللغة العربية العامية المصرية فقط. '
      'ردودك قصيرة، ودودة، ومفيدة ولا تتجاوز ٣ جمل. '
      'إذا سأل المستخدم عن موضوع خارج نطاق البلاغات، أعده بلطف للموضوع الأساسي.';

  final List<Map<String, String>> _conversationHistory = [
    {'role': 'system', 'content': _systemPrompt},
  ];

  final List<ChatMessage> _messages = [];

  ChatCubit() : super(const ChatLoading());

  Future<void> loadChat({String? reportLabel}) async {
    emit(const ChatLoading());
    await Future.delayed(const Duration(milliseconds: 400));

    _messages.clear();
    _conversationHistory.removeWhere((m) => m['role'] != 'system');

    //first message in the chat
    _messages.add(const ChatMessage(
      text: '👋 مرحبًا بحضرتك في نظام البلاغات الذكي.\n\n'
          'يسعدني أكون المساعد الخاص بيك، واللي هيساعدك خطوة بخطوة '
          'لتسجيل أي بلاغ أو ملاحظة بشكل سريع وسهل.',
      isUser: false,
      time: 'now',
    ));

    emit(ChatLoaded(
        List.from(_messages), DateTime.now().millisecondsSinceEpoch));

    if (reportLabel != null && reportLabel.isNotEmpty) {
      emit(ChatTyping(
          List.from(_messages), DateTime.now().millisecondsSinceEpoch));

      try {
        final contextPrompt =
            'المستخدم للتو أرسل بلاغ عن مشكلة "$reportLabel" وتم استلامه بنجاح. '
            'اكتب رسالة قصيرة تطمئنه إن البلاغ وصل للجهات المختصة وهيتم النظر فيه، '
            'واسأله إذا كان محتاج مساعدة تانية بخصوص نفس الموضوع. '
            'الرد يكون بالعامية المصرية ومش أكتر من ٣ جمل.';

        _conversationHistory
            .add({'role': 'user', 'content': contextPrompt});

        final reply = await _callGroq();

        _conversationHistory
            .add({'role': 'assistant', 'content': reply});

        _messages
            .add(ChatMessage(text: reply, isUser: false, time: _now()));
      } catch (e) {
        _messages.add(ChatMessage(
          text: 'تم استلام بلاغك عن "$reportLabel" بنجاح ✅\n'
              'هيتم النظر فيه من الجهات المختصة في أقرب وقت.\n'
              'في حاجة تانية أقدر أساعدك بيها؟',
          isUser: false,
          time: _now(),
        ));
      }

      emit(ChatLoaded(
          List.from(_messages), DateTime.now().millisecondsSinceEpoch));
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(text: text.trim(), isUser: true, time: _now()));
    _conversationHistory.add({'role': 'user', 'content': text.trim()});
    emit(ChatTyping(
        List.from(_messages), DateTime.now().millisecondsSinceEpoch));

    try {
      final reply = await _callGroq();
      _conversationHistory.add({'role': 'assistant', 'content': reply});
      _messages.add(ChatMessage(text: reply, isUser: false, time: _now()));
      emit(ChatLoaded(
          List.from(_messages), DateTime.now().millisecondsSinceEpoch));
    } catch (e) {
      debugPrint("🔴 Groq Error: $e");
      _messages.add(const ChatMessage(
        text: 'عذرًا، في مشكلة في الاتصال. حاول تاني بعد شوية.',
        isUser: false,
        time: 'now',
      ));
      emit(ChatLoaded(
          List.from(_messages), DateTime.now().millisecondsSinceEpoch));
    }
  }

  Future<String> _callGroq() async {
    final response = await http.post(
      Uri.parse(_groqEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': _conversationHistory,
        'max_tokens': 300,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      String content =
          data['choices'][0]['message']['content'].toString().trim();
      content =
          content.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
      return content;
    } else {
      debugPrint("🔴 Groq HTTP ${response.statusCode}: ${response.body}");
      throw Exception('Groq API error ${response.statusCode}');
    }
  }

  String _now() {
    final t = DateTime.now();
    return '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
  }
}
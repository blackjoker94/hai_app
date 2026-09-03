// lib/features/chat/presentation/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_text_styles.dart';
import 'package:hai_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:hai_app/features/chat/presentation/cubit/chat_state.dart';

class ChatScreen extends StatefulWidget {
  final String? reportLabel;
  const ChatScreen({super.key, this.reportLabel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit()..loadChat(reportLabel: widget.reportLabel),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("المساعد الذكي", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatCubit, ChatState>(
                listener: (context, state) {
                  if (state is ChatLoaded || state is ChatTyping) {
                    _scrollToBottom();
                  }
                },
                builder: (context, state) {
                  final messages = switch (state) {
                    ChatLoaded s => s.messages,
                    ChatTyping s => s.messages,
                    _ => [],
                  };

                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: messages.length + (state is ChatTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state is ChatTyping && index == messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("يكتب الآن...", style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      final msg = messages[index];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Text(
                            msg.text,
                            style: AppTextStyles.x2(
                              color: msg.isUser ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            Builder(
              builder: (context) {
                final isTyping = context.watch<ChatCubit>().state is ChatTyping;
                return Container(
                  padding: EdgeInsets.all(16.w),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !isTyping,
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالتك...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.r),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 10.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          icon: isTyping 
                             ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                             : const Icon(Icons.send, color: Colors.white),
                          onPressed: isTyping
                              ? null
                              : () {
                                  final text = _messageController.text;
                                  if (text.isNotEmpty) {
                                    context.read<ChatCubit>().sendMessage(text);
                                    _messageController.clear();
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}
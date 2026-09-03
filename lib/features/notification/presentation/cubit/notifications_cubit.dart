import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hai_app/features/notification/data/model/notification_model.dart';

import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsLoading()) {
    loadNotifications();
  }

  List<NotificationModel> _notifications = [];

  void loadNotifications() async {
    emit(NotificationsLoading());
    await Future.delayed(const Duration(milliseconds: 500));

    // Hardcoded data mapped to the Model
    _notifications = [
      const NotificationModel(
        id: 1,
        text: "مبروك🥳 تم معالجة مشكله البلاعه بدون غطاء الذي قمت لانشاءه يوم 01/10/2025",
        isRead: false,
      ),
      const NotificationModel(
        id: 2,
        text: "شكوي رقم: 233453\nتم ارسال مشكلتك الان و سيتم مراجعتها من خلال الجهه المختصه",
        isRead: false,
      ),
      const NotificationModel(
        id: 3,
        text: "شكوي رقم: 233453\nتم التحقق من مشكلتك سوف ترسل الي الجهه المختصه",
        isRead: true, 
      ),
      const NotificationModel(
        id: 4,
        text: "شكوي رقم: 233453\nيتم الان اصلاح مشكلتك و سوف نخبرك عندما ينتهي عمالنا",
        isRead: false,
      ),
      const NotificationModel(
        id: 5,
        text: "ازيك يا بطل حي بيفكرك ان فاضلك 3 نقط و تبقي كبير المساعدين متفوتهاش",
        isRead: true,
      ),
      const NotificationModel(
        id: 6,
        text: "شكوي رقم: 233453\nتم رفض طلب المشكله\nالسبب: عدم الجيه او لعدم اهميتها",
        isRead: false,
      ),
    ];

    _emitLoaded();
  }

  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _emitLoaded();
  }

  void markItemAsRead(int notificationId) {
    _notifications = _notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    
    _emitLoaded();
  }

  void _emitLoaded() {
    emit(NotificationsLoaded(
      List.from(_notifications), 
      DateTime.now().millisecondsSinceEpoch,
    ));
  }
}
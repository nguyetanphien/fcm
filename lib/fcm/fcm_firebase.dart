import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'local_notification_service.dart';



class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initForegroundNotification() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<RemoteMessage?> getMessage() async {
    return _firebaseMessaging.getInitialMessage();
  }

  Future<void> init() async {
    final NotificationSettings settings =
        await _firebaseMessaging.requestPermission(
      announcement: true,
      carPlay: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('Firebase User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log('Firebase User granted provisional permission');
    } else {
      log('Firebase User declined or has not accepted permission');
    }

    await _firebaseMessaging.setAutoInitEnabled(true);

    // _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
    //   if (message != null) {
    //     Get.log('getInitialMessage data: ${message.data}');
    //     Get.log('getInitialMessage notification: ${message.notification}');
    //     onOpenNotification(message);
    //   }
    // });

    /// Xử lý message khi nhận thông báo ở forgground
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      debugPrint("onMessage: $message");
      log('Message data: ${message?.data}');
      log('Message notification: ${message?.notification}');
      final RemoteNotification? notification = message?.notification;

      // if (Get.isRegistered<DashBoardHomeController>()) {
      //   final dashBoardController = Get.find<DashBoardHomeController>();
      //   dashBoardController.onGetDataNotification();
      // }

      // if (Get.isRegistered<DashBoardController>()) {
      //   Get.find<DashBoardController>().checkNotification();
      //   Get.find<DashBoardController>().checkNotificationSystem();
      //   Get.find<DashboardNotifyController>().initNoti(isRefresh: true);
      // }
      
      // if (Get.isRegistered<DashBoardController>()) {
        
      // }

      if (notification != null && Platform.isAndroid) {
        final Map<String, dynamic> data = message?.data ?? {};
        // data[NOTIFICATION_KEY] = notification.hashCode.toString();
        // data[NOTIFICATION_TITLE] = notification.title;
       log('data to send: $data');
        LocalNotificationService().showNotification(
          notification.hashCode,
          notification.title??'',
          notification.body??'',
          // parse(notification.title?.tr??'').body?.text ?? '',
          // parse(notification.body?.tr??'').body?.text ?? '',
          'high_importance_channel',
         " EndPoints.notification_channel", // title/notification_channel
          'This channel is used for important notifications.',
        );

        // Show local notification.
      }
    });

    /// Xử lý message khi nhân vào thông báo.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // print('A new onMessageOpenedApp event was published!');
      debugPrint("onMessageOpenedApp: data ${message.data}");
      debugPrint("onMessageOpenedApp: notification ${message.notification}");

      onOpenNotification(message);
    });
  }

  // Yêu cầu cấp quyền
  Future<void> requestPermission() async {
    final requestPermisson = await _firebaseMessaging.getNotificationSettings();
    if (requestPermisson.authorizationStatus == AuthorizationStatus.denied ||
        requestPermisson.authorizationStatus ==
            AuthorizationStatus.notDetermined ||
        requestPermisson.authorizationStatus ==
            AuthorizationStatus.provisional) {
      await _firebaseMessaging.requestPermission(
        announcement: true,
        carPlay: true,
      );
    }
  }

  /// Top function / static function xử lý khi nhận thông báo backdround
  static Future<dynamic> backgroundMessageHandler(RemoteMessage message) async {
    debugPrint("onBackgroundMessage data: ${message.data}");
    debugPrint("onBackgroundMessage notification: ${message.notification}");
    // if (Get.isRegistered<DashBoardController>()) {
    //   Get.find<DashBoardController>().checkNotification();
    //   Get.find<DashboardNotifyController>().initNoti(isRefresh: true);
      
    // }
    // if (Get.isRegistered<DashBoardController>()) {
    //   Get.find<DashBoardController>().checkNotificationSystem();
    //   Get.find<DashboardNotifyController>().initNoti(isRefresh: true);
    // }
    // LocalNotificationService().showNotification(
    //   Random().nextInt(1000),
    //   message.notification?.title ?? '',
    //   message.notification?.body ?? '',
    //   notificationChannelId,
    //   "DPFOOD",
    //   "",
    // );
  }

  /// Open notification
  Future<void> onOpenNotification(RemoteMessage message,
      {bool isAppClosed = false}) async {
    // if (!IZIValidate.nullOrEmpty(sl<SharedPreferenceHelper>().getIdUser)) {
    //   if (Get.isRegistered<DashBoardController>()) {
    //     Get.find<DashBoardController>()
    //         .handleUpdateCurrentTab(DashBoardTabEnum.Notify);
    //   }
    // }
    debugPrint('onOpenNotification ${message.data}');
  }

  Future<void> backgroundHandler() async {
    // await Firebase.initializeApp();

    /// Goi khi nhận thông báo background
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
  }

  Future<void> subscribeTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeTopic(String topic) async {
    // ignore: deprecated_member_use
    final bool isReset = await deleteInstanceID();
    if (!isReset) {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    }
  }

  Future<bool> deleteInstanceID() async {
    try {
      await _firebaseMessaging.deleteToken();
      return true;
    } catch (e) {
      return false;
    }
  }
}

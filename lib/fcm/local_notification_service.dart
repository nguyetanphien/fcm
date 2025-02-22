import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';

// ignore: depend_on_referenced_packages

class LocalNotificationService {
  LocalNotificationService() {
    flutterLocalNotificationsPlugin ??= FlutterLocalNotificationsPlugin();
    didReceiveLocalNotificationSubject ??= BehaviorSubject<ReceivedNotification>();
    selectNotificationSubject ??= BehaviorSubject<String>();
  }

  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  // Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
  static BehaviorSubject<ReceivedNotification>?
      // ignore: close_sinks
      didReceiveLocalNotificationSubject;

  // ignore: close_sinks
  static BehaviorSubject<String>? selectNotificationSubject = BehaviorSubject<String>();

  NotificationAppLaunchDetails? notificationAppLaunchDetails;

  Future<void> init() async {
    notificationAppLaunchDetails =
        !kIsWeb && Platform.isLinux ? null : await flutterLocalNotificationsPlugin?.getNotificationAppLaunchDetails();

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Note: permissions aren't requested here just to demonstrate that can be done later using the `requestPermissions()` method
    // of the `IOSFlutterLocalNotificationsPlugin` class
    final initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: (int? id, String? title, String? body, String? payload) async {
      didReceiveLocalNotificationSubject!.add(ReceivedNotification(id: id, title: title, body: body, payload: payload));
    });
    const MacOSInitializationSettings initializationSettingsMacOS = MacOSInitializationSettings();
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
    );
    flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          "",
          "EndPoints.notification_channel",
          description: '',
          importance: Importance.high,
        ));
    await flutterLocalNotificationsPlugin!.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      if (payload != null) {

        // Đẩy sự kiện
        selectNotificationSubject!.sink.add(payload);
      }
    });
  }

  ///
  /// Yêu cầu quyền
  ///
  Future<bool?>? requestIOSPermissions() async {
    final result = await flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result;
  }

  ///
  /// Đăng ký lắng nghe sự kiến cho notificationSubject
  ///
  void configureDidReceiveLocalNotificationSubject(BuildContext context) {
    didReceiveLocalNotificationSubject!.stream.listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null ? Text(receivedNotification.title ?? '') : null,
          content: receivedNotification.body != null ? Text(receivedNotification.body ?? '') : null,
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Ok'),
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                // await Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => ListenNotification(receivedNotification.payload ?? ''),
                //   ),
                // );
              },
            )
          ],
        ),
      );
    });
  }

  ///
  /// Đăng ký lăng nghe sự kiện cho selectNotificationSubject khi click thông báo
  ///
  void configureSelectNotificationSubject(BuildContext context, Function callback) {
    // Lăng nghe sự kiện
    selectNotificationSubject!.stream.listen((String payload) {
      log('selectNotificationSubject: $payload');
      //      await Navigator.push(
      //        context,
      //        MaterialPageRoute(builder: (context) => Home(payload: payload)),
      //      );
    });
  }

  ///
  ///
  ///
  Future getNotificationAppLaunchDetail() async {
    notificationAppLaunchDetails = await flutterLocalNotificationsPlugin!.getNotificationAppLaunchDetails();
    final String payload = notificationAppLaunchDetails?.payload ?? '{}';
    log('getNotificationAppLaunchDetail: $payload');
  }

  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    return flutterLocalNotificationsPlugin!.getNotificationAppLaunchDetails();
  }

  ///
  /// Dispose
  ///
  void dispose() {
    if (didReceiveLocalNotificationSubject != null) {
      didReceiveLocalNotificationSubject!.close();
    }
    if (selectNotificationSubject != null) {
      selectNotificationSubject!.close();
    }
  }

  Future<void> showNotification(
    int id,
    String title,
    String body,
    String androidChannelId,
    String androidChannelName,
    String androidChannelDescription, {
    String? payload,
    String? ticker,
    bool playSound = true,
    Importance importance = Importance.max,
    Priority priority = Priority.high,
  }) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription: androidChannelDescription,
      importance: importance,
      priority: priority,
      ticker: ticker,
    );
    const iOSPlatformChannelSpecifics = IOSNotificationDetails();
    final platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin!.show(id, title, body, platformChannelSpecifics, payload: payload);
  }

  /// Schedules a notification that specifies a different icon, sound and vibration pattern
  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    String androidChannelId,
    String androidChannelName,
    String androidChannelDescription, {
    int ledOnMs = 1000,
    int ledOffMs = 500,
    String? payload,
    String? icon,
    bool? enableLights,
    bool enableVibration = true,
    bool? channelShowBadge,
    bool? playSound,
    AndroidNotificationSound? sound,
    Int64List? vibrationPattern,
    Color? color,
    Color? ledColor,
  }) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(androidChannelId, androidChannelName,
        channelDescription: androidChannelDescription,
        vibrationPattern: vibrationPattern,
        enableLights: enableLights!,
        enableVibration: enableVibration,
        icon: icon,
        playSound: playSound!,
        channelShowBadge: channelShowBadge!,
        color: color,
        ledColor: ledColor,
        ledOnMs: ledOnMs,
        ledOffMs: ledOffMs);
    const iOSPlatformChannelSpecifics = IOSNotificationDetails(sound: 'chuong.wav');
    final platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    // ignore: deprecated_member_use
    await flutterLocalNotificationsPlugin!
        .schedule(id, title, body, scheduledDate, platformChannelSpecifics, payload: payload);
  }

  Future<void> repeatNotification(int id, String title, String body, RepeatInterval repeatInterval,
      String androidChannelId, String androidChannelName, String androidChannelDescription,
      {String? payload}) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription: androidChannelDescription,
    );
    const iOSPlatformChannelSpecifics = IOSNotificationDetails();
    final platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin!
        .periodicallyShow(id, title, body, repeatInterval, platformChannelSpecifics, payload: payload);
  }

  Future<void> checkPendingNotificationRequests(BuildContext context) async {
    final pendingNotificationRequests = await flutterLocalNotificationsPlugin!.pendingNotificationRequests();
    for (final pendingNotificationRequest in pendingNotificationRequests) {
      debugPrint(
          'pending notification: [id: ${pendingNotificationRequest.id}, title: ${pendingNotificationRequest.title}, body: ${pendingNotificationRequest.body}, payload: ${pendingNotificationRequest.payload}]');
    }
    // ignore: use_build_context_synchronously
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('${pendingNotificationRequests.length} pending notification requests'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin!.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin!.cancelAll();
  }

  Future<void> onDidReceiveLocalNotification(
      BuildContext context, int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    await showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: title != null ? Text(title) : null,
        content: body != null ? Text(body) : null,
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              // await Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => ListenNotification(payload ?? ''),
              //   ),
              // );
            },
          )
        ],
      ),
    );
  }
}

class ReceivedNotification {
  final int? id;
  final String? title;
  final String? body;
  final String? payload;

  ReceivedNotification({
    this.id,
    this.title,
    this.body,
    this.payload,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  const darwinSettings = DarwinInitializationSettings();

  const initializationSettings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  await requestNotificationPermissions();

  runApp(const MyApp());
}

Future<void> requestNotificationPermissions() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}

Future<void> showSimpleNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'basic_channel',
    'Basic Notifications',
    channelDescription: 'Basic noti channel',
    importance: Importance.max,
    priority: Priority.high,
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: 'GDGoC 알림',
    body: '알림이 도착했습니다!.',
    payload: 'payload',
    notificationDetails: notificationDetails,
  );
}

Future<void> scheduleNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'schedule_channel',
    'Scheduled Notifications',
    channelDescription: 'Scheduled noti channel',
    importance: Importance.max,
    priority: Priority.high,
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id: 1,
    title: 'GDGoC 예약 알림',
    body: '5초 뒤에 도착한 알림입니다.',
    payload: 'payload',
    scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
    notificationDetails: notificationDetails,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Demo',
      home: const NotificationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('9주차 세션')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: showSimpleNotification,
              child: const Text('즉시 알림 보내기'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: scheduleNotification,
              child: const Text('5초 뒤 알림 보내기'),
            ),
          ],
        ),
      ),
    );
  }
}

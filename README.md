### App Session 9주차
> 담당 Core: 임도협

![GDGoC Header](https://github.com/user-attachments/assets/dfe27e31-d863-40ff-81f0-051b1742bdc0)

## 이번 주에는

- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)를 사용해 push notification 구현하기
- 플랫폼별 알림 권한 설정하기
- 알림 초기화하기
- 즉시 알림 구현하기
- 예약 알림 구현하기

<br />

## Step 1

#### 1. 프로젝트 생성 및 실행

```bash
flutter create --empty noti
code .
```

> VSCode에서 `lib/main.dart`를 열고, 화면 하단 상태바에서 사용할 디바이스(시뮬레이터)를 선택한 후, 창 상단 Start Debugging을 눌러 앱을 실행합니다.

<img width="2056" height="1245" alt="image" src="https://github.com/user-attachments/assets/a6c74c42-4b24-4d53-8db7-df5f4355ba17" />

#### 2. 패키지 설치

다음 패키지를 설치합니다.

```yaml
flutter_local_notifications: ^21.0.0
timezone: ^0.11.0
```

> VSCode에서 `cmd+shift+p` 키를 누르고, `Dart: Add Dependency`를 입력한 후 enter <br />
> 
> <img width="1270" height="598" alt="image" src="https://github.com/user-attachments/assets/1c52b858-74f1-4fd9-8f26-89d28600fbba" />
>
> `flutter_local_notifications`를 입력한 후 enter <br />
> 
> <img width="1275" height="649" alt="image" src="https://github.com/user-attachments/assets/b336dd43-5511-4ef1-9b87-489806e36ebc" />
>
> `timezone`을 입력한 후 enter <br />
> 
> <img width="1276" height="693" alt="image" src="https://github.com/user-attachments/assets/4ef043fe-18eb-4111-8629-49e6a451c002" />
>
> `pubspec.yaml`에 설치된 모습 <br />
> 
> <img width="1269" height="672" alt="image" src="https://github.com/user-attachments/assets/f95c986c-c7ed-4c1c-84a2-358c92f744eb" />


## Step 2

#### 3. 앱 알림 권한 설정

푸쉬 알림을 사용하려면 플랫폼별 권한 설정이 필요한데요,
특히 iOS는 반드시 권한 요청 코드가 필요하고, Android도 최신 버전에서는 알림 권한을 명시해야 합니다!

##### Android 설정

`android/app/src/main/AndroidManifest.xml`파일에 아래 권한을 추가합니다.

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

그리고 `<application ...>` 태그 내부에 다음 receiver도 추가합니다.

```xml
<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />

<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

<img width="1586" height="764" alt="image" src="https://github.com/user-attachments/assets/60fc9eef-b123-4982-8b59-d672029490fc" />



##### iOS 설정

`ios/Runner/Info.plist`에 아래 내용을 추가합니다.

<key>NSUserNotificationUsageDescription</key>
<string>푸쉬 알림을 수신하기 위해 권한이 필요합니다.</string>

<img width="1586" height="419" alt="image" src="https://github.com/user-attachments/assets/38f4c709-7f21-4029-bcf8-517b1eef0042" />

그 다음, `ios/Runner/AppDelegate.swift`를 아래로 바꿔줍니다.

> 기본적으로 iOS는 앱이 실행 중이면 알림을 받아도 표시하지 않는데요, `UNUserNotificationCenter.current().delegate = self`로 설정함으로서 알림을 항상 수신할 수 있게 하는 과정입니다!

```swift
import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  @available(iOS 12.0, *)
  override func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      openSettingsFor notification: UNNotification?
  ) {
      let controller = window?.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel(
          name: "com.example.noti/settings",
          binaryMessenger: controller.binaryMessenger)

      channel.invokeMethod("showNotificationSettings", arguments: nil)
  }
}
```


## Step 3

#### 4. 알림 서비스 `flutter_local_notifications` 초기화하기

`lib/main.dart`를 아래처럼 작성합니다.

```dart
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

  runApp(const MyApp());
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
      body: const Center(),
    );
  }
}
```

이제 앱을 다시 빌드하면 다음과 같이 알림 권한을 묻는 것을 확인할 수 있습니다.

<img width="467" height="995" alt="image" src="https://github.com/user-attachments/assets/a639dc46-6bee-48e8-afc2-0df75d89763e" />



## Step 4

#### 5. 즉시 알림 보내기

먼저 버튼을 눌렀을 때 바로 알림이 오도록 해보겠습니다.

`showSimpleNotification()` 펑션을 `lib/main.dart`에 추가해주세요.

```dart
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
```

그리고 이를 호출하는 버튼을 메인 화면에 추가해주면 됩니다!

```dart
body: Center(
  child: ElevatedButton(
    onPressed: showSimpleNotification,
    child: const Text('즉시 알림 보내기'),
  ),
),
```

<img width="443" height="157" alt="image" src="https://github.com/user-attachments/assets/98d784ea-0dad-4a03-953e-60b3d6d77a37" />


#### 6. 예약 알림 보내기

이번에는 몇 초 뒤에 알림이 오도록 예약해보겠습니다.
이 기능을 위해 `timezone` 패키지를 함께 사용합니다.

```dart
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
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}
```

그리고 이를 호출하는 버튼을 즉시 알림 버튼 아래에 추가해줍니다!

```dart
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
```

<img width="428" height="152" alt="image" src="https://github.com/user-attachments/assets/26ff180f-020a-496d-8492-0616b80927f2" />


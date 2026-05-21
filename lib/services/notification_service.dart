import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> scheduleReminder(String bodyPart) async {
    // 1 Ay sonrası için hatırlatıcı (Test için isterseniz .add(Duration(seconds: 10)) yapabilirsiniz)
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(days: 30));

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'derma_ai_reminders', // channel Id
      'Leke Takip Hatırlatıcıları', // channel Name
      channelDescription: 'Taranan lekelerin düzenli kontrolü için hatırlatıcılar',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    // Her leke için benzersiz bir ID oluştur (basitçe zaman damgası)
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 100000;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Kontrol Vakti Geldi! 🩺',
      body: '$bodyPart bölgesindeki lekeniz için 1 ay önce tarama yapmıştınız. Değişim var mı kontrol etmek ister misiniz?',
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

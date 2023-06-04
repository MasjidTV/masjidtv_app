import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'constants.dart';
import 'home.dart';
import 'pages/app_settings.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  // init timezone
  tz.initializeTimeZones();
  const String timeZoneName = 'Asia/Kuala_Lumpur';
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  // init notif
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notif_app_icon');

  InitializationSettings initializationSettings =
      const InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // init default settings
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(kSpServerPort)) prefs.setInt(kSpServerPort, 8080);
  if (!prefs.containsKey(kSpGithubSource)) {
    prefs.setString(kSpGithubSource, GithubSource.Default.name);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MasjidTV App',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}

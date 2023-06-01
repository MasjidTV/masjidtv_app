import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:masjidtv_app/services/server_task_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'home.dart';
import 'pages/app_settings.dart';

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

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

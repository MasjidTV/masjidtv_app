import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'home.dart';
import 'pages/app_settings.dart';

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

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../server/backend_server.dart';
import '../util/notification_scheduler.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final TextEditingController _portEditingController = TextEditingController();
  final TextEditingController _githubUrlController = TextEditingController();

  bool _notificationEnabled = false;

  @override
  void initState() {
    super.initState();
    initSettings();
  }

  Future<void> initSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // try read from shared preferences
    // if not found, set to random port
    var port = prefs.getInt('kSpServerPort');
    if (port != null) {
      _portEditingController.text = port.toString();
    }

    var savedGithubUrl = prefs.getString(kSpGithubUrl);
    if (savedGithubUrl != null) {
      _githubUrlController.text = savedGithubUrl;
    }

    var isNotificationEnabled = prefs.getBool(kSpNotificationSetting);
    if (isNotificationEnabled != null) {
      setState(() {
        _notificationEnabled = isNotificationEnabled;
      });
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.cable, color: Colors.white),
            ),
            subtitle: const Text(
                'Eg: 1024, 3000, 5500, 8000, etc. If empty, random port will be assigned'),
            title: const Text('Port selection'),
            trailing: SizedBox(
                width: 150,
                child: TextField(
                  controller: _portEditingController,
                  onEditingComplete: () async {
                    // hide keyboard
                    FocusScope.of(context).unfocus();

                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    var port = int.tryParse(_portEditingController.text);

                    if (port == null) {
                      prefs.remove('kSpServerPort');
                      _showToast('Port settings saved');
                      return;
                    }

                    if (port == BackendServer.reservedPort) {
                      _showToast(
                          'Error: Port $port is reserved for backend server. Please choose another port');
                      return;
                    }

                    await prefs.setInt('kSpServerPort', port);
                    _showToast('Port settings saved');
                  },
                  keyboardType: TextInputType.number,
                )),
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.black87,
              child: FaIcon(FontAwesomeIcons.github, color: Colors.white),
            ),
            subtitle: FutureBuilder(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!.getString(kSpGithubUrl) ?? '');
                  }
                  return const Text('Repo to download HTML files from');
                }),
            title: const Text('Source repository'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final sp = await SharedPreferences.getInstance();
                var res = await showDialog(
                  context: context,
                  builder: (_) {
                    final controller = TextEditingController(
                        text: sp.getString(kSpGithubUrl) ?? '');
                    return AlertDialog(
                      title: const Text("Source repository"),
                      content: TextField(controller: controller),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context,
                                  'https://github.com/iqfareez/masjidTV-waktusolat');
                            },
                            child: const Text("Set default")),
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel")),
                        TextButton(
                            onPressed: () {
                              if (controller.text.isEmpty) {
                                Fluttertoast.showToast(
                                    msg: "Please enter a valid URL");
                                return;
                              }
                              Navigator.pop(context, controller.text);
                            },
                            child: const Text("Save")),
                      ],
                    );
                  },
                );

                if (res != null) {
                  await sp.setString(kSpGithubUrl, res);
                  Fluttertoast.showToast(msg: "Github URL is saved");
                  setState(() {});
                }
              },
            ),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.key, color: Colors.white),
            ),
            title: const Text("Repository Key"),
            subtitle: const Text('Only for a private repository'),
            onTap: () async {
              final sp = await SharedPreferences.getInstance();
              var res = await showDialog(
                context: context,
                builder: (_) {
                  final controller = TextEditingController(
                      text: sp.getString(kSpGithubKey) ?? '');
                  return AlertDialog(
                    title: const Text("Repository Key"),
                    content: TextField(
                      controller: controller,
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context, dotenv.env['GH_REPO_PAT']);
                          },
                          child: const Text("Set default")),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel")),
                      TextButton(
                          onPressed: () {
                            sp.remove(kSpGithubKey);
                            Navigator.pop(context);
                          },
                          child: const Text("Clear key")),
                      TextButton(
                          onPressed: () {
                            if (controller.text.isEmpty) {
                              Fluttertoast.showToast(
                                  msg: "Please enter a valid key");
                              return;
                            }
                            Navigator.pop(context, controller.text);
                          },
                          child: const Text("Save")),
                    ],
                  );
                },
              );

              if (res != null) {
                await sp.setString(kSpGithubKey, res);
                Fluttertoast.showToast(msg: "Github Key is saved");
                setState(() {});
              }
            },
          ),
          // const Divider(),
          // ListTile(
          //   isThreeLine: true,
          //   leading: const CircleAvatar(
          //     backgroundColor: Colors.green,
          //     child: Icon(Icons.folder_zip, color: Colors.white),
          //   ),
          //   subtitle: Text(MyStorage.getMasjidTvDirectory().path),
          //   title: const Text("Download location"),
          //   trailing: IconButton(
          //     icon: const Icon(Icons.edit),
          //     onPressed: () async {
          //       final dirOptions =
          //           await MyStorage.getAvailableMasjidTvDirectory();
          //       showDialog(
          //           context: context,
          //           builder: (_) {
          //             return SimpleDialog(
          //               title: const Text("Select download location"),
          //               children: dirOptions
          //                   .map((e) => SimpleDialogOption(
          //                         child: Text(e.path),
          //                         onPressed: () async {
          //                           await MyStorage.setMasjidTvDirectory(
          //                               e.path);
          //                           Navigator.pop(context);
          //                           Fluttertoast.showToast(
          //                               msg: "Download location is saved");
          //                           setState(() {});
          //                         },
          //                       ))
          //                   .toList(),
          //             );
          //           });
          //     },
          //   ),
          // ),
          const Divider(),
          SwitchListTile(
            secondary: const CircleAvatar(
              backgroundColor: Colors.pink,
              child: Icon(Icons.notifications, color: Colors.white),
            ),
            title: const Text("Notification"),
            value: _notificationEnabled,
            onChanged: (value) async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              if (value) {
                var res = await flutterLocalNotificationsPlugin
                    .resolvePlatformSpecificImplementation<
                        AndroidFlutterLocalNotificationsPlugin>()!
                    .requestPermission();

                if (res ?? false) {
                  setState(() => _notificationEnabled = true);
                  Fluttertoast.showToast(msg: "Notification is enabled");
                  prefs.setBool(kSpNotificationSetting, true);
                  try {
                    await NotificationScheduler.scheduleBeepForCurrentMonth();
                  } catch (e) {
                    Fluttertoast.showToast(
                        msg: "Error when scheduling notification: $e");
                  }
                } else {
                  Fluttertoast.showToast(msg: "Notification cannot be enabled");
                  setState(() => _notificationEnabled = false);
                }
              } else {
                Fluttertoast.showToast(msg: "Notification has been disabled");
                await NotificationScheduler.cancelNotification();
                prefs.setBool(kSpNotificationSetting, false);
                setState(() => _notificationEnabled = false);
              }
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text(
                "Please restart the app after settings have been modified"),
          )
        ],
      ),
    );
  }
}

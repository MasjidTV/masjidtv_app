import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../server/backend_server.dart';

// ignore: constant_identifier_names
enum GithubSource { Default, Custom }

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  final TextEditingController _portEditingController = TextEditingController();
  final TextEditingController _githubUrlController = TextEditingController();

  GithubSource _githubSource = GithubSource.Default;
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

    var savedGithubSource = prefs.getString(kSpGithubSource);
    if (savedGithubSource != null) {
      _githubSource = GithubSource.values.byName(savedGithubSource);
      setState(() {});
    }

    var savedGithubUrl = prefs.getString(kSpCustomGithubUrl);
    if (savedGithubUrl != null) {
      _githubUrlController.text = savedGithubUrl;
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
      child: Column(
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
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.black87,
              child: FaIcon(FontAwesomeIcons.github, color: Colors.white),
            ),
            subtitle: const Text('Repo to download HTML files from'),
            title: const Text('Source repository'),
            trailing: DropdownButton<GithubSource>(
              value: _githubSource,
              onChanged: (GithubSource? value) async {
                // This is called when the user selects an item.
                setState(() => _githubSource = value!);
                final sp = await SharedPreferences.getInstance();
                await sp.setString(kSpGithubSource, value!.name);
                Fluttertoast.showToast(msg: "Saved Github source option");
              },
              items: GithubSource.values
                  .map<DropdownMenuItem<GithubSource>>((GithubSource value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value.name),
                );
              }).toList(),
            ),
          ),
          IgnorePointer(
            ignoring: _githubSource != GithubSource.Custom,
            child: ListTile(
              enabled: _githubSource == GithubSource.Custom,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: FaIcon(
                  FontAwesomeIcons.link,
                  color: _githubSource != GithubSource.Custom
                      ? Colors.black26
                      : null,
                ),
              ),
              title: TextField(
                controller: _githubUrlController,
                onSubmitted: (value) async {
                  // Check and add the https:// prefix if missing
                  if (!value.startsWith('http')) {
                    value = 'https://$value';
                  }
                  // save the sp
                  final sp = await SharedPreferences.getInstance();
                  await sp.setString(kSpCustomGithubUrl, value);
                  Fluttertoast.showToast(msg: "Custom Github URL is saved");
                },
              ),
              subtitle:
                  const Text('Custom GitHub repository URL (Public repo)'),
            ),
          ),
        ],
      ),
    );
  }
}

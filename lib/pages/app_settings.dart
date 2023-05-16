import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../server/backend_server.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  final TextEditingController _portEditingController = TextEditingController();
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
        ],
      ),
    );
  }
}

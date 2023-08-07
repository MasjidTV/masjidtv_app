import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../util/link_launcher.dart';

class AppAbout extends StatefulWidget {
  const AppAbout({super.key});

  @override
  State<AppAbout> createState() => _AppAboutState();
}

class _AppAboutState extends State<AppAbout> {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.info, color: Colors.white),
          ),
          title: const Text('Israk Solutions Sdn. Bhd.'),
          subtitle: const Text('https://www.israk.my'),
          onTap: () {
            LinkLauncher.launch('https://www.israk.my/');
          },
        ),
        const Divider(),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.purple,
            child: Icon(Icons.data_object, color: Colors.white),
          ),
          title: const Text('Version'),
          subtitle: FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (_, snapshot) {
                return Text(snapshot.data?.version ?? 'N/A');
              }),
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.phone_android, color: Colors.white),
          ),
          title: const Text('Device Info'),
          subtitle: FutureBuilder(
              future: deviceInfo.androidInfo,
              builder: (_, snapshot) {
                var androidVersion = snapshot.data?.version.release ?? 'N/A';
                var androidSdk = snapshot.data?.version.sdkInt ?? 'Sdk?';
                return Text('Android $androidVersion SDK $androidSdk');
              }),
        ),
      ],
    );
  }
}

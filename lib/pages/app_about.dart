import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppAbout extends StatefulWidget {
  const AppAbout({super.key});

  @override
  State<AppAbout> createState() => _AppAboutState();
}

class _AppAboutState extends State<AppAbout> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }
}

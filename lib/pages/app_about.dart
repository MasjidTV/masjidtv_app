import 'package:flutter/material.dart';

class AppAbout extends StatefulWidget {
  const AppAbout({super.key});

  @override
  State<AppAbout> createState() => _AppAboutState();
}

class _AppAboutState extends State<AppAbout> {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple,
            child: Icon(Icons.data_object, color: Colors.white),
          ),
          title: Text('Version'),
          subtitle: Text('v0.1.2'),
        ),
      ],
    );
  }
}

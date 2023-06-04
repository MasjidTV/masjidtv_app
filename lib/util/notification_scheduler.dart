import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart';

import '../constants.dart';
import '../model/prayer_time_data.dart';
import 'my_storage.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationScheduler {
  static Future<void> scheduleBeepForCurrentMonth() async {
    // load data from shared preferences
    final sp = await SharedPreferences.getInstance();
    final zone = sp.getString(kSpJakimZone);

    if (zone == null) throw Exception('Zone is null');

    final year = DateTime.now().year;
    final month = DateTime.now().month;

    // load data from json
    final dbDir = join((await MyStorage.getMasjidTvDirectory()).path, 'db');

    final jsonFile = File(join(dbDir, '$zone-$month-$year.json'));

    debugPrint('Loading JSON file from ${jsonFile.path}');

    if (!jsonFile.existsSync()) throw Exception('JSON file not found');

    final json = jsonFile.readAsStringSync();
    final data = PrayerTimeData.fromJson(jsonDecode(json));

    final currentDateTime = DateTime.now();

    // schedule
    for (final prayerTime in data.prayers!) {
      debugPrint("Scheduling for ${prayerTime.day}");
      if (prayerTime.fajr!.isAfter(currentDateTime)) {
        //to make sure the time is in future
        await _scheduleSingleBeepNotification(
          id: int.parse(
              prayerTime.fajr!.millisecondsSinceEpoch.toString().substring(5)),
          title: "Fajr",
          scheduledTime: TZDateTime.from(prayerTime.fajr!, local),
        );
      }
      if (prayerTime.syuruk!.isAfter(currentDateTime)) {
        await _scheduleSingleBeepNotification(
          id: int.parse(prayerTime.syuruk!.millisecondsSinceEpoch
              .toString()
              .substring(5)),
          title: 'Syuruk',
          scheduledTime: TZDateTime.from(prayerTime.syuruk!, local),
        );
      }
      if (prayerTime.dhuhr!.isAfter(currentDateTime)) {
        await _scheduleSingleBeepNotification(
          id: int.parse(
              prayerTime.dhuhr!.millisecondsSinceEpoch.toString().substring(5)),
          title: "Zohor",
          scheduledTime: TZDateTime.from(prayerTime.dhuhr!, local),
        );
      }
      if (prayerTime.asr!.isAfter(currentDateTime)) {
        await _scheduleSingleBeepNotification(
          id: int.parse(
              prayerTime.asr!.millisecondsSinceEpoch.toString().substring(5)),
          title: "Asar",
          scheduledTime: TZDateTime.from(prayerTime.asr!, local),
        );
      }
      if (prayerTime.maghrib!.isAfter(currentDateTime)) {
        await _scheduleSingleBeepNotification(
          id: int.parse(prayerTime.maghrib!.millisecondsSinceEpoch
              .toString()
              .substring(5)),
          title: "Maghrib",
          scheduledTime: TZDateTime.from(prayerTime.maghrib!, local),
        );
      }
      if (prayerTime.isha!.isAfter(currentDateTime)) {
        await _scheduleSingleBeepNotification(
          id: int.parse(
              prayerTime.isha!.millisecondsSinceEpoch.toString().substring(5)),
          title: "Isyak",
          scheduledTime: TZDateTime.from(prayerTime.isha!, local),
        );
      }
    }
  }

  /// Single prayer azan notification
  static Future<void> _scheduleSingleBeepNotification(
      //for main prayer functionality
      {
    required int id,
    required String title,
    required TZDateTime scheduledTime,
  }) async {
    var androidSpecifics = AndroidNotificationDetails(
      '$title azan1 id',
      '$title azan notification',
      channelDescription: 'Scheduled daily prayer azan',
      priority: Priority.max,
      importance: Importance.high,
      when: scheduledTime.millisecondsSinceEpoch,
      playSound: true,
      category: AndroidNotificationCategory.alarm,
      sound: const RawResourceAndroidNotificationSound(
          "511492__andersmmg__double-beep"),
      color: Colors.purple,
    );
    var platformChannelSpecifics =
        NotificationDetails(android: androidSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
        id, title, "Azan $title", scheduledTime, platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }
}

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class MyStorage {
  static Directory? _directory;

  static Future<void> init() async {
    // check if there is an entry on Shared Preferences
    // if not, set to default
    final sp = await SharedPreferences.getInstance();
    var savedPath = sp.getString(kSpSaveDirectory);

    if (savedPath != null) {
      _directory = Directory(savedPath);
    } else {
      try {
        _directory = await _externalStoragePath();
      } catch (e) {
        _directory = await getApplicationDocumentsDirectory();
      }
    }
  }

  static Future<void> setMasjidTvDirectory(String path) async {
    if (path.isEmpty) throw Exception('Path cannot be empty');
    final sp = await SharedPreferences.getInstance();
    sp.setString(kSpSaveDirectory, path);
    _directory = Directory(path);
  }

  static Future<List<Directory>> getAvailableMasjidTvDirectory() async {
    // In emulator, i had to use below directory, otherwise error
    // if (await _isRunInEmulator()) {
    //   return await getApplicationDocumentsDirectory();
    // }
    List<Directory> listDir = [];
    try {
      var externalDir = await _externalStoragePath();
      listDir.add(externalDir);
    } catch (e) {
      print(e);
    }
    var appDocDir = await getApplicationDocumentsDirectory();
    listDir.add(appDocDir);

    return listDir;
  }

  static Directory getMasjidTvDirectory() {
    if (_directory == null) {
      throw Exception('Directory not initialized');
    }
    return _directory!;
  }

  static Future<bool> _isRunInEmulator() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    var androidInfo = await deviceInfo.androidInfo;
    return !androidInfo.isPhysicalDevice;
  }

  static Future<Directory> _externalStoragePath() async {
    // build directory on storage
    var extractDir = await getExternalStorageDirectory();
    String newPath = "";
    List<String> paths = extractDir!.path.split("/");
    for (int x = 1; x < paths.length; x++) {
      String folder = paths[x];
      if (folder != "Android") {
        newPath += "/$folder";
      } else {
        break;
      }
    }
    newPath = "$newPath/MasjidTV";
    extractDir = Directory(newPath);
    await extractDir.create();
    return extractDir;
  }
}

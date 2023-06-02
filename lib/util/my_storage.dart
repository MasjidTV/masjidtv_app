import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class MyStorage {
  static Future<Directory> getMasjidTvDirectory() async {
    // In emulator, i had to use below directory, otherwise error
    if (await _isRunInEmulator()) {
      return await getApplicationDocumentsDirectory();
    }

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

  static Future<bool> _isRunInEmulator() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    var androidInfo = await deviceInfo.androidInfo;
    return !androidInfo.isPhysicalDevice;
  }
}

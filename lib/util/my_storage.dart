import 'dart:io';

import 'package:path_provider/path_provider.dart';

class MyStorage {
  static Future<Directory> getMasjidTvDirectory() async {
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

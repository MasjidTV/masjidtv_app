import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'my_storage.dart';

class HtmlContentSetup {
  /// Check if was already setup
  static Future<bool> isAlreadySetup() async {
    final directory = await getExternalStorageDirectory();
    var webDir = Directory(p.join(directory!.path, 'web'));
    return await webDir.exists();
  }

  /// Download repo from github and extract it to the 'web' folder
  static Future<void> setupHtmlContentFromGithub() async {
    var permissionStatus = await Permission.manageExternalStorage.status;
    if (!permissionStatus.isGranted) {
      await Permission.manageExternalStorage.request();
    }
    var zipRepo = await _downloadGithubRepo();
    if (zipRepo == null) {
      throw Exception(
          'No path is returned. Possibly the repo download has failed?');
    }

    // The extracted file is extracted to /web/iqfareez-masjidTV-waktusolat-cb802722d1e5152df3be7b29d286a08ef162f68e
    // We need to move all the files and dir the files to /web
    var extractedPath = await _extractZipToStorage(zipFilePath: zipRepo);

    // Extract the tar file to the device folder
    var extractDir = await MyStorage.getMasjidTvDirectory();

    debugPrint('moving to $extractDir');

    await _moveContentsToDestinationDirectory(extractedPath, extractDir.path);
  }

  static Future<void> _moveContentsToDestinationDirectory(
      String sourceDirectoryPath, String destinationDirectoryPath) async {
    Directory sourceDirectory = Directory(sourceDirectoryPath);
    Directory destinationDirectory = Directory(destinationDirectoryPath);

    if (!await sourceDirectory.exists()) {
      debugPrint('Source directory does not exist!');
      return;
    }

    if (!await destinationDirectory.exists()) {
      debugPrint('Destination directory does not exist!');
      return;
    }

    List<FileSystemEntity> contents = sourceDirectory.listSync();

    for (var element in contents) {
      debugPrint(element.path);
    }

    // for (FileSystemEntity content in contents) {
    //   debugPrint(content.path);
    //   await content.rename(destinationDirectory.path);
    // }

    for (FileSystemEntity content in contents) {
      debugPrint(content.path);
      if (content is Directory) {
        await _copyDirectoryToDestination(content, destinationDirectory);
      } else if (content is File) {
        await _copyFileToDestination(content, destinationDirectory);
      }
    }

    await sourceDirectory.delete(recursive: true);
    debugPrint('Contents moved successfully!');
  }

  static Future<void> _copyDirectoryToDestination(
      Directory sourceDirectory, Directory destinationDirectory) async {
    var tempCorrectedPath = destinationDirectory.path.split('/');
    tempCorrectedPath.removeWhere(
        (element) => element.contains("iqfareez-masjidTV-waktusolat"));
    var correctedDirectory = Directory(tempCorrectedPath.join('/'));
    String sourceDirectoryName = sourceDirectory.path.split('/').last;
    String destinationDirectoryPath =
        '${correctedDirectory.path}/$sourceDirectoryName';
    Directory destinationSubDirectory = Directory(destinationDirectoryPath);
    // remove the first directory name
    // ie: /web/iqfareez-masjidTV-waktusolat-cb802722d1e5152df3be7b29d286a08ef162f68e
    // to /web
    await destinationSubDirectory.create(recursive: true);

    List<FileSystemEntity> contents = sourceDirectory.listSync();

    for (FileSystemEntity content in contents) {
      if (content is Directory) {
        await _copyDirectoryToDestination(content, destinationSubDirectory);
      } else if (content is File) {
        await _copyFileToDestination(content, destinationSubDirectory);
      }
    }
  }

  static Future<void> _copyFileToDestination(
      File sourceFile, Directory destinationDirectory) async {
    var tempCorrectedPath = destinationDirectory.path.split('/');
    tempCorrectedPath.removeWhere(
        (element) => element.contains("iqfareez-masjidTV-waktusolat"));
    var correctedDirectory = Directory(tempCorrectedPath.join('/'));
    String fileName = sourceFile.path.split('/').last;
    File destinationFile = File('${correctedDirectory.path}/$fileName');
    await sourceFile.copy(destinationFile.path);
  }

  // Future<List<String>> _copyAssetsToDocuments(String fromPath, String toPath) async {
  //   // Get the app documents directory.
  //   final directory = await getExternalStorageDirectory();

  //   // removed unwanted assets
  //   assetList.removeWhere((key, value) =>
  //       key.startsWith('assets/app_reserved') || key.startsWith('packages'));

  //   // print all asset that will be copied
  //   for (final assetPath in assetList.keys) {
  //     debugPrint(assetPath);
  //   }

  //   List<String> copiedAssets = [];

  //   // Copy each asset to the app documents directory.
  //   for (final assetPath in assetList.keys) {
  //     final assetData = await bundle.load(assetPath);
  //     // remove the 'assets/' part from the path
  //     final correctedAssetPath = assetPath.replaceFirst('assets/', 'web/');
  //     final file = File('${directory!.path}/$correctedAssetPath');
  //     await file.create(recursive: true);
  //     await file.writeAsBytes(assetData.buffer.asUint8List());

  //     // record
  //     copiedAssets.add(correctedAssetPath);
  //   }

  //   return copiedAssets;
  // }

  static Future<String> _extractZipToStorage(
      {required String zipFilePath}) async {
    // Extract the tar file to the device folder
    final extractDir = await getExternalStorageDirectory();
    final extractPath = p.join(extractDir!.path, 'temp_zip_extract');
    await extractFileToDisk(zipFilePath, extractPath);
    return extractPath;
  }

  static Future<String?> _downloadGithubRepo() async {
    var githubApiKey = dotenv.env['GH_REPO_PAT'];

    debugPrint('key: $githubApiKey');

    const owner = 'iqfareez';
    const repo = 'masjidTV-waktusolat';

    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo/zipball'),
      headers: {
        "Accept": "application/vnd.github+json",
        "Authorization": 'Bearer $githubApiKey',
        "X-GitHub-Api-Version": "2022-11-28",
      },
    );
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      // Get the temporary directory path
      final tempDir = await getApplicationDocumentsDirectory();
      final tempFilePath = p.join(tempDir.path, 'masjidTVrepo.zip');

      // Save the downloaded tar file to the temporary directory
      var file = await File(tempFilePath).create(recursive: true);
      await file.writeAsBytes(bytes);
      // Delete the temporary tar file
      // await file.delete();

      return file.path;
    } else {
      debugPrint('Download zip failed with status: ${response.statusCode}.');
      throw Exception('Failed to download the zip file');
    }
  }
}

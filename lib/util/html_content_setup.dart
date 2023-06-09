import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'my_storage.dart';

class HtmlContentSetup {
  /// Check if was already setup
  static Future<bool> isAlreadySetup() async {
    final directory = MyStorage.getMasjidTvDirectory();
    if (!await directory.exists()) return false;
    // check if contain index.html
    var files = await directory.list().toList();
    return files.isNotEmpty &&
        files.any((element) => element.path.contains('index.html'));
  }

  /// Download repo from github and extract it to the 'web' folder
  static Future<void> setupHtmlContentFromGithub() async {
    var permissionStatus = await Permission.manageExternalStorage.status;
    if (!permissionStatus.isGranted) {
      await Permission.manageExternalStorage.request();
    }

    // check setting for GitHub Source
    final sp = await SharedPreferences.getInstance();

    var ghRepoUrl = sp.getString(kSpGithubUrl);
    var (owner, repo) = _retrieveGitHubOwnerRepo(ghRepoUrl!);

    Fluttertoast.showToast(msg: "Downloading from $owner/$repo");

    var zipRepo = await _downloadGithubRepo(owner: owner, repo: repo);
    if (zipRepo == null) {
      throw Exception(
          'No path is returned. Possibly the repo download has failed?');
    }

    // The extracted file is extracted to /web/iqfareez-masjidTV-waktusolat-cb802722d1e5152df3be7b29d286a08ef162f68e
    // We need to move all the files and dir the files to /web
    var extractedPath = await _extractZipToStorage(zipFilePath: zipRepo);

    // Extract the tar file to the device folder
    var extractDir = MyStorage.getMasjidTvDirectory();

    debugPrint('moving to $extractDir');

    await _moveContentsToDestinationDirectory(extractedPath, extractDir.path,
        ownerRepo: '$owner-$repo');
  }

  static Future<void> _moveContentsToDestinationDirectory(
      String sourceDirectoryPath, String destinationDirectoryPath,
      {required String ownerRepo}) async {
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
        await _copyDirectoryToDestination(content, destinationDirectory,
            ownerRepo: ownerRepo);
      } else if (content is File) {
        await _copyFileToDestination(content, destinationDirectory,
            ownerRepo: ownerRepo);
      }
    }

    await sourceDirectory.delete(recursive: true);
    debugPrint('Contents moved successfully!');
  }

  static Future<void> _copyDirectoryToDestination(
      Directory sourceDirectory, Directory destinationDirectory,
      {required ownerRepo}) async {
    var tempCorrectedPath = destinationDirectory.path.split('/');
    // remove the first directory name
    // ie: /web/iqfareez-masjidTV-waktusolat-cb802722d1e5152df3be7b29d286a08ef162f68e
    // to /web
    tempCorrectedPath.removeWhere((element) => element.contains(ownerRepo));
    var correctedDirectory = Directory(tempCorrectedPath.join('/'));
    String sourceDirectoryName = sourceDirectory.path.split('/').last;

    String destinationDirectoryPath =
        '${correctedDirectory.path}/$sourceDirectoryName';
    Directory destinationSubDirectory = Directory(destinationDirectoryPath);

    // if the directory is an empty folder left by the unzipping process (usually the
    // folder name is based on owner-repo-commit name), we want to skip it
    if (!sourceDirectoryName.startsWith(ownerRepo)) {
      await destinationSubDirectory.create(recursive: true);
    }

    List<FileSystemEntity> contents = sourceDirectory.listSync();

    for (FileSystemEntity content in contents) {
      if (content is Directory) {
        await _copyDirectoryToDestination(content, destinationSubDirectory,
            ownerRepo: ownerRepo);
      } else if (content is File) {
        await _copyFileToDestination(content, destinationSubDirectory,
            ownerRepo: ownerRepo);
      }
    }
  }

  static Future<void> _copyFileToDestination(
      File sourceFile, Directory destinationDirectory,
      {required ownerRepo}) async {
    var tempCorrectedPath = destinationDirectory.path.split('/');
    tempCorrectedPath.removeWhere((element) => element.contains(ownerRepo));
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

  static Future<String?> _downloadGithubRepo(
      {required String owner, required String repo}) async {
    String? githubApiKey;

    debugPrint('key: $githubApiKey');
    var headers = {
      "Accept": "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
    };

    // check setting for GitHub Source
    final sp = await SharedPreferences.getInstance();

    if (sp.getString(kSpGithubKey) != null) {
      githubApiKey = sp.getString(kSpGithubKey);
    }

    if (githubApiKey != null) {
      headers.addAll({"Authorization": 'Bearer $githubApiKey'});
    }

    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo/zipball'),
      headers: headers,
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

/// Extract the owner and repo information from Github URL
(String, String) _retrieveGitHubOwnerRepo(String url) {
  String owner = '';
  String repo = '';

  // Remove .git extension from URL, if present
  if (url.endsWith('.git')) {
    url = url.substring(0, url.length - 4);
  }

  // Extract owner and repo from the URL
  Uri uri = Uri.parse(url);
  List<String> pathSegments = uri.pathSegments;
  if (pathSegments.length >= 2) {
    owner = pathSegments[0];
    repo = pathSegments[1];
  }

  return (owner, repo);
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;

class HtmlContentSetup {
  static Future<void> setupHtmlContentFromGithub() async {
    var zipRepo = await _downloadGithubRepo();
    if (zipRepo == null) {
      throw Exception(
          'No path is returned. Possibly the repo download has failed?');
    }

    // The extracted file is extracted to /web/iqfareez-masjidTV-waktusolat-cb802722d1e5152df3be7b29d286a08ef162f68e
    // We need to move all the files and dir the files to /web
    var extractedPath = await _extractZipToStorage(zipFilePath: zipRepo);

    String sourceDirectoryPath = extractedPath;
    var targetDirectory =
        Directory(p.join((await getExternalStorageDirectory())!.path, 'web'));
    await targetDirectory.create();
    await _moveContentsToDestinationDirectory(
        sourceDirectoryPath, targetDirectory.path);
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

    List<FileSystemEntity> contents = await sourceDirectory.list().toList();

    for (FileSystemEntity content in contents) {
      await content.rename(destinationDirectory.path);
    }

    await sourceDirectory.delete(recursive: true);
    debugPrint('Contents moved successfully!');
  }

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
    print('Received');
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
      print('Request failed with status: ${response.statusCode}.');
      throw Exception('Failed to download the tar file');
    }
  }
}

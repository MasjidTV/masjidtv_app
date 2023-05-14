import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:url_launcher/url_launcher_string.dart';

class LinkLauncher {
  static void launch(String url) {
    url_launcher.launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
  }
}

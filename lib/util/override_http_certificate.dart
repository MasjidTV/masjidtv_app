import 'dart:io';

/// Custom certificate override for HttpClient, use in demand
/// Taken from https://stackoverflow.com/a/67609657/13617136
class OverrideHttpCertificate extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) {
        return true;
      });
  }
}

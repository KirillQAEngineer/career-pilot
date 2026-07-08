import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);

  if (uri == null ||
      !uri.hasScheme ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return false;
  }

  return launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
}
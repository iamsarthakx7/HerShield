import 'package:url_launcher/url_launcher.dart';

class NearbyHelpService {
  static Future<void> openPolice(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/police+station/@$lat,$lng,15z',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openHospital(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/hospital/@$lat,$lng,15z',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

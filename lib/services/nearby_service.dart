import 'package:url_launcher/url_launcher.dart';

class NearbyService {
  static Future<void> openPolice({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/police/@$latitude,$longitude,15z',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  static Future<void> openHospital({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/hospital/@$latitude,$longitude,15z',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

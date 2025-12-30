 import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static Future<void> sendSMS({
    required String phone,
    required String message,
  }) async {
    final Uri uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

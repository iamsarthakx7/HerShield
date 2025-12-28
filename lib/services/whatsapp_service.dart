import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final encodedMessage = Uri.encodeComponent(message);

    final url = Uri.parse(
      'https://wa.me/$phone?text=$encodedMessage',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not open WhatsApp';
    }
  }
}

import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final encodedMessage = Uri.encodeComponent(message);

    final Uri url = Uri.parse(
      'https://wa.me/$phone?text=$encodedMessage',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }
}
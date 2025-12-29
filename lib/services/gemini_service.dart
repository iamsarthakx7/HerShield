import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ⚠️ Move this to env later (keep for now)
  static const String _apiKey = 'AIzaSyBw_nXxBnKe1GdBJEwv-tvugWPaufmFROQ';

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  Future<String> sendMessage({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final uri = Uri.parse('$_endpoint?key=$_apiKey');

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text": """
$systemPrompt

$userMessage
"""
            }
          ]
        }
      ]
    };

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    // 🔍 DEBUG (keep during development)
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return data['candidates'][0]['content']['parts'][0]['text']
        .toString()
        .trim();
  }
}

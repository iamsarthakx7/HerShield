import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ⚠️ HACKATHON-ONLY KEY
  static const String _apiKey = 'AIzaSyBiKY5Zxzr5URXqq1-VYZEwPdKpv_DzPIY';

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  // ============================
  // 🇮🇳 INDIA-SPECIFIC SAFETY PROMPT
  // ============================
  static const String safetySystemPrompt = """
You are a women's safety assistant inside a mobile safety app used in INDIA.

IMPORTANT CONTEXT:
- The user is in India.
- India's main emergency number is 112.
- Women helpline numbers include 181 and 1091.
- Police assistance is available through nearby police stations.

Your task is to analyze the user's message and assess danger level.

Classify the situation into ONE of these risk levels:
- low
- medium
- high

Rules:
- If the user expresses fear, panic, being followed, threatened, trapped, lost, or unsafe → risk is HIGH
- If the user asks for safety advice, helplines, or nearby help → risk is MEDIUM
- Normal conversation → risk is LOW

If risk is HIGH, recommend activating SOS.

When appropriate, suggest India-specific help options such as:
- Calling emergency number 112
- Contacting women helpline 181 or 1091
- Seeking help from nearby police

Respond ONLY in valid JSON with these keys:
- risk_level
- recommend_sos
- reason
- advice

Do not add extra text.
Do not include markdown.
""";

  // ============================
  // 🔁 GENERIC GEMINI CALL
  // ============================
  Future<String> sendMessage({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final uri = Uri.parse('$_endpoint?key=$_apiKey');

    final body = {
      "systemInstruction": {
        "parts": [
          {"text": systemPrompt}
        ]
      },
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": userMessage}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 300
      }
    };

    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini error: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return data['candidates'][0]['content']['parts'][0]['text']
        .toString()
        .trim();
  }

  // ============================
  // 🚨 SAFETY ANALYSIS METHOD
  // ============================
  Future<Map<String, dynamic>> analyzeSafetyMessage(
      String userMessage) async {
    final responseText = await sendMessage(
      systemPrompt: safetySystemPrompt,
      userMessage: userMessage,
    );

    try {
      return jsonDecode(responseText);
    } catch (_) {
      return {
        "risk_level": "low",
        "recommend_sos": false,
        "reason": "Unable to analyze safely",
        "advice": ""
      };
    }
  }
}

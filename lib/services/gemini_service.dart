import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class GeminiResponse {
  final String text;
  final String? audioUrl;

  GeminiResponse({required this.text, this.audioUrl});
}

class GeminiService {
  Future<GeminiResponse> sendMessage(String message, {String lang = "en-US"}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chat/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': message,
          'lang': lang,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GeminiResponse(
          text: data['text'] ?? "No response from AI",
          audioUrl: data['audioUrl'],
        );
      } else {
        print("Erro Gemini Server: ${response.statusCode} - ${response.body}");
        return GeminiResponse(
          text: "Error ${response.statusCode}: Failed to get response from server.",
        );
      }
    } catch (e) {
      print("Erro de conexão Gemini Server: $e");
      return GeminiResponse(text: "Connection error: $e");
    }
  }
}


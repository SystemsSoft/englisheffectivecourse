import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = "AQ.Ab8RN6I3mwbx8p4CIQwsNi-sdrisYGPVCGLwSIqLzeLzVvo3hg";

  // Modelo gemini-3.6-flash confirmado via testes de conexão
  final String baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent";

  final List<Map<String, dynamic>> _history = [];

  GeminiService() {
    _history.add({
      "role": "user",
      "parts": [
        {"text": "Você é Megam, uma tutora especialista em conversação em inglês. Seu objetivo é ajudar o aluno a praticar conversação de forma amigável, incentivando-o a falar e corrigindo-o educadamente se necessário. Responda sempre de forma concisa e encorajadora. Você deve conversar em inglês com o aluno, mas pode dar explicações em português se ele não entender algo ou se você estiver corrigindo um erro gramatical importante."}
      ]
    });
    _history.add({
      "role": "model",
      "parts": [
        {"text": "Hello! I am Megam, your English conversation tutor. I'm here to help you practice and improve your speaking skills. How are you feeling today? Let's start our conversation!"}
      ]
    });
  }

  Future<String> sendMessage(String message) async {
    _history.add({
      "role": "user",
      "parts": [
        {"text": message}
      ]
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl?key=$apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": _history,
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 1000,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        _history.add({
          "role": "model",
          "parts": [
            {"text": text}
          ]
        });

        return text;
      } else {
        print("Erro Gemini API: ${response.statusCode}");
        print("Corpo: ${response.body}");
        return "Erro ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      print("Exceção na chamada Gemini: $e");
      return "Erro de conexão: $e";
    }
  }
}

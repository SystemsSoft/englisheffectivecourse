import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiResponse {
  final String text;
  final String? audioBase64;

  GeminiResponse({required this.text, this.audioBase64});
}

class GeminiService {
  final String apiKey = "AQ.Ab8RN6I3mwbx8p4CIQwsNi-sdrisYGPVCGLwSIqLzeLzVvo3hg";

  // Usando o modelo confirmado em testes (gemini-3.6-flash para 2026)
  final String baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent";

  final List<Map<String, dynamic>> _history = [];

  GeminiService() {
    _history.add({
      "role": "user",
      "parts": [
        {"text": "Você é Megam, uma tutora de inglês profissional, calma e prestativa. Seu objetivo é ajudar o aluno a praticar inglês de forma natural e clara. Aja como uma professora encorajadora. Suas respostas devem ser predominantemente em inglês. Se houver dicas, explicações gramaticais ou correções em português, coloque-as SEMPRE após o marcador '---' e nunca misture os idiomas antes desse marcador."}
      ]
    });
  }

  Future<GeminiResponse> sendMessage(String message) async {
    _history.add({
      "role": "user",
      "parts": [{"text": message}]
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl?key=$apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": _history,
          "generationConfig": {
            "temperature": 0.7,
            "topP": 0.95,
            "topK": 64,
            "maxOutputTokens": 1000,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates'][0];
        final text = candidate['content']['parts'][0]['text'];

        _history.add({
          "role": "model",
          "parts": [{"text": text}]
        });

        return GeminiResponse(text: text);
      } else {
        print("Erro Gemini: ${response.statusCode} - ${response.body}");
        return GeminiResponse(text: "Erro ${response.statusCode}: Verifique o console para detalhes.");
      }
    } catch (e) {
      return GeminiResponse(text: "Erro de conexão: $e");
    }
  }
}

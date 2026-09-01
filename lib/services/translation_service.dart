import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

/// Traduz um texto via o backend (POST /translate), para exibir a tradução
/// do que a Megan disse na chamada de voz.
///
/// Endpoint esperado (a ser criado no backend):
///   POST /translate
///   body: {"text": "...", "targetLang": "pt-BR"}
///   resp 200: {"translation": "..."}
class TranslationService {
  Future<String?> translate(String text, {String targetLang = 'pt-BR'}) async {
    if (text.trim().isEmpty) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'targetLang': targetLang}),
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['translation'] as String?;
    } catch (_) {
      return null;
    }
  }
}

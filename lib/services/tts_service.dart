import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class TTSService {
  Future<String?> getAudioUrl(String text, {String lang = "en-US"}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chat/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'lang': lang,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['audioUrl'] as String?;
      } else {
        print("Erro TTS Server: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Erro de conexão TTS Server: $e");
      return null;
    }
  }
}

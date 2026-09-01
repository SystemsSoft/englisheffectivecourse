import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local_config.dart';

/// PROVISÓRIO — só para teste local do comportamento de tradução.
///
/// Chama a Gemini diretamente do cliente Flutter Web para traduzir o texto
/// que a Megan disse. Isso expõe a API key no bundle JS compilado (qualquer
/// pessoa consegue extraí-la pelo DevTools do navegador) — por isso a chave
/// nunca fica hardcoded aqui, só em lib/local_config.dart (não versionado,
/// veja .gitignore) ou via --dart-define=GEMINI_API_KEY=... Este serviço
/// NÃO deve ser usado em um build publicado/produção. Em produção, a
/// tradução deve passar por um endpoint do backend, que já guarda a chave
/// da Gemini em segurança (mesmo motivo pelo qual o relay de voz já
/// funciona assim).
class GeminiTranslationService {
  static const String _dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
  static final String _apiKey =
      _dartDefineKey.isNotEmpty ? _dartDefineKey : LocalConfig.geminiApiKey;
  static const String _model = 'gemini-3.5-flash-lite';

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<String> translate(String text, {String targetLang = 'português do Brasil'}) async {
    if (!isConfigured) {
      throw StateError(
        'GEMINI_API_KEY não configurada. Rode com '
        '--dart-define=GEMINI_API_KEY=SUA_CHAVE (só para teste local).',
      );
    }
    if (text.trim().isEmpty) return '';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Traduza o texto a seguir para $targetLang. '
                    'Responda apenas com a tradução, sem aspas, sem comentários, '
                    'sem explicações.\n\nTexto: $text',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao traduzir (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    final parts = (candidates?.first as Map<String, dynamic>?)?['content']?['parts'] as List?;
    final translated = (parts?.first as Map<String, dynamic>?)?['text'] as String?;
    if (translated == null || translated.isEmpty) {
      throw Exception('Resposta de tradução vazia.');
    }
    return translated.trim();
  }
}

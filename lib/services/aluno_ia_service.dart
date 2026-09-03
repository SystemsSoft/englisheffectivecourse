import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/aluno_ia_model.dart';
import '../models/assinatura_status_model.dart';
import '../utils/api_config.dart';

class AlunoIaService {
  /// Busca o registro do aluno na Megan. Retorna `null` se ainda não existe (404).
  Future<AlunoIaDto?> getAluno(String userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/aluno-ia/${Uri.encodeComponent(userId)}',
    );
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AlunoIaDto.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Erro ao buscar aluno na Megan (${response.statusCode}).');
  }

  /// Cria o registro do aluno na Megan.
  Future<AlunoIaDto> criarAluno(AlunoIaDto aluno) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/aluno-ia');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(aluno.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AlunoIaDto.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erro ao criar aluno na Megan (${response.statusCode}).');
  }

  /// Avança a missão (dia) do aluno. Só deve ser chamado quando o aluno
  /// completa a chamada de voz inteira (15 minutos) — nunca ao desligar
  /// antes do tempo.
  Future<AlunoIaDto> avancarMissao(String userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/aluno-ia/${Uri.encodeComponent(userId)}/avancar-missao',
    );

    debugPrint('[avancarMissao] ▶ POST $uri');
    debugPrint('[avancarMissao] ▶ userId enviado: "$userId"');

    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      debugPrint(
        '[avancarMissao] ✖ Exceção de rede antes de qualquer resposta: $e',
      );
      debugPrint('[avancarMissao] ✖ StackTrace: $st');
      rethrow;
    }

    debugPrint('[avancarMissao] ◀ status: ${response.statusCode}');
    debugPrint('[avancarMissao] ◀ headers: ${response.headers}');
    debugPrint('[avancarMissao] ◀ body: ${response.body}');

    if (response.statusCode == 200) {
      final parsed = AlunoIaDto.fromJson(jsonDecode(response.body));
      debugPrint(
        '[avancarMissao] ✔ parseado com sucesso: userId=${parsed.userId} '
        'moduloAtual=${parsed.moduloAtual} missaoAtual=${parsed.missaoAtual} '
        'ultimaSessao=${parsed.ultimaSessao}',
      );
      return parsed;
    }
    debugPrint(
      '[avancarMissao] ✖ status inesperado (${response.statusCode}), lançando exceção.',
    );
    throw Exception(
      'Erro ao avançar missão (${response.statusCode}): ${response.body}',
    );
  }

  /// Consulta o status de assinatura do aluno — usado para liberar o botão
  /// "Chamar a Megan" quando ele já passou da missão 1.
  Future<AssinaturaStatusDto> getAssinaturaStatus(String userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/aluno-ia/${Uri.encodeComponent(userId)}/assinatura',
    );
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AssinaturaStatusDto.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 404) {
      throw Exception('Aluno não encontrado ao verificar assinatura.');
    }
    throw Exception('Erro ao verificar assinatura (${response.statusCode}).');
  }

  /// Pede ao backend a URL do Stripe Customer Portal, onde o aluno gerencia
  /// (troca forma de pagamento) ou cancela a própria assinatura sem
  /// precisar de login extra. [returnUrl] é para onde a Stripe manda o
  /// aluno de volta depois que ele sai do portal.
  Future<String> getPortalAssinaturaUrl(String userId, String returnUrl) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/aluno-ia/${Uri.encodeComponent(userId)}/portal-assinatura',
    ).replace(queryParameters: {'returnUrl': returnUrl});
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'] as String;
    }
    if (response.statusCode == 400) {
      throw Exception('Você ainda não tem uma assinatura ativa.');
    }
    if (response.statusCode == 404) {
      throw Exception('Aluno não encontrado.');
    }
    throw Exception(
      'Erro ao abrir o portal de assinatura (${response.statusCode}).',
    );
  }
}

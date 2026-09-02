import 'dart:convert';
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
    throw Exception(
      'Erro ao buscar aluno na Megan (${response.statusCode}).',
    );
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
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AlunoIaDto.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erro ao avançar missão (${response.statusCode}).');
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
}

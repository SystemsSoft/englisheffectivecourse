import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/aluno_ia_model.dart';
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
}

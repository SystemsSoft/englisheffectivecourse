import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/curriculo_model.dart';
import '../utils/api_config.dart';

class CurriculoService {
  /// Busca todos os módulos do currículo da Megan.
  Future<List<CurriculoModuloDto>> getCurriculo() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/curriculo');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar currículo (${response.statusCode}).');
    }
    // O servidor às vezes cai no fallback estático (serve HTML) para rotas
    // que não existem de fato no backend — sem isso, o erro de parsing
    // JSON ficaria confuso ("FormatException: Unexpected character").
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('json')) {
      throw Exception(
        'Endpoint de currículo indisponível (respondeu $contentType em vez de JSON).',
      );
    }
    final data = jsonDecode(response.body) as List;
    return data
        .map((e) => CurriculoModuloDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

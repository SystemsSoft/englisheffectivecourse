import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/access_model.dart';
import '../utils/api_config.dart';

class AccessService {
  /// Busca todos os registros e valida name + password.
  /// Retorna o [AccessDto] do aluno se encontrado, ou lança uma exceção.
  Future<AccessDto> login(String name, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/access');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

      final match = data
          .map((e) => AccessDto.fromJson(e as Map<String, dynamic>))
          .where((a) => a.name == name && a.password == password)
          .firstOrNull;

      if (match != null) {
        return match;
      } else {
        throw Exception('Nome ou senha inválidos.');
      }
    } else {
      throw Exception('Erro ao conectar ao servidor (${response.statusCode}).');
    }
  }
}


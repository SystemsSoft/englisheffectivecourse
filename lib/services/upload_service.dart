import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/upload_model.dart';

class UploadService {
  static const String _baseUrl = 'https://athennaserver-5c57d33a2f13.herokuapp.com';

  Future<List<UploadFilteredDto>> fetchByClassName(String className) async {
    final uri = Uri.parse('$_baseUrl/upload/filter').replace(
      queryParameters: {'className': className},
    );

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => UploadFilteredDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Erro ao buscar aulas (${response.statusCode}).');
    }
  }
}


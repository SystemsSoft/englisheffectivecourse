import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flashcard_model.dart';

class FlashcardService {
  static const String _baseUrl =
      'https://athennaserver-5c57d33a2f13.herokuapp.com';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // ─── GET /flashcards?studentName=&className= ──────────────────────────────
  /// Retorna todos os flashcards do aluno.
  Future<List<FlashcardDto>> fetchAll({
    required String studentName,
    required String className,
  }) async {
    final uri = Uri.parse('$_baseUrl/flashcards').replace(
      queryParameters: {
        'studentName': studentName,
        'className': className,
      },
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data =
          jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => FlashcardDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Erro ao buscar flashcards (${response.statusCode}).');
    }
  }

  // ─── POST /flashcards ─────────────────────────────────────────────────────
  /// Cria um novo flashcard e retorna o objeto salvo (com id).
  Future<FlashcardDto> create(FlashcardDto card) async {
    final uri = Uri.parse('$_baseUrl/flashcards');

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(card.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return FlashcardDto.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(
          'Erro ao criar flashcard (${response.statusCode}).');
    }
  }

  // ─── PUT /flashcards/:id?studentName=&className= ─────────────────────────
  /// Atualiza um flashcard existente pelo id.
  Future<FlashcardDto> update(
    String id,
    FlashcardDto card, {
    required String studentName,
    required String className,
  }) async {
    final uri = Uri.parse('$_baseUrl/flashcards/$id').replace(
      queryParameters: {
        'studentName': studentName,
        'className': className,
      },
    );

    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(card.toJson()),
    );

    if (response.statusCode == 200) {
      return FlashcardDto.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(
          'Erro ao atualizar flashcard (${response.statusCode}).');
    }
  }

  // ─── DELETE /flashcards/:id?studentName=&className= ──────────────────────
  /// Remove um flashcard pelo id.
  Future<void> delete(
    String id, {
    required String studentName,
    required String className,
  }) async {
    final uri = Uri.parse('$_baseUrl/flashcards/$id').replace(
      queryParameters: {
        'studentName': studentName,
        'className': className,
      },
    );

    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Erro ao remover flashcard (${response.statusCode}).');
    }
  }

  // ─── DELETE /flashcards?studentName=&className= ───────────────────────────
  /// Remove TODOS os flashcards de um aluno.
  Future<void> deleteAll({
    required String studentName,
    required String className,
  }) async {
    final uri = Uri.parse('$_baseUrl/flashcards').replace(
      queryParameters: {
        'studentName': studentName,
        'className': className,
      },
    );

    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Erro ao remover flashcards (${response.statusCode}).');
    }
  }
}


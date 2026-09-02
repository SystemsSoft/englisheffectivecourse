/// Espelha o retorno de GET /curriculo: um módulo do currículo da Megan,
/// com a lista de dias/tópicos.
class CurriculoModuloDto {
  final String moduleId;
  final int totalDias;
  final List<CurriculoDiaDto> dias;

  const CurriculoModuloDto({
    required this.moduleId,
    required this.totalDias,
    required this.dias,
  });

  factory CurriculoModuloDto.fromJson(Map<String, dynamic> json) {
    return CurriculoModuloDto(
      moduleId: json['moduleId'] as String,
      totalDias: json['totalDias'] as int? ?? 0,
      dias: (json['dias'] as List? ?? [])
          .map((e) => CurriculoDiaDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CurriculoDiaDto {
  final int day;
  final String topic;

  const CurriculoDiaDto({required this.day, required this.topic});

  factory CurriculoDiaDto.fromJson(Map<String, dynamic> json) {
    return CurriculoDiaDto(
      day: json['day'] as int,
      topic: json['topic'] as String? ?? '',
    );
  }
}

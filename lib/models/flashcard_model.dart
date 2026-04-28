class FlashcardDto {
  final String? id; // backend retorna Int — convertemos para String
  final String studentName;
  final String className;
  final String word;
  final String type;
  final String definition;
  final String example;

  const FlashcardDto({
    this.id,
    required this.studentName,
    required this.className,
    required this.word,
    required this.type,
    required this.definition,
    required this.example,
  });

  factory FlashcardDto.fromJson(Map<String, dynamic> j) => FlashcardDto(
        // Backend usa id Int (ex: 42) — convertemos para String para o Flutter
        id: j['id'] != null ? j['id'].toString() : null,
        studentName: j['studentName'] as String,
        className: j['className'] as String,
        word: j['word'] as String,
        type: j['type'] as String? ?? 'word',
        definition: j['definition'] as String,
        example: j['example'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'studentName': studentName,
        'className': className,
        'word': word,
        'type': type,
        'definition': definition,
        'example': example,
        // 'id' não é enviado no body — só no path param
      };
}


import 'dart:math';

/// Gera um identificador no formato ULID (26 caracteres, Crockford's
/// Base32): 10 caracteres de timestamp (ms desde a epoch) + 16 caracteres
/// aleatórios. Usado como userId único do aluno na Megan.
class Ulid {
  static const String _encoding = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static final Random _random = Random.secure();

  static String generate() {
    final buffer = StringBuffer();

    // Timestamp (48 bits em teoria, mas ms-desde-epoch cabe com folga em
    // 10 chars de 5 bits = 50 bits). Usa divisão/módulo (não bitwise) para
    // ser seguro tanto no VM nativo quanto compilado para JS (Web).
    var time = DateTime.now().millisecondsSinceEpoch;
    final timeChars = List<String>.filled(10, '0');
    for (var i = 9; i >= 0; i--) {
      timeChars[i] = _encoding[time % 32];
      time = time ~/ 32;
    }
    buffer.write(timeChars.join());

    // 16 caracteres aleatórios (80 bits de entropia).
    for (var i = 0; i < 16; i++) {
      buffer.write(_encoding[_random.nextInt(32)]);
    }

    return buffer.toString();
  }
}

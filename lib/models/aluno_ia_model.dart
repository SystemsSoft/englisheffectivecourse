class AlunoIaDto {
  final int? id;
  final String userId;
  final String nome;
  final String email;
  final String stripeCustomerId;
  final String planoAtivo;
  final String moduloAtual;
  final String missaoAtual;
  final String ultimaSessao;

  const AlunoIaDto({
    this.id,
    required this.userId,
    required this.nome,
    required this.email,
    required this.stripeCustomerId,
    required this.planoAtivo,
    required this.moduloAtual,
    required this.missaoAtual,
    required this.ultimaSessao,
  });

  factory AlunoIaDto.fromJson(Map<String, dynamic> json) {
    return AlunoIaDto(
      id: json['id'] as int?,
      userId: json['userId'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      stripeCustomerId: json['stripeCustomerId'] as String? ?? '',
      planoAtivo: json['planoAtivo'] as String? ?? '',
      moduloAtual: json['moduloAtual'] as String? ?? 'module1',
      missaoAtual: json['missaoAtual'] as String? ?? '1',
      ultimaSessao: json['ultimaSessao'] as String? ?? '',
    );
  }

  /// Corpo para POST /aluno-ia (sem `id`, gerado pelo servidor).
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'nome': nome,
        'email': email,
        'stripeCustomerId': stripeCustomerId,
        'planoAtivo': planoAtivo,
        'moduloAtual': moduloAtual,
        'missaoAtual': missaoAtual,
        'ultimaSessao': ultimaSessao,
      };
}

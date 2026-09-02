/// Espelha o `AssinaturaStatusDto` do backend (GET /aluno-ia/{userId}/assinatura).
class AssinaturaStatusDto {
  final bool assinante;
  final bool ativa;
  final bool cancelada;
  final bool pagamentoFalhou;
  final String status;
  final String? atualizadoEm;

  const AssinaturaStatusDto({
    required this.assinante,
    required this.ativa,
    required this.cancelada,
    required this.pagamentoFalhou,
    required this.status,
    this.atualizadoEm,
  });

  factory AssinaturaStatusDto.fromJson(Map<String, dynamic> json) {
    return AssinaturaStatusDto(
      assinante: json['assinante'] as bool? ?? false,
      ativa: json['ativa'] as bool? ?? false,
      cancelada: json['cancelada'] as bool? ?? false,
      pagamentoFalhou: json['pagamentoFalhou'] as bool? ?? false,
      status: json['status'] as String? ?? 'INATIVA',
      atualizadoEm: json['atualizadoEm'] as String?,
    );
  }
}

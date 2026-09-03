enum MeganCallState {
  idle,
  requestingPermission,
  connecting,

  /// Socket conectado e a Megan já foi "chamada" (saudação enviada), mas
  /// ainda não respondeu — toca o tom de chamando, como se o telefone
  /// estivesse tocando esperando ela atender.
  ringing,
  inCall,

  /// A conexão caiu sozinha no meio da chamada e o app está tentando
  /// reabrir a sessão automaticamente — o cronômetro fica pausado (não
  /// reseta) enquanto esse estado dura.
  reconnecting,
  ended,
}

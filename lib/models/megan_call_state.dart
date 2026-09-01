enum MeganCallState {
  idle,
  requestingPermission,
  connecting,
  /// Socket conectado e a Megan já foi "chamada" (saudação enviada), mas
  /// ainda não respondeu — toca o tom de chamando, como se o telefone
  /// estivesse tocando esperando ela atender.
  ringing,
  inCall,
  ended,
}

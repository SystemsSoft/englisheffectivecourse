// Exporta a implementação correta de acordo com a plataforma:
// – Na Web: sintetiza o tom de "chamando" via Web Audio API (sem depender
//   de nenhum arquivo de áudio)
// – Nativo: stub (o app hoje só suporta a chamada da Megan em Web)
export 'megan_ringback_player_stub.dart'
    if (dart.library.html) 'megan_ringback_player_web.dart';

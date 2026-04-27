// Exporta a implementação correta de acordo com a plataforma:
// – Na Web: usa dart:html AudioElement (sem crossOrigin → sem CORS)
// – Nativo: usa just_audio
export 'radio_player_stub.dart'
    if (dart.library.html) 'radio_player_web.dart';


// Exporta a implementação correta de acordo com a plataforma:
// – Na Web: captura/reprodução PCM via Web Audio API (package:web)
// – Nativo: stub (a chamada de voz com a Megan hoje só é suportada em Web)
export 'megan_audio_io_stub.dart'
    if (dart.library.html) 'megan_audio_io_web.dart';

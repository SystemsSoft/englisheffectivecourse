// Export condicional: usa implementação web em Flutter Web,
// stub nas demais plataformas.
export 'pwa_install_stub.dart'
    if (dart.library.js_interop) 'pwa_install_web.dart';


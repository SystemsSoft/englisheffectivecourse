import 'dart:js_interop';

@JS('pwaInstallAvailable')
external bool get _pwaInstallAvailable;

@JS('triggerPwaInstall')
external void _triggerPwaInstall();

@JS('onPwaInstallAvailable')
external set _onPwaInstallAvailable(JSFunction? fn);

@JS('navigator.userAgent')
external String get _userAgent;

@JS('navigator.standalone')
external bool? get _navigatorStandalone;

bool get isPwaInstallAvailable {
  try {
    return _pwaInstallAvailable;
  } catch (_) {
    return false;
  }
}

/// true se for iPhone / iPad / iPod
bool get isIosDevice {
  try {
    final ua = _userAgent.toLowerCase();
    return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
  } catch (_) {
    return false;
  }
}

/// true se o app já está rodando instalado (modo standalone)
bool get isInStandaloneMode {
  try {
    if (_navigatorStandalone == true) return true;
    return false;
  } catch (_) {
    return false;
  }
}

void triggerPwaInstall() {
  try {
    _triggerPwaInstall();
  } catch (_) {}
}

void registerPwaCallback(void Function() callback) {
  _onPwaInstallAvailable = callback.toJS;
}

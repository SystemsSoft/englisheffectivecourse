import 'dart:js_interop';

@JS('pwaInstallAvailable')
external bool get _pwaInstallAvailable;

@JS('triggerPwaInstall')
external void _triggerPwaInstall();

@JS('onPwaInstallAvailable')
external set _onPwaInstallAvailable(JSFunction? fn);

bool get isPwaInstallAvailable {
  try {
    return _pwaInstallAvailable;
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


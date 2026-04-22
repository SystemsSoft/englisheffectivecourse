// Stub para plataformas não-web (Android/iOS nativos)
bool get isPwaInstallAvailable => false;
bool get isIosDevice => false;
bool get isInStandaloneMode => false;
void triggerPwaInstall() {}
void registerPwaCallback(void Function() callback) {}

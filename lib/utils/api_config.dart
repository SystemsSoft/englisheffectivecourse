class ApiConfig {
  /// Host base da API REST, ex.: https://seu-host.com ou http://192.168.29.3:8080
  ///
  /// Configurável em tempo de build via:
  ///   flutter build web --dart-define=API_BASE_URL=https://seu-host.com
  /// Sem o --dart-define, cai no valor de desenvolvimento abaixo.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.effectiveenglishcourse.com',
  );

  /// Host base do WebSocket, derivado de [baseUrl] trocando http→ws e https→wss.
  static String get wsBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return 'wss://${baseUrl.substring('https://'.length)}';
    }
    if (baseUrl.startsWith('http://')) {
      return 'ws://${baseUrl.substring('http://'.length)}';
    }
    return baseUrl;
  }
}

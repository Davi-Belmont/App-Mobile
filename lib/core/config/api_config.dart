// Responsável: Cainã Coutinho
class ApiConfig {
  /// URL base da API (PDF: http://localhost:3000).
  /// - Emulador Android: http://10.0.2.2:3000  (padrão abaixo)
  /// - iOS Simulator / desktop: http://localhost:3000
  /// - Celular físico: http://IP_DO_SEU_PC:3000
  /// Pode ser trocada sem editar o código:
  ///   flutter run --dart-define=API_URL=http://localhost:3000
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration timeout = Duration(seconds: 10);
}

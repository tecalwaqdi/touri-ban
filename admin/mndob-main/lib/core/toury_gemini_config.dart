/// مفتاح Google Gemini API (Generative Language).
/// مرّره عند البناء: `--dart-define=TOURY_GEMINI_API_KEY=...`
abstract final class TouryGeminiConfig {
  TouryGeminiConfig._();

  static const String apiKey = String.fromEnvironment(
    'TOURY_GEMINI_API_KEY',
    defaultValue: '',
  );
}

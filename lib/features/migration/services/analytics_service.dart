class MigrationAnalyticsService {
  void logEvent(String name, [Map<String, dynamic>? parameters]) {
    // Print to console for production auditing/verification.
    // Can be easily connected to Firebase Analytics, Mixpanel, or Amplitude.
    print('📊 [Migration Analytics] Event: $name, Parameters: $parameters');
  }
}

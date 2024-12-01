class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  static const String apiUsersEndpoint = '$apiBaseUrl/users';
  static const String apiRacesEndpoint = '$apiBaseUrl/admin/races';
}

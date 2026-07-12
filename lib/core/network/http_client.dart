abstract class HttpClient {
  /// Performs a GET request to [url] and returns the response body as a string.
  /// Throws [NetworkException] on connection failure.
  /// Throws [TimeoutException] if the request exceeds [timeout].
  Future<String> get(String url, {Duration? timeout});

  /// Performs a POST request to [url] with [body] and [headers], returning
  /// the response body as a string.
  /// Throws [NetworkException] on connection failure.
  /// Throws [TimeoutException] if the request exceeds [timeout].
  Future<String> post(
    String url, {
    required String body,
    Map<String, String>? headers,
    Duration? timeout,
  });
}

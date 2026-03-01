abstract class HttpClient {
  /// Performs a GET request to [url] and returns the response body as a string.
  /// Throws [NetworkException] on connection failure.
  /// Throws [TimeoutException] if the request exceeds [timeout].
  Future<String> get(String url, {Duration? timeout});
}

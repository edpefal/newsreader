import 'dart:async' as dart_async;
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/network/http_client.dart';

class HttpPackageClient implements HttpClient {
  final http.Client _client;

  HttpPackageClient({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<String> get(String url, {Duration? timeout}) async {
    final effectiveTimeout = timeout ?? AppConstants.feedFetchTimeout;
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(effectiveTimeout);
      return response.body;
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on dart_async.TimeoutException {
      throw const TimeoutException();
    }
  }
}

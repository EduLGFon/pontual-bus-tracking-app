// Keep-alive client for native platforms.
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Creates the shared keep-alive client.
http.Client createHttpClient() {
  return IOClient(
    HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 30)
      ..maxConnectionsPerHost = 4,
  );
}

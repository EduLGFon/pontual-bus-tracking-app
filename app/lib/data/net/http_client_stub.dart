// Browser client for web builds.
import 'package:http/http.dart' as http;

/// Creates the shared client on web.
http.Client createHttpClient() => http.Client();

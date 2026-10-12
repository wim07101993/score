import 'package:http/http.dart' as http;
import 'package:score/config.dart';
import 'package:score_api/score_api.dart' show CustomServer, HealthApi;
import 'package:tonik_util/tonik_util.dart';

// TODO move these times out of this file
final endOfTime = DateTime.now().toUtc().add(const Duration(days: 15340));
final beginningOfTime = DateTime.utc(1970);

/// Builds the generated clients, and is the http client they send with:
/// every request goes out over [inner] signed with the token of the moment,
/// which [authToken] is asked for each time.
class ApiClientFactory({
  required final ApiConfig config,
  required final http.Client inner,
  required final Future<String> Function() authToken,
}) extends http.BaseClient {
  T build<T>(T Function(CustomServer server) create) => create(
    CustomServer(
      baseUrl: config.baseUrl.toString(),
      serverConfig: ServerConfig.client(this),
    ),
  );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer ${await authToken()}';
    return inner.send(request);
  }

  Future<bool> canBeReached() => apiCanBeReached(inner, config);
}

class TimingOutClient({
  required final http.Client inner,
  final Duration patience = const Duration(seconds: 60),
}) extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await inner.send(request).timeout(patience);
    return http.StreamedResponse(
      response.stream.timeout(patience),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => inner.close();
}

Future<bool> apiCanBeReached(http.Client client, ApiConfig config) async {
  try {
    final result = await HealthApi(
      CustomServer(
        baseUrl: config.baseUrl.toString(),
        serverConfig: ServerConfig.client(client),
      ),
    ).healthz().timeout(const Duration(seconds: 5));
    final response = switch (result) {
      TonikSuccess(:final response) => response,
      TonikError(:final response) => response,
    };
    return response != null && response.statusCode < 400;
  } catch (error) {
    return false;
  }
}

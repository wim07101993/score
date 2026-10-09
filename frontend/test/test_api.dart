import 'package:http/http.dart' as http;
import 'package:score/config.dart';
import 'package:score/storage/api_exception.dart';
import 'package:score/storage/clients.dart';
import 'package:score_api/score_api.dart' show ProblemDetails;

/// What builds the API clients in a test: an API at an address that goes
/// nowhere, signed with [authToken] — a token that is always there unless
/// said otherwise.
ApiClientFactory testClientFactory({Future<String> Function()? authToken}) =>
    ApiClientFactory(
      config: ApiConfig(baseUrl: Uri.parse('http://nowhere/')),
      inner: http.Client(),
      authToken: authToken ?? () async => 'a-token',
    );

/// What the API answers a failure with, as much of it as a test cares about:
/// the rest is what the server fills in.
ProblemDetails testProblem(
  ErrorCode errorCode, {
  required int status,
  String detail = '',
  String? entryId,
}) => ProblemDetails(
  $type: 'about:blank',
  title: '',
  status: status,
  detail: detail,
  instance: 'urn:uuid:00000000-0000-0000-0000-000000000000',
  errorCode: errorCode,
  entryId: entryId,
);

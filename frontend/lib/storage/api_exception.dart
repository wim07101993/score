import 'package:http/http.dart' as http;
import 'package:score_api/score_api.dart'
    show ProblemDetails, ProblemDetailsErrorCodeModel;

typedef ErrorCode = ProblemDetailsErrorCodeModel;

class ApiException({
  required final String message,
  required final int? statusCode,
  required final ProblemDetails? problem,
}) implements Exception {
  factory ApiException.fromProblemDetails({
    required ProblemDetails problem,
  }) {
    return ApiException(
      message: '${problem.status}: ${problem.detail}',
      statusCode: problem.status,
      problem: problem,
    );
  }

  factory ApiException.fromUnexpectedProblemDetails({
    required ProblemDetails problem,
  }) {
    return ApiException(
      message:
          '${problem.status}: unexpected response from api: ${problem.detail}',
      statusCode: problem.status,
      problem: problem,
    );
  }

  factory ApiException.fromUnexpectedResponse({
    required http.Response response,
  }) {
    return ApiException(
      message:
          '${response.statusCode}: unexpected response from api: ${response.body}',
      statusCode: response.statusCode,
      problem: null,
    );
  }

  factory ApiException.fromSendError({
    required Object error,
  }) {
    return ApiException(
      message: 'failed to send api request: $error',
      statusCode: null,
      problem: null,
    );
  }

  ErrorCode? get errorCode => problem?.errorCode;

  String get detail => problem?.detail ?? message;

  @override
  String toString() => message;
}

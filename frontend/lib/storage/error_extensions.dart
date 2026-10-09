/// What every part of the API has in common, whichever part of the app talks to
/// it: how a failure is told apart from an answer, and what it says. How a call
/// is made, and whether the server is there at all, is in `clients.dart`.
///
/// The scores, the sets and the collections each have a client of their own,
/// because each has its own endpoints. What a failure is — and whether it is
/// worth trying again — is the same for all three, and is said once, in
/// [ApiException].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:score/storage/api_exception.dart';
import 'package:score/storage/clients.dart';
import 'package:score_api/score_api.dart' show ProblemDetails;
import 'package:tonik_util/tonik_util.dart';

extension ApiHttpResponseExtensions on http.Response {
  ProblemDetails? get problem {
    try {
      return ProblemDetails.fromJson(jsonDecode(body));
    } catch (_) {
      return null;
    }
  }
}

extension ProblemDetailsExtensions on ProblemDetails {
  ApiException toApiException() => switch (errorCode) {
    ErrorCode.endpointNotFound || ErrorCode.methodNotAllowed =>
      ApiException.fromUnexpectedProblemDetails(problem: this),
    _ => ApiException.fromProblemDetails(problem: this),
  };
}

extension TonikErrorExtensions<ApiResponse>
    on TonikError<ApiResponse, http.Response> {
  ApiException toApiException() {
    final response = this.response;
    if (response == null) {
      if (isNetworkFailure(error)) {
        return ApiException.fromSendError(error: error);
      }
      // Not the request failing but something before it — nobody signed in
      // to send it as — which is not the API's to say anything about.
      Error.throwWithStackTrace(error, stackTrace);
    }

    if (response.problem case final problem?) {
      return problem.toApiException();
    }

    return ApiException.fromUnexpectedResponse(response: response);
  }
}

/// Whether [error] is the network failing a request: nothing there, a
/// connection that dropped, or a request that stopped answering (see
/// [TimingOutClient]).
bool isNetworkFailure(Object error) =>
    error is http.ClientException ||
    error is TimeoutException ||
    error is IOException;

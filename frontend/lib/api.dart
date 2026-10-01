/// What every part of the API has in common, whichever part of the app talks to
/// it: how a call is made, how a failure is told apart from an answer and what
/// it says, and whether the server is there at all.
///
/// The scores, the sets and the collections each have a client of their own,
/// because each has its own endpoints. What a failure is — and whether it is
/// worth trying again — is the same for all three, and is said once, here.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:score/config.dart';

/// A call to the API that did not come back with what was asked for.
///
/// The status is the one http gave, and [errorCode] the one this API gives —
/// which is the one to branch on, the way the API says. Both are absent when
/// the call never reached a server at all.
class ApiException implements Exception {
  ApiException(
    this.message,
    this.status, [
    this.problem,
  ]);

  final String message;
  final int? status;

  /// The RFC 9457 body, when there was one.
  final Map<String, dynamic>? problem;

  String? get errorCode => problem?['errorCode'] as String?;

  String get detail => (problem?['detail'] as String?) ?? message;

  /// The error code that says what was written belongs to somebody else. Each
  /// part of the API has its own, and waiting does not change whose it is.
  String? get notTheOwnersCode => null;

  /// Whether the same call is worth making again later.
  ///
  /// A request the server refused to read is refused just as firmly the next
  /// time: a set naming a score that does not exist, or an address that is not
  /// an address, is not going to start being accepted because time passed.
  /// What is worth trying again is everything that says nothing about the
  /// request — the network being down, the server being unwell, a token that
  /// has run out.
  bool get isWorthRetrying {
    final status = this.status;
    if (status == null) {
      // Nothing answered, so nothing has been said about the request.
      return true;
    }
    if (errorCode != null && errorCode == notTheOwnersCode) {
      return false;
    }
    if (status == 401 || status == 403) {
      // A token that expired mid-sync, or a role that has yet to be granted:
      // both are about the caller rather than about what was written.
      return true;
    }
    return status < 400 || status >= 500;
  }

  @override
  String toString() => message;
}

/// How a part of the API says a call failed: which kind of [ApiException] it
/// throws. A constructor of one is one.
typedef ApiFailure = ApiException Function(
  String message,
  int? status, [
  Map<String, dynamic>? problem,
]);

/// Makes a call, turning a network that is not there into the same kind of
/// failure as a server that said no — one with no status, since nothing
/// answered.
Future<http.Response> callTheApi(
  Future<http.Response> Function() send,
  String what,
  ApiFailure failure,
) async {
  try {
    return await send();
  } catch (error) {
    throw failure('failed to $what: $error', null);
  }
}

/// Throws unless [response] is the API saying yes.
///
/// Only a 2xx is. A redirect answered to a write is not the write having been
/// made — nothing follows one for a PUT or a DELETE — and taken for one it
/// would drop an edit that never reached anything.
void throwUnlessOk(http.Response response, String what, ApiFailure failure) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return;
  }

  final problem = _problemIn(response);
  if (response.statusCode == 404 && problem?['errorCode'] is! String) {
    // Every 404 this API answers with says what was not found. One that does
    // not is a proxy, or a server halfway through a deploy, and says nothing
    // about what was asked for — taken for a refusal, an edit would be given
    // up on over it.
    throw failure(
      'failed to $what: 404 from something that is not the API',
      null,
    );
  }

  // What the API said, when it said something, rather than the whole body it
  // said it in: this is what a player is shown.
  final said = problem?['detail'] ?? response.body;
  throw failure(
    'failed to $what: ${response.statusCode} $said',
    response.statusCode,
    problem,
  );
}

/// The RFC 9457 body of [response], when it has one. Every failure this API
/// answers with is one; anything else came from something in between that does
/// not know about it.
Map<String, dynamic>? _problemIn(http.Response response) {
  try {
    final parsed = jsonDecode(response.body);
    return parsed is Map ? parsed.cast<String, dynamic>() : null;
  } catch (_) {
    return null;
  }
}

/// Whether [response] is the API saying there is no such thing: a 404 with
/// one of the error codes in [notFound].
///
/// A 404 that is not the API's own — a proxy's page, or a server halfway
/// through a deploy — throws, as worth trying again. Taken at its word, it
/// would count a delete as done that never reached the server, or a set as
/// gone that is not.
bool isNotThere(
  http.Response response,
  Set<String> notFound,
  String what,
  ApiFailure failure,
) {
  if (response.statusCode != 404) {
    return false;
  }
  if (notFound.contains(_problemIn(response)?['errorCode'])) {
    return true;
  }
  throw failure(
    'failed to $what: 404 from something that is not the API',
    null,
  );
}

/// The object the API answered with.
///
/// A body that is not one — the page of a proxy, or of a venue's wifi that
/// wants a password first — is not the API answering at all, and is failed
/// the way a network that is not there is: as worth trying again, rather than
/// as an answer.
Map<String, dynamic> objectIn(
  http.Response response,
  String what,
  ApiFailure failure,
) {
  final Object? parsed;
  try {
    parsed = jsonDecode(response.body);
  } catch (error) {
    throw failure('failed to $what: what answered was not the API', null);
  }
  if (parsed is! Map) {
    throw failure('failed to $what: what answered was not the API', null);
  }
  return parsed.cast<String, dynamic>();
}

/// The objects the API answered with; see [objectIn].
List<Map<String, dynamic>> objectsIn(
  http.Response response,
  String what,
  ApiFailure failure,
) {
  final Object? parsed;
  try {
    parsed = jsonDecode(response.body);
  } catch (error) {
    throw failure('failed to $what: what answered was not the API', null);
  }
  if (parsed is! List) {
    throw failure('failed to $what: what answered was not the API', null);
  }
  return [
    for (final object in parsed) (object as Map).cast<String, dynamic>(),
  ];
}

/// A client that gives up on a request that stops answering.
///
/// The health checks only say a server was there a moment ago. A venue's wifi
/// that lets them through and then swallows the next request, or a backend that
/// hangs, would otherwise leave that request waiting for good — and with it
/// everything queued behind it: the one refresh every sync shares, the provider
/// the app looks up once, the writes to a set, which go out one after another.
/// A request that times out fails the way a network that is not there does,
/// and is tried again later.
class TimingOutClient extends http.BaseClient {
  TimingOutClient(this._inner, {this.patience = const Duration(seconds: 60)});

  final http.Client _inner;

  /// How long to wait for an answer to start, and then for each part of it.
  final Duration patience;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request).timeout(patience);
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
  void close() => _inner.close();
}

/// Whether the API is there to be asked.
///
/// Answered rather than thrown about: this is asked to find out whether to
/// work from what is kept on the device, and a network that is down is the
/// very case it is asked in.
Future<bool> apiCanBeReached(http.Client client, ApiConfig config) async {
  try {
    final response = await client
        .get(config.path('healthz'))
        .timeout(const Duration(seconds: 5));
    return response.statusCode < 400;
  } catch (error) {
    return false;
  }
}

/// Writes a moment the way the API reads it: RFC 3339, in UTC, keeping the
/// milliseconds, so that a window ends exactly where it was asked to and
/// nothing that changed inside the second it was asked about falls outside it.
String apiDate(DateTime date) => date.toUtc().toIso8601String();

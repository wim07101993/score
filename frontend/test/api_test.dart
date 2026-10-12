import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:score/config.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/storage/api_exception.dart';
import 'package:score/storage/clients.dart';

/// What every call to the API has in common: a request that stops answering is
/// given up on rather than waited for, and whatever comes back that is not the
/// answer asked for is a failure that says whether it is worth trying again.
void main() {
  const patience = Duration(milliseconds: 50);

  test('gives up on a server that never answers', () async {
    final hangs = MockClient((_) => Completer<http.Response>().future);
    final client = TimingOutClient(inner: hangs, patience: patience);

    await expectLater(
      client.get(Uri.parse('https://api.test/sets')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('gives up on an answer that stops halfway', () async {
    final stalls = MockClient.streaming((request, _) async {
      final body = StreamController<List<int>>()..add([1, 2, 3]);
      return http.StreamedResponse(body.stream, 200, request: request);
    });
    final client = TimingOutClient(inner: stalls, patience: patience);

    await expectLater(
      client.get(Uri.parse('https://api.test/sets')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('a failed call through it is one worth trying again', () async {
    final hangs = MockClient((_) => Completer<http.Response>().future);
    final client = TimingOutClient(inner: hangs, patience: patience);

    final sets = SetsApi(
      clientFactory: ApiClientFactory(
        config: ApiConfig(baseUrl: Uri.parse('https://api.test/')),
        inner: client,
        authToken: () async => 'a-token',
      ),
    );

    try {
      await sets.listChanges(since: DateTime.utc(1970));
      fail('it waited');
    } on ApiException catch (error) {
      expect(error.statusCode, isNull);
      expect(error.isWorthRetrying, isTrue);
    }
  });

  group('a failure', () {
    /// What listing the sets fails with when the server answers [body].
    Future<ApiException> failureOn(
      int status,
      String body, {
      String contentType = 'application/problem+json',
    }) async {
      final sets = SetsApi(
        clientFactory: ApiClientFactory(
          config: ApiConfig(baseUrl: Uri.parse('https://api.test/')),
          inner: MockClient(
            (_) async => http.Response(
              body,
              status,
              headers: {'content-type': contentType},
            ),
          ),
          authToken: () async => 'a-token',
        ),
      );
      try {
        await sets.listChanges(since: DateTime.utc(1970));
      } on ApiException catch (error) {
        return error;
      }
      fail('it did not fail');
    }

    test("in the API's own words is what it says", () async {
      final error = await failureOn(404, _problem('set_entry_not_found', 404));

      expect(error.statusCode, 404);
      expect(error.errorCode, ErrorCode.setEntryNotFound);
      expect(error.isWorthRetrying, isFalse);
    });

    test("that is not the API's is worth trying again", () async {
      // A proxy's page, or a server halfway through a deploy.
      for (final (body, contentType) in [
        ('<html>Not Found</html>', 'text/html'),
        ('{"message":"nope"}', 'application/json'),
        // Not the whole of what the API says about a failure.
        ('{"errorCode":"set_not_found"}', 'application/problem+json'),
      ]) {
        final error = await failureOn(404, body, contentType: contentType);

        expect(error.isWorthRetrying, isTrue, reason: body);
      }
    });

    test('from a server without the endpoint has not refused anything', () async {
      // A backend older than the app, during a deploy or after a rollback: its
      // own router answers, in the API's own words, that there is no such
      // route.
      for (final (status, code) in [
        (404, 'endpoint_not_found'),
        (405, 'method_not_allowed'),
      ]) {
        final error = await failureOn(status, _problem(code, status));

        expect(error.isWorthRetrying, isTrue, reason: code);
      }
    });

    test('with an error code newer than the app is its status alone', () async {
      // The codes only ever grow: a server that has learned a new one still
      // fails the request by its status, and the app has no code to act on.
      final error = await failureOn(
        409,
        _problem('a_code_from_the_future', 409),
      );

      expect(error.statusCode, 409);
      expect(error.problem, isNull);
      expect(error.isWorthRetrying, isFalse);
    });

    test('of a yes the API does not give is worth trying again', () async {
      // A page where the answer was expected: whatever said yes, it was not
      // the API.
      final error = await failureOn(
        200,
        '<html>Welcome</html>',
        contentType: 'text/html',
      );

      expect(error.isWorthRetrying, isTrue);
    });

    test("over somebody else's set is not worth asking about again", () async {
      final error = await failureOn(403, _problem('not_set_owner', 403));

      expect(error.isNotTheOwners, isTrue);
      expect(error.isWorthRetrying, isFalse);
    });

    test('over a piece already in the collection says where it is', () async {
      final error = await failureOn(
        409,
        _problem('score_already_in_collection', 409, entryId: 'the-entry'),
      );

      expect(error.isAlreadyInTheCollection, isTrue);
      expect(error.problem?.entryId, 'the-entry');
    });
  });

  test('passes an answer that comes through', () async {
    final answers = MockClient((request) async => http.Response('[]', 200));
    final client = TimingOutClient(inner: answers, patience: patience);

    final response = await client.get(Uri.parse('https://api.test/sets'));
    expect(response.body, '[]');
  });
}

/// A failure the way the API words one.
String _problem(String errorCode, int status, {String? entryId}) => jsonEncode({
  'type': 'about:blank',
  'title': '',
  'status': status,
  'detail': errorCode.replaceAll('_', ' '),
  'instance': 'urn:uuid:00000000-0000-0000-0000-000000000000',
  'errorCode': errorCode,
  'entryId': ?entryId,
});

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:score/api.dart';

/// A request that stops answering is given up on rather than waited for: the
/// health checks passing says nothing about the request after them.
void main() {
  const patience = Duration(milliseconds: 50);

  test('gives up on a server that never answers', () async {
    final hangs = MockClient((_) => Completer<http.Response>().future);
    final client = TimingOutClient(hangs, patience: patience);

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
    final client = TimingOutClient(stalls, patience: patience);

    await expectLater(
      client.get(Uri.parse('https://api.test/sets')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('a failed call through it is one worth trying again', () async {
    final hangs = MockClient((_) => Completer<http.Response>().future);
    final client = TimingOutClient(hangs, patience: patience);

    try {
      await callTheApi(
        () => client.get(Uri.parse('https://api.test/sets')),
        'list the sets',
        ApiException.new,
      );
      fail('it waited');
    } on ApiException catch (error) {
      expect(error.status, isNull);
      expect(error.isWorthRetrying, isTrue);
    }
  });

  group('a 404', () {
    http.Response notFound(String body) => http.Response(body, 404);

    test("with the API's own code is the thing not being there", () {
      expect(
        isNotThere(
          notFound('{"errorCode":"set_not_found","detail":"no such set"}'),
          const {'set_not_found'},
          'read the set',
          ApiException.new,
        ),
        isTrue,
      );
    });

    test('from anything else is worth trying again', () {
      for (final body in ['<html>Not Found</html>', '{"message":"nope"}']) {
        expect(
          () => isNotThere(
            notFound(body),
            const {'set_not_found'},
            'delete the set',
            ApiException.new,
          ),
          throwsA(isA<ApiException>()
              .having((error) => error.status, 'status', isNull)
              .having((error) => error.isWorthRetrying, 'retried', isTrue)),
        );
      }
    });

    test('from anything else is not a write refused', () {
      expect(
        () => throwUnlessOk(
            notFound('<html>Not Found</html>'), 'save the set', ApiException.new),
        throwsA(isA<ApiException>()
            .having((error) => error.isWorthRetrying, 'retried', isTrue)),
      );
      expect(
        () => throwUnlessOk(
          notFound('{"errorCode":"set_entry_not_found"}'),
          'save the view',
          ApiException.new,
        ),
        throwsA(isA<ApiException>()
            .having((error) => error.status, 'status', 404)
            .having((error) => error.isWorthRetrying, 'retried', isFalse)),
      );
    });
  });

  test('passes an answer that comes through', () async {
    final answers = MockClient((request) async => http.Response('[]', 200));
    final client = TimingOutClient(answers, patience: patience);

    final response = await client.get(Uri.parse('https://api.test/sets'));
    expect(response.body, '[]');
  });
}

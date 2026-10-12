import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/authentication_exception.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/storage/api_exception.dart';
import 'package:score/storage/clients.dart';

/// What the sets client makes of what the server answers: the generated
/// client reads it, and every answer it can give is turned into a set, a
/// nothing, or a failure.
void main() {
  SetsApi answering(int status, Object body, {String? contentType}) => SetsApi(
    clientFactory: ApiClientFactory(
      config: ApiConfig(baseUrl: Uri.parse('https://api.test/')),
      inner: MockClient(
        (_) async => http.Response(
          body is String ? body : jsonEncode(body),
          status,
          headers: {
            'content-type':
                contentType ??
                (status < 300
                    ? 'application/json'
                    : 'application/problem+json'),
          },
        ),
      ),
      authToken: () async => 'a-token',
    ),
  );

  Matcher failure({required int? status}) => throwsA(
    isA<ApiException>().having((error) => error.statusCode, 'status', status),
  );

  test('a set that is there is read', () async {
    final api = answering(200, _set);

    expect((await api.getSet('the-set'))?.title, 'Zomerbar');
  });

  test('a song with no score is read as having none', () async {
    final api = answering(200, {
      ..._set,
      'entries': [
        {
          'id': 'paper',
          'position': 0,
          'score_id': null,
          'description': 'Blue Bossa',
          'transposition': 0,
          'view': {'transposition': 0, 'hidden_parts': <String>[], 'zoom': 1},
        },
      ],
    });

    final entry = (await api.getSet('the-set'))!.entries.single;
    expect(entry.scoreId, isNull);
  });

  test('a set the API says is not there is nothing', () async {
    final api = answering(404, _problem('set_not_found', 404));

    expect(await api.getSet('the-set'), isNull);
  });

  test("a 404 that is not the API's is a failure by its status", () async {
    final api = answering(
      404,
      '<html>Not Found</html>',
      contentType: 'text/html',
    );

    await expectLater(
      api.getSet('the-set'),
      failure(status: 404),
    );
  });

  test('a server without the endpoint has not refused anything', () async {
    final api = answering(404, _problem('endpoint_not_found', 404));

    await expectLater(
      api.deleteSet('the-set'),
      failure(status: 404),
    );
  });

  test('deleting a set that is gone already is done', () async {
    final api = answering(404, _problem('set_not_found', 404));

    await api.deleteSet('the-set');
  });

  test("somebody else's set is refused for good", () async {
    final api = answering(403, _problem('not_set_owner', 403));

    await expectLater(
      api.putSet('the-set', {
        'title': 'Zomerbar',
        'description': '',
        'shared_with': <String>[],
      }),
      failure(status: 403),
    );
  });

  test('a failure in words this app does not know keeps its status', () async {
    final api = answering(409, _problem('a_code_from_the_future', 409));

    await expectLater(
      api.getSet('the-set'),
      failure(status: 409),
    );
  });

  test('every request is signed with the token of the moment', () async {
    final sent = <String?>[];
    var token = 'first';
    final api = SetsApi(
      clientFactory: ApiClientFactory(
        config: ApiConfig(baseUrl: Uri.parse('https://api.test/')),
        inner: MockClient((request) async {
          sent.add(request.headers['Authorization']);
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        authToken: () async => token,
      ),
    );

    await api.listChanges(since: DateTime.utc(1970));
    token = 'second';
    await api.listChanges(since: DateTime.utc(1970));

    expect(sent, ['Bearer first', 'Bearer second']);
  });

  test('nobody signed in is not the network failing', () async {
    // The generated client catches whatever goes wrong in a request, and the
    // token is asked for in the middle of one.
    final api = SetsApi(
      clientFactory: ApiClientFactory(
        config: ApiConfig(baseUrl: Uri.parse('https://api.test/')),
        inner: MockClient((_) => fail('nothing is sent')),
        authToken: () async => throw const SignInRequired(),
      ),
    );

    await expectLater(
      api.listChanges(since: DateTime.utc(1970)),
      throwsA(isA<SignInRequired>()),
    );
  });

  test('a set deleted there is listed as only its id', () async {
    final api = answering(200, [
      _set,
      {'id': 'gone', 'deleted_at': '2026-09-01T00:00:00Z'},
    ]);

    final changes = await api.listChanges(since: DateTime.utc(1970));

    expect(changes.changed.single.id, 'the-set');
    expect(changes.deleted.single.id, 'gone');
    expect(changes.deleted.single.deletedAt, DateTime.utc(2026, 9));
  });

  test('nothing answering is a failure with no status', () async {
    final api = SetsApi(
      clientFactory: ApiClientFactory(
        config: ApiConfig(baseUrl: Uri.parse('https://api.test/')),
        inner: MockClient((_) => throw http.ClientException('offline')),
        authToken: () async => 'a-token',
      ),
    );

    await expectLater(
      api.listChanges(since: DateTime.utc(1970)),
      failure(status: null),
    );
  });
}

final _set = {
  'id': 'the-set',
  'title': 'Zomerbar',
  'description': '',
  'entries': <Object>[],
  'is_owner': true,
  'shared_with': <String>[],
  'last_changed_at': '2026-02-01T00:00:00Z',
};

/// A failure the way the API words one.
Map<String, Object?> _problem(String errorCode, int status) => {
  'type': 'about:blank',
  'title': '',
  'status': status,
  'detail': errorCode.replaceAll('_', ' '),
  'instance': 'urn:uuid:00000000-0000-0000-0000-000000000000',
  'errorCode': errorCode,
};

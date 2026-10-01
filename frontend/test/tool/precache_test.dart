import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/precache.dart';

/// What the web app keeps for use without a network, and how a new release
/// reaches a browser that already has it.

void main() {
  late Directory build;

  setUp(() {
    build = Directory.systemTemp.createTempSync('precache');
    void write(String path, String content) =>
        File(p.join(build.path, path))
          ..createSync(recursive: true)
          ..writeAsStringSync(content);

    write('index.html', '<html></html>');
    write('main.dart.js', 'main();');
    write('flutter_bootstrap.js', '{"useLocalCanvasKit":true}; load();');
    write('assets/assets/config.json', '{}');
    write('assets/NOTICES', 'every licence there is');
    write('canvaskit/canvaskit.js', 'ck');
    write('canvaskit/canvaskit.wasm', 'ck');
    write('canvaskit/canvaskit.js.symbols', 'debugger only');
    write('canvaskit/chromium/canvaskit.js', 'ck');
    write('canvaskit/chromium/canvaskit.wasm', 'ck');
    write('canvaskit/skwasm.wasm', 'wasm builds only');
    write('canvaskit/webparagraph/canvaskit.wasm', 'opt-in only');
    write('flutter_service_worker.js', "Flutter's own");
    write('service-worker.js', "const RESOURCES = {};\nconst VERSION = '';\n");
    write('.last_build_id', 'x');
  });

  tearDown(() => build.deleteSync(recursive: true));

  test('keeps what the app loads, and nothing it does not', () {
    expect(resourcesOf(build).keys, [
      'assets/assets/config.json',
      'canvaskit/canvaskit.js',
      'canvaskit/canvaskit.wasm',
      'canvaskit/chromium/canvaskit.js',
      'canvaskit/chromium/canvaskit.wasm',
      'flutter_bootstrap.js',
      'index.html',
      'main.dart.js',
    ]);
  });

  test('hashes what is in each file the way the worker checks it', () {
    expect(
      resourcesOf(build)['main.dart.js'],
      sha256.convert(utf8.encode('main();')).toString(),
    );
  });

  test('tells the worker what to keep, as often as it is run', () {
    final worker = File(p.join(build.path, 'service-worker.js'));
    final resources = resourcesOf(build);

    final once = fillIn(worker.readAsStringSync(), resources);
    final twice = fillIn(once, resources);

    expect(once, contains('"main.dart.js":"'));
    expect(
      once,
      contains(
        'const VERSION = "${versionOf(resources, worker: worker.readAsStringSync())}";',
      ),
    );
    expect(twice, once);
  });

  test('a release that changed anything is a worker that changed', () {
    final before = versionOf(resourcesOf(build));
    File(p.join(build.path, 'main.dart.js')).writeAsStringSync('main(2);');

    expect(versionOf(resourcesOf(build)), isNot(before));
  });

  test('a release that changed only the worker is a new version', () {
    const before = "const RESOURCES = {};\nconst VERSION = '';\nkeep();\n";
    const after = "const RESOURCES = {};\nconst VERSION = '';\nkeepBetter();\n";
    final resources = resourcesOf(build);

    expect(versionOf(resources, worker: after),
        isNot(versionOf(resources, worker: before)));
    // Filling it in does not change what it is a version of.
    expect(versionOf(resources, worker: fillIn(before, resources)),
        versionOf(resources, worker: before));
  });

  test('refuses a build that draws with a renderer from the CDN', () {
    expect(problemWith(build), isNull);
    File(p.join(build.path, 'flutter_bootstrap.js'))
        .writeAsStringSync('{"useLocalCanvasKit":false}; load();');
    expect(problemWith(build), contains('--no-web-resources-cdn'));
  });

  test('refuses a worker it has nowhere to write into', () {
    expect(
      () => fillIn('self.addEventListener("fetch", () => {});', {}),
      throwsFormatException,
    );
  });
}

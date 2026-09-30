/// Tells the web app's service worker which files to keep for use without a
/// network, and what is in each of them.
///
/// Run once `flutter build web` has run:
///
///     flutter build web --release --no-web-resources-cdn
///     dart run tool/precache.dart
///
/// It writes the list into the copy of web/service-worker.js the build left in
/// build/web. The hashes are what makes a new release reach a device: a build
/// that changed anything is a service worker that changed, which is what a
/// browser checks for, and the files that did not change are copied over from
/// what the device already has rather than fetched again.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) {
  final root = Directory(arguments.isEmpty ? 'build/web' : arguments.single);
  final worker = File(p.join(root.path, 'service-worker.js'));
  if (!worker.existsSync()) {
    stderr.writeln('There is no ${worker.path}. Build the web app first:'
        ' flutter build web --release --no-web-resources-cdn');
    exitCode = 1;
    return;
  }

  final problem = problemWith(root);
  if (problem != null) {
    stderr.writeln(problem);
    exitCode = 1;
    return;
  }

  final resources = resourcesOf(root);
  worker.writeAsStringSync(fillIn(worker.readAsStringSync(), resources));
  stdout.writeln('${resources.length} files are kept for use without a'
      ' network.');
}

/// Why the build in [root] cannot be kept for use without a network, or null
/// when it can.
///
/// A build that loads its renderer from Google's CDN has every file of the app
/// on the device but the one that draws it, and opens on a blank page with no
/// network.
String? problemWith(Directory root) {
  final bootstrap = File(p.join(root.path, 'flutter_bootstrap.js'));
  if (!bootstrap.existsSync() ||
      !bootstrap.readAsStringSync().contains('"useLocalCanvasKit":true')) {
    return 'The build in ${root.path} loads CanvasKit from the CDN, so it'
        ' cannot start without a network. Build it with'
        ' --no-web-resources-cdn.';
  }
  return null;
}

/// Every file of the build the app can ask for, by where it is in the build,
/// with the SHA-256 of what is in it: the worker checks every file it fetches
/// against it, so that a file answered by the wrong version of the server (or
/// by index.html, for a file it does not have) is not kept as this one.
Map<String, String> resourcesOf(Directory root) {
  final files = <String, String>{};
  for (final file in root.listSync(recursive: true).whereType<File>()) {
    final path = p
        .split(p.relative(file.path, from: root.path))
        .join('/');
    if (isKept(path)) {
      files[path] = sha256.convert(file.readAsBytesSync()).toString();
    }
  }
  return {
    for (final path in files.keys.toList()..sort()) path: files[path]!,
  };
}

/// Whether a file of the build is one the app can ask for.
///
/// Left out are the service workers themselves, what only a debugger reads,
/// and the renderers only a WebAssembly build or an opt-in loads — the
/// JavaScript build loads `canvaskit/` or `canvaskit/chromium/`, depending on
/// the browser, and nothing else in there. So are the licences of the
/// packages, which nothing in the app shows and which are a megabyte and a
/// half on their own.
bool isKept(String path) {
  final name = path.split('/').last;
  if (name.startsWith('.') ||
      name.endsWith('.symbols') ||
      path == 'service-worker.js' ||
      path == 'flutter_service_worker.js' ||
      path == 'assets/NOTICES') {
    return false;
  }
  if (path.startsWith('canvaskit/')) {
    return path == 'canvaskit/canvaskit.js' ||
        path == 'canvaskit/canvaskit.wasm' ||
        path == 'canvaskit/chromium/canvaskit.js' ||
        path == 'canvaskit/chromium/canvaskit.wasm';
  }
  return true;
}

/// What changes whenever any file that is kept does, or the [worker] itself.
///
/// The worker counts too: a release that changed only how it keeps the app
/// would otherwise be installed under the name of the cache it is replacing,
/// find nothing in it to copy from, and fetch the whole app again over it.
String versionOf(Map<String, String> resources, {String worker = ''}) {
  final code = worker
      .replaceFirst(_resourcesLine, '')
      .replaceFirst(_versionLine, '');
  return md5.convert(utf8.encode('${jsonEncode(resources)}\n$code')).toString();
}

final _resourcesLine = RegExp(r'^const RESOURCES = .*;$', multiLine: true);
final _versionLine = RegExp(r'^const VERSION = .*;$', multiLine: true);

/// The service worker [worker], told to keep [resources].
///
/// Written over whatever it was told before, so running this twice on the same
/// build is the same as running it once.
String fillIn(String worker, Map<String, String> resources) {
  if (!_resourcesLine.hasMatch(worker) || !_versionLine.hasMatch(worker)) {
    throw const FormatException(
      'the service worker has no `const RESOURCES = …;` and'
      ' `const VERSION = …;` lines to fill in',
    );
  }
  return worker
      .replaceFirst(_resourcesLine, 'const RESOURCES = ${jsonEncode(resources)};')
      .replaceFirst(
        _versionLine,
        'const VERSION = ${jsonEncode(versionOf(resources, worker: worker))};',
      );
}

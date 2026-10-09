/// Runs one sync of a kind at a time.
///
/// Every page that opens asks for the syncs it shows, and a link into a song
/// of a set opens four of them at once — each of which would otherwise list
/// the same changes and fetch the same documents side by side. One asked for
/// while one is running goes once after it, however many ask: what it reads
/// may have changed after the running one read it.
class OneAtATime() {
  /// The sync of each kind that is running, and the one to run after it.
  final Map<String, Future<void>> _running = {};
  final Map<String, Future<void>> _next = {};

  Future<void> call(String kind, Future<void> Function() sync) {
    final running = _running[kind];
    if (running == null) {
      // A block body, not an arrow: `remove` hands back the future it removes,
      // which is this one, and a whenComplete that returns it waits on itself.
      return _running[kind] = sync().whenComplete(() {
        _running.remove(kind);
      });
    }
    return _next[kind] ??= running.then((_) {
      _next.remove(kind);
      return call(kind, sync);
    });
  }
}

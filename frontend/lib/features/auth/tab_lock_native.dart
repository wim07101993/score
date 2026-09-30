Future<T> platformUnderTabLock<T>(String name, Future<T> Function() body) =>
    body();

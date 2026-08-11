import 'package:flutter/material.dart';

/// What is on screen while the app works out what it has.
///
/// It is only ever there for as long as it takes to open a database, which on a
/// device with a few hundred scores is not nothing — and on the web it is there
/// while the browser is already pointing at a particular score, which is what
/// makes it more than a spinner.
class Starting extends StatelessWidget {
  const Starting({
    super.key,
    required this.theme,
    required this.darkTheme,
    this.failure,
  });

  final ThemeData theme;
  final ThemeData darkTheme;

  /// What went wrong, when what went wrong is that the app could not start.
  final Object? failure;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      // This is one screen, but the address it is started at is whatever the
      // browser was pointed at — a link straight to a score, most of the time.
      // Left to itself a navigator builds a page for every prefix of that
      // address, finds that this screen has no `/scores`, and says so:
      //
      //     Could not navigate to initial route.
      //
      // Which is a complaint about the screen that says "starting", not about
      // the app that replaces it a moment later. The answer is that while there
      // is nothing to show yet, every address shows the same nothing.
      onGenerateInitialRoutes: (initial) => [
        MaterialPageRoute<void>(
          settings: RouteSettings(name: initial),
          builder: _screen,
        ),
      ],
      // Not `home`, which a navigator may not be given alongside a stack to
      // start on. Every address leads here anyway.
      onGenerateRoute: (settings) =>
          MaterialPageRoute<void>(settings: settings, builder: _screen),
    );
  }

  Widget _screen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: failure == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    const Text('The app could not start.'),
                    const SizedBox(height: 8),
                    Text('$failure', textAlign: TextAlign.center),
                  ],
                ),
              ),
      ),
    );
  }
}

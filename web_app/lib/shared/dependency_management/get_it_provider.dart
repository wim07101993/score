import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class GetItProvider extends InheritedWidget {
  const GetItProvider({
    required super.child,
    required this.getIt,
  });

  final GetIt getIt;

  @override
  bool updateShouldNotify(GetItProvider oldWidget) {
    return oldWidget.getIt != getIt;
  }

  static GetIt? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GetItProvider>()?.getIt;
  }

  static GetIt of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No get-it found in context');
    return result!;
  }
}

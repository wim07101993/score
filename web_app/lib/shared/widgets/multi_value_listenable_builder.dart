import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:score/shared/multi_value_listenable.dart';

class MultiValueListenableBuilder<T> extends StatefulWidget {
  const MultiValueListenableBuilder({
    super.key,
    required this.valueListenables,
    required this.builder,
  });

  final List<ValueListenable<T>> valueListenables;
  final ValueWidgetBuilder<List<T>> builder;

  @override
  State<MultiValueListenableBuilder<T>> createState() =>
      _MultiValueListenableBuilderState<T>();
}

class _MultiValueListenableBuilderState<T>
    extends State<MultiValueListenableBuilder<T>> {
  late MultiValueListenable<T> multiValueListenable;

  @override
  void initState() {
    super.initState();
    multiValueListenable = MultiValueListenable(widget.valueListenables);
  }

  @override
  void didUpdateWidget(covariant MultiValueListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    multiValueListenable.dispose();
    multiValueListenable = MultiValueListenable(widget.valueListenables);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<T>>(
      valueListenable: multiValueListenable,
      builder: widget.builder,
    );
  }
}

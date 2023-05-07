import 'package:flutter/material.dart';

class ListenableBuilder<T extends Listenable> extends StatefulWidget {
  const ListenableBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.child,
  });

  final T listenable;

  final ValueWidgetBuilder<T> builder;

  final Widget? child;

  @override
  State<StatefulWidget> createState() => _ValueListenableBuilderState<T>();
}

class _ValueListenableBuilderState<T extends Listenable>
    extends State<ListenableBuilder<T>> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_valueChanged);
      widget.listenable.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.listenable, widget.child);
  }
}

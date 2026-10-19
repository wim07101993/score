import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// On the stand the score is all there is: the bars a device draws over the
/// top and the bottom of the screen are lines of music not shown. They come
/// back with a swipe from the edge, and for good once the stand is closed.
class const ImmersiveStand({
  super.key,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<ImmersiveStand> createState() => _ImmersiveStandState();
}

class _ImmersiveStandState extends State<ImmersiveStand> {
  static int _stands = 0;

  @override
  void initState() {
    super.initState();
    if (_stands++ == 0) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    if (--_stands == 0) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A snack bar that says something went wrong.
///
/// Up longer than one that says something went right: what went wrong is
/// usually a sentence or two, often with what the server said tacked on, and
/// four seconds is not enough to read it — let alone to read it out to
/// whoever can do something about it. So it can also be copied, to be pasted
/// to them as it is. It can be closed sooner.
SnackBar errorSnackBar(String message) => SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 10),
      // A snack bar with an action stays until it is closed, unless told not
      // to; this one goes after its time like any other.
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'Copy',
        onPressed: () => Clipboard.setData(ClipboardData(text: message)),
      ),
    );

import 'package:flutter/material.dart';
import 'package:score/routes.dart';

/// Opens an empty score page, which is where a new score is uploaded from.
class UploadScoreFab extends StatelessWidget {
  const UploadScoreFab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.of(context).pushNamed(AppRoute.newScore()),
      icon: const Icon(Icons.upload_file),
      label: const Text('Upload'),
    );
  }
}

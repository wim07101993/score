import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/router.dart';

/// Opens the page a new score is uploaded from.
class const UploadScoreFab({
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.router.push(const NewScoreRoute()),
      icon: const Icon(Icons.upload_file),
      label: const Text('Upload'),
    );
  }
}

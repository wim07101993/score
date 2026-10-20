import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail/perform_button.dart';

class const PaperEntryBody({
  super.key,
  required final String note,
  final VoidCallback? onPerform,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onPerform = this.onPerform;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              note,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onPerform != null) ...[
              const SizedBox(height: 16),
              PerformButton(onPressed: onPerform),
            ],
          ],
        ),
      ),
    );
  }
}

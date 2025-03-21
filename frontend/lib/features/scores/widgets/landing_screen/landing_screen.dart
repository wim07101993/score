import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

@RoutePage()
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Placeholder(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  SizedBox(
                    height: 200,
                    child: Placeholder(),
                  ),
                  SizedBox(
                    height: 200,
                    child: Placeholder(),
                  ),
                  SizedBox(
                    height: 200,
                    child: Placeholder(),
                  ),
                  SizedBox(
                    height: 200,
                    child: Placeholder(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

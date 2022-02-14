import 'package:flutter/material.dart';
import 'package:score/features/user/widgets/profile_app_bar.dart';
import 'package:score/features/user/widgets/profile_fields.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProfileAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: LayoutBuilder(builder: (context, constraints) {
              const fields = ProfileFields();
              return constraints.maxWidth <= 500
                  ? fields
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: fields,
                    );
            }),
          ),
        ),
      ),
    );
  }
}

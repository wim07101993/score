import 'package:flutter/material.dart';
import 'package:score/features/user/widgets/profile_fields.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }
}

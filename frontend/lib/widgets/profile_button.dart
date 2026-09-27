import 'package:flutter/material.dart';

/// The way to the profile.
///
/// Never hidden, whatever roles the user turns out to have: a user who is shown
/// nothing at all is exactly the user who needs to see why.
class ProfileButton extends StatelessWidget {
  const ProfileButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Profile',
      icon: const Icon(Icons.person_outline),
      onPressed: () => Navigator.of(context).pushNamed('/profile'),
    );
  }
}

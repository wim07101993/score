import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: TextButton(
            onPressed: () => context.read<FirebaseAuth>().signOut(),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Log out'),
            ),
          ),
        ),
      ],
    );
  }
}

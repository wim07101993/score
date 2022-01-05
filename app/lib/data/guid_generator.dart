import 'package:uuid/uuid.dart';

class GuidGenerator {
  const GuidGenerator({
    this.uuid = const Uuid(),
  });

  final Uuid uuid;

  String newGuid() {
    return uuid.v1();
  }
}

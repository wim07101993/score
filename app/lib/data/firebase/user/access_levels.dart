import 'dart:async';

import 'package:core/core.dart';

import 'user.dart';

part 'access_levels.freezed.dart';
part 'access_levels.g.dart';

@freezed
class AccessLevels with _$AccessLevels {
  const factory AccessLevels({
    @Default(false) bool application,
    @Default(false) bool admin,
  }) = _AccessLevels;

  factory AccessLevels.fromJson(Map<String, dynamic> json) =>
      _$AccessLevelsFromJson(json);
}

class AccessLevelsChanges extends ValueNotifier<AccessLevels> {
  AccessLevelsChanges({
    required UserRepository userRepository,
  }) : super(const AccessLevels()) {
    _userChangeSubscription = userRepository.changes.listen((user) {
      value = user?.accessLevels ?? const AccessLevels();
    });
  }

  StreamSubscription? _userChangeSubscription;

  @override
  void dispose() {
    _userChangeSubscription?.cancel();
    super.dispose();
  }
}

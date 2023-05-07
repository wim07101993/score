import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/shared/dependency_management/get_it_provider.dart';

extension GetItBuildContextExtensions on BuildContext {
  GetIt get getIt => GetItProvider.of(this);
}

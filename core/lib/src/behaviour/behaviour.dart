import 'package:flutter/foundation.dart';

import 'behaviour_base.dart';
import 'exception_or.dart';

abstract class Behaviour<TIn, TOut> extends BehaviourBase {
  Behaviour({
    required BehaviourDependencies dependencies,
  }) : super(dependencies);

  Future<ExceptionOr<TOut>> call(TIn input) {
    return executeAction(() async => Success(await action(input)));
  }

  @protected
  Future<TOut> action(TIn input);
}

import 'package:logging/logging.dart';
import 'package:score/features/auth/authentication_exception.dart';

class const ApiSync({
  required final Logger logger,
}) {
  Future<void> call({
    required String what,
    required Future<bool> Function() apiCanBeReached,
    required Future<void> Function() sync,
  }) async {
    if (!await apiCanBeReached()) {
      return;
    }
    try {
      logger.fine(what);
      await sync();
    } on AuthenticationException catch (error) {
      logger.info('not $what: $error');
    } catch (error, stackTrace) {
      logger.warning('failed $what', error, stackTrace);
    }
  }
}

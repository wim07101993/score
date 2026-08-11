import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Where a device keeps what this app has: a file per database, somewhere the
/// operating system will not clear out behind the user's back.
Future<Database> openDatabase(String name) async {
  final directory = await getApplicationSupportDirectory();
  return databaseFactoryIo.openDatabase(p.join(directory.path, '$name.db'));
}

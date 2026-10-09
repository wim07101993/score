import 'package:score/storage/database_factory_io.dart'
    if (dart.library.js_interop) 'package:score/storage/database_factory_web.dart';
import 'package:sembast/sembast_memory.dart';

/// Where everything this device knows is kept between visits.
///
/// A score is read on a stage, a set is edited at a gig and a piece is put into
/// the book where the book is, and all of those are exactly where there is no
/// network. So nothing waits on the API: what is stored is what is shown, and
/// the API is squared with it afterwards.
///
/// Every feature keeps its own records, in a store of its own in these
/// databases; this only opens them. They work the same on a browser and on a
/// device, so that nothing above them ever has to ask which one it is on.
class Databases._({
  /// What every feature keeps. The score files are kept apart, as files: see
  /// `ScoreDocuments`.
  required final Database data,
}) {
  static Future<Databases> open() async =>
      Databases._(data: await openDatabase('score'));

  /// A database on nothing, which is what the tests keep things in: they have
  /// neither a browser nor a device, and what they are testing is not where
  /// the bytes land.
  static Future<Databases> inMemory() async => Databases._(
    data: await newDatabaseFactoryMemory().openDatabase('score'),
  );
}

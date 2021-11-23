import 'package:core/core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

class MockBox<T> extends Mock implements Box<T> {}

class MockFirebasePerformance extends Mock implements FirebasePerformance {}

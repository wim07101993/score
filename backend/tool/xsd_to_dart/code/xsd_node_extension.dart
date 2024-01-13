import 'dart:io';

import '../xsd/restriction/restriction.dart';
import '../xsd/schema.dart';

extension XsdNodeExtension on XsdNode {
  List<String> get docs => annotation?.documentations ?? const [];

  void writeDocs(IOSink sink, {int indent = 0}) {
    final docs = this.docs;
    if (docs.isEmpty) {
      return;
    }
    for (final doc in docs.expand((doc) => doc.split('\n'))) {
      sink.write(''.padLeft(indent));
      sink.write('/// ');
      sink.writeln(doc);
    }
  }
}

extension XsdRestrictionsExtensions on List<RestrictionValueChoice> {
  MinLength? get minLength =>
      whereType<MinLengthRestrictionValue>().firstOrNull?.value;

  MinExclusive? get minExclusive =>
      whereType<MinExclusiveRestrictionValue>().firstOrNull?.value;
  MinInclusive? get minInclusive =>
      whereType<MinInclusiveRestrictionValue>().firstOrNull?.value;
  MaxInclusive? get maxInclusive =>
      whereType<MaxInclusiveRestrictionValue>().firstOrNull?.value;
  PatternRestriction? get pattern =>
      whereType<PatternRestrictionValue>().firstOrNull?.value;

  Iterable<Enumeration> get enumerations =>
      whereType<EnumeratedRestrictionValue>().map((e) => e.value);
}

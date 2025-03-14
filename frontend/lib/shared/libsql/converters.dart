DateTime sqlStringToDateTime(String str) {
  return DateTime.parse(str.replaceAll(' ', 'T'));
}

String dateTimeToSqlDateTime(DateTime dt) {
  return dt.toIso8601String().replaceAll('T', ' ');
}

import 'package:drift/drift.dart';

String _toSnakeCase(String camel) {
  final buf = StringBuffer();
  for (var i = 0; i < camel.length; i++) {
    final ch = camel[i];
    final lower = ch.toLowerCase();
    if (ch != lower && i > 0) buf.write('_');
    buf.write(lower);
  }
  return buf.toString();
}

class SnakeEnumConverter<T extends Enum> extends TypeConverter<T, String> {
  const SnakeEnumConverter(this.values);

  final List<T> values;

  @override
  T fromSql(String fromDb) =>
      values.firstWhere((v) => _toSnakeCase(v.name) == fromDb);

  @override
  String toSql(T value) => _toSnakeCase(value.name);
}

/// Parsers tolerantes na borda da API de check-in (sem `as String` cego).
String? checkinJsonString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String checkinJsonStringOr(dynamic value, [String fallback = '']) =>
    checkinJsonString(value) ?? fallback;

int? checkinJsonInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

int checkinJsonIntOr(dynamic value, [int fallback = 0]) =>
    checkinJsonInt(value) ?? fallback;

double? checkinJsonDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final text = value.toString().trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

bool checkinJsonBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'sim') return true;
  if (text == 'false' || text == '0' || text == 'nao' || text == 'não') {
    return false;
  }
  return fallback;
}

Map<String, dynamic>? checkinJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> checkinJsonMapList(dynamic value) {
  if (value is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final item in value) {
    final map = checkinJsonMap(item);
    if (map != null) out.add(map);
  }
  return out;
}

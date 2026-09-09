import '../../../core/utils/fx_utils.dart';

String evolucaoFotosCountLabel(int count) {
  if (count <= 0) return 'Nenhuma foto';
  if (count == 1) return '1 foto';
  return '$count fotos';
}

String evolucaoFotosDateLabel(String data) {
  final parsed = DateTime.tryParse(data);
  if (parsed != null) return fxDateShort(parsed);
  return data.length >= 10 ? data.substring(0, 10) : data;
}

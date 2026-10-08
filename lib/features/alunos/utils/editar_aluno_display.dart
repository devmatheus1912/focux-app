import '../../dashboard/utils/birth_date_api_format.dart';

export 'add_aluno_display.dart'
    show
        addAlunoEmailValido,
        addAlunoNomeMax,
        addAlunoEmailMax,
        addAlunoObjetivoMax,
        addAlunoFirstName;

const editarAlunoTelefoneMax = 20;

String editarAlunoHubSubtitle() => 'Perfil do aluno';

String editarAlunoSalvarTooltip() => 'Salvar';

String editarAlunoConfirmTitle(String firstName) => 'Salvar $firstName?';

String editarAlunoConfirmMessage() =>
    'Nome, contato e perfil entram no 360 e na prescrição.';

String editarAlunoConfirmLabel() => 'Salvar';

/// Altura digitada em cm (100–250). Vazio é válido: o campo é opcional.
bool editarAlunoAlturaValida(String? raw) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return true;
  final cm = int.tryParse(v);
  return cm != null && cm >= 100 && cm <= 250;
}

int? editarAlunoAlturaCm(String raw) => int.tryParse(raw.trim());

/// Aceita DD-MM-AAAA, DD/MM/AAAA ou DDMMAAAA; data real e no passado.
bool editarAlunoNascimentoValido(String? raw) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return true;
  final iso = normalizeBirthDateForApi(v);
  final data = iso == null ? null : DateTime.tryParse(iso);
  if (data == null) return false;
  final partes = iso!.split('-');
  if (data.month != int.parse(partes[1]) || data.day != int.parse(partes[2])) {
    return false;
  }
  final hoje = DateTime.now();
  return data.isBefore(hoje) && data.year >= hoje.year - 110;
}

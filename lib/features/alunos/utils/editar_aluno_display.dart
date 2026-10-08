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

/// Altura digitada em cm (100–250). Vazio só vale se ainda não havia valor:
/// o backend ignora campo vazio, então apagar não teria efeito.
bool editarAlunoAlturaValida(String? raw, {bool obrigatorio = false}) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return !obrigatorio;
  final cm = int.tryParse(v);
  return cm != null && cm >= 100 && cm <= 250;
}

/// O app guarda altura em metros (modelo, 360 e perfil do aluno).
double? editarAlunoAlturaMetros(String raw) {
  final cm = int.tryParse(raw.trim());
  return cm == null ? null : cm / 100;
}

/// Aceita DD-MM-AAAA, DD/MM/AAAA ou DDMMAAAA; data real e no passado.
bool editarAlunoNascimentoValido(String? raw, {bool obrigatorio = false}) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return !obrigatorio;
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

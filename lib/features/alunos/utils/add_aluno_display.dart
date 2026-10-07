const addAlunoEmailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';

const addAlunoNomeMax = 150;
const addAlunoEmailMax = 255;
const addAlunoObjetivoMax = 300;

const addAlunoGeneros = ['Masculino', 'Feminino', 'Outro'];

const addAlunoTiposConsultoria = ['ONLINE', 'PRESENCIAL', 'HIBRIDO'];

const addAlunoTiposConsultoriaLabel = ['Online', 'Presencial', 'Híbrido'];

const addAlunoObjetivosRapidos = [
  'Hipertrofia',
  'Emagrecimento',
  'Força',
  'Condicionamento',
];

String addAlunoHubSubtitle() => 'Cadastro rápido';

String addAlunoSalvarTooltip() => 'Cadastrar';

bool addAlunoEmailValido(String raw) =>
    RegExp(addAlunoEmailPattern).hasMatch(raw.trim());

String addAlunoFirstName(String nome) {
  final value = nome.trim();
  if (value.isEmpty) return 'Aluno';
  return value.split(RegExp(r'\s+')).first;
}

String addAlunoConfirmTitle(String firstName) => 'Cadastrar $firstName?';

String addAlunoConfirmMessage({required bool hasWhatsapp}) {
  if (hasWhatsapp) {
    return 'O aluno entra na lista e recebe um link para criar a senha. O convite abre pronto no WhatsApp.';
  }
  return 'O aluno entra na lista e recebe um link para criar a senha. Você copia o convite em seguida.';
}

String addAlunoConfirmLabel() => 'Cadastrar';

String addAlunoAfterSubmitCopy({
  required String firstName,
  required bool hasWhatsapp,
}) {
  if (hasWhatsapp) {
    return '$firstName entra na lista e o link de acesso fica pronto no WhatsApp.';
  }
  return '$firstName entra na lista. Você copia o link de acesso.';
}

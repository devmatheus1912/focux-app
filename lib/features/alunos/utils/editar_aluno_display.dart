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

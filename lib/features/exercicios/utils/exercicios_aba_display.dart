import '../data/exercicio_repository.dart';
import '../screens/widgets/exercise_media_thumb.dart';
import 'biblioteca_aba.dart';

/// Escolha no topo da aba Exercícios (20/11): Meus · Biblioteca · Favoritos.
enum ExerciciosAba { meus, biblioteca, favoritos }

String exerciciosAbaRotulo(ExerciciosAba aba) => switch (aba) {
  ExerciciosAba.meus => 'Meus',
  ExerciciosAba.biblioteca => 'Biblioteca',
  ExerciciosAba.favoritos => 'Favoritos',
};

/// Valor de `aba` no `GET /api/exercicios/v2`. Favoritos busca nas duas.
String? exerciciosAbaParam(ExerciciosAba aba) => switch (aba) {
  ExerciciosAba.meus => 'MEUS',
  ExerciciosAba.biblioteca => 'FOCUX',
  ExerciciosAba.favoritos => null,
};

/// Subtítulo do topo: "3 seus · 492 da biblioteca"; com busca ou filtro,
/// quantos sobraram ("12 exercícios"). Contagem ainda não carregada some.
String? exerciciosResumoTopo({
  required int? meus,
  required int? biblioteca,
  required bool filtrando,
  required int totalFiltrado,
}) {
  if (filtrando) return exerciciosQuantos(totalFiltrado);
  if (meus == null || biblioteca == null) return null;
  final seus = meus == 1 ? '1 seu' : '$meus seus';
  return '$seus · $biblioteca da biblioteca';
}

String exerciciosQuantos(int n) =>
    n <= 0
        ? 'Nenhum exercício'
        : n == 1
        ? '1 exercício'
        : '$n exercícios';

/// Ações do "⋯" de um exercício.
enum ExercicioAcao { assistir, video, editar, duplicar, excluir }

/// O que o "⋯" oferece: exercício da biblioteca intocado só se assiste e se
/// copia; o do personal (ou com vídeo dele) também troca vídeo, edita e exclui.
List<ExercicioAcao> exercicioAcoesDisponiveis(Exercicio e) => [
  if (e.hasPlayableMedia) ExercicioAcao.assistir,
  if (!videoFocuxIntocado(e)) ExercicioAcao.video,
  if (!videoFocuxIntocado(e)) ExercicioAcao.editar,
  ExercicioAcao.duplicar,
  if (!videoFocuxIntocado(e)) ExercicioAcao.excluir,
];

String exercicioAcaoRotulo(ExercicioAcao a, Exercicio e) => switch (a) {
  ExercicioAcao.assistir => 'Assistir vídeo',
  ExercicioAcao.video =>
    exercicioHasPersonalVideo(e) ? 'Trocar vídeo' : 'Enviar vídeo',
  ExercicioAcao.editar => 'Editar',
  ExercicioAcao.duplicar =>
    videoFocuxIntocado(e) ? 'Criar o meu a partir deste' : 'Duplicar',
  ExercicioAcao.excluir => 'Excluir',
};

/// Excluir só sai quando nenhuma ficha usa (o servidor recusa). Com fichas,
/// a folha vira aviso com a contagem; sem, confirma dizendo o efeito.
String exercicioExcluirTitulo(int fichas) =>
    fichas > 0 ? 'Este exercício está em uso' : 'Excluir exercício?';

String exercicioExcluirMensagem(int fichas) =>
    fichas <= 0
        ? 'Sai da sua lista. Nenhuma ficha usa este exercício.'
        : fichas == 1
        ? 'Está em 1 ficha. Tire da ficha antes de excluir.'
        : 'Está em $fichas fichas. Tire das fichas antes de excluir.';

/// "Meus" vazio, sem busca nem filtro.
const exerciciosMeusVazioTitulo = 'Crie exercícios com o seu vídeo';
const exerciciosMeusVazioApoio =
    'O aluno vê a sua demonstração no treino, no lugar da da Focux.';

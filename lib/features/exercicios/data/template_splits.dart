import 'enums.dart';

class TemplateSlot {
  final String label;
  final PadraoMovimento? padrao;
  final GrupoMuscular? grupo;

  const TemplateSlot.padrao(this.padrao, this.label) : grupo = null;
  const TemplateSlot.grupo(this.grupo, this.label) : padrao = null;
}

class TemplateDia {
  final String nome;
  final List<TemplateSlot> slots;

  const TemplateDia({required this.nome, required this.slots});
}

/// Agrupa modelos pela agenda do aluno — como o personal escolhe no dia a dia.
enum TemplateSplitGroup {
  ate3Dias,
  quatroDias,
  cincoSeisDias,
  foco,
}

extension TemplateSplitGroupX on TemplateSplitGroup {
  String get header => switch (this) {
    TemplateSplitGroup.ate3Dias => '2–3 dias na semana',
    TemplateSplitGroup.quatroDias => '4 dias na semana',
    TemplateSplitGroup.cincoSeisDias => '5–6 dias na semana',
    TemplateSplitGroup.foco => 'Foco do aluno',
  };

  String get caption => switch (this) {
    TemplateSplitGroup.ate3Dias =>
      'Iniciante, rotina apertada ou retorno pós-pausa',
    TemplateSplitGroup.quatroDias =>
      'Melhor equilíbrio volume × recuperação (mais pedido em 2025–26)',
    TemplateSplitGroup.cincoSeisDias =>
      'Hipertrofia com frequência alta — ABC e PPL nas academias BR',
    TemplateSplitGroup.foco => 'Quando o objetivo é um grupo ou contexto específico',
  };
}

class TemplateSplit {
  final String id;
  final String nome;
  final String descricao;
  final TemplateSplitGroup grupo;
  final int diasSemana;
  final List<TemplateDia> dias;

  const TemplateSplit({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.grupo,
    required this.diasSemana,
    required this.dias,
  });

  int get slotsCount =>
      dias.fold<int>(0, (sum, day) => sum + day.slots.length);
}

/// Catálogo BR — ordenado pelo que o personal monta primeiro (frequência do aluno).
/// Fontes de prioridade: academias BR (ABC/Full body), ciência de frequência
/// (full body 2–3x, upper/lower 4x, PPL 5–6x) e demanda de foco inferior.
const templateSplits = <TemplateSplit>[
  // ── 2–3 dias ──────────────────────────────────────────────────────────
  TemplateSplit(
    id: 'fullbody-iniciante',
    nome: 'Full body',
    descricao: 'Corpo inteiro em cada sessão — base do iniciante',
    grupo: TemplateSplitGroup.ate3Dias,
    diasSemana: 3,
    dias: [
      TemplateDia(
        nome: 'A',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento'),
          TemplateSlot.padrao(
            PadraoMovimento.pushHorizontal,
            'Supino / empurrar',
          ),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Remada / puxar'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior de quadril'),
          TemplateSlot.padrao(PadraoMovimento.coreAntiExtensao, 'Core'),
        ],
      ),
    ],
  ),
  TemplateSplit(
    id: 'fullbody-ab',
    nome: 'Full body A/B',
    descricao: 'Dois dias alternados com mais volume por sessão',
    grupo: TemplateSplitGroup.ate3Dias,
    diasSemana: 3,
    dias: [
      TemplateDia(
        nome: 'A',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento principal'),
          TemplateSlot.padrao(
            PadraoMovimento.pushHorizontal,
            'Supino / empurrar',
          ),
          TemplateSlot.padrao(
            PadraoMovimento.pullHorizontal,
            'Remada horizontal',
          ),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior de quadril'),
          TemplateSlot.grupo(GrupoMuscular.ombroLateral, 'Ombro lateral'),
          TemplateSlot.padrao(PadraoMovimento.coreAntiExtensao, 'Core'),
        ],
      ),
      TemplateDia(
        nome: 'B',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.lunge, 'Avanço / unilateral'),
          TemplateSlot.padrao(PadraoMovimento.pushVertical, 'Desenvolvimento'),
          TemplateSlot.padrao(PadraoMovimento.pullVertical, 'Puxada vertical'),
          TemplateSlot.grupo(GrupoMuscular.gluteo, 'Glúteo'),
          TemplateSlot.grupo(GrupoMuscular.panturrilha, 'Panturrilha'),
          TemplateSlot.padrao(
            PadraoMovimento.coreAntiRotacao,
            'Core rotacional',
          ),
        ],
      ),
    ],
  ),
  TemplateSplit(
    id: 'casa-sem-equipo',
    nome: 'Em casa · sem equipamento',
    descricao: 'Peso corporal — aluno remoto ou viagem',
    grupo: TemplateSplitGroup.ate3Dias,
    diasSemana: 3,
    dias: [
      TemplateDia(
        nome: 'A',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Empurrar'),
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachar'),
          TemplateSlot.padrao(PadraoMovimento.lunge, 'Unilateral'),
          TemplateSlot.padrao(PadraoMovimento.coreAntiExtensao, 'Core'),
          TemplateSlot.padrao(PadraoMovimento.cardioHiit, 'Condicionamento'),
        ],
      ),
    ],
  ),

  // ── 4 dias ────────────────────────────────────────────────────────────
  TemplateSplit(
    id: 'upper-lower',
    nome: 'Superior / Inferior',
    descricao: '4x semana — equilíbrio clássico de volume e recuperação',
    grupo: TemplateSplitGroup.quatroDias,
    diasSemana: 4,
    dias: [
      TemplateDia(
        nome: 'Superior',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Peito / supino'),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Remada'),
          TemplateSlot.padrao(PadraoMovimento.pushVertical, 'Ombro'),
          TemplateSlot.padrao(PadraoMovimento.pullVertical, 'Dorsal'),
          TemplateSlot.grupo(GrupoMuscular.biceps, 'Bíceps'),
          TemplateSlot.grupo(GrupoMuscular.triceps, 'Tríceps'),
        ],
      ),
      TemplateDia(
        nome: 'Inferior',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior de quadril'),
          TemplateSlot.padrao(PadraoMovimento.lunge, 'Unilateral'),
          TemplateSlot.grupo(GrupoMuscular.gluteo, 'Glúteo'),
          TemplateSlot.grupo(GrupoMuscular.panturrilha, 'Panturrilha'),
          TemplateSlot.padrao(PadraoMovimento.coreAntiRotacao, 'Core'),
        ],
      ),
    ],
  ),

  // ── 5–6 dias ──────────────────────────────────────────────────────────
  TemplateSplit(
    id: 'bro-split',
    nome: 'ABC clássico',
    descricao: 'Peito · costas · pernas — o mais comum nas academias BR',
    grupo: TemplateSplitGroup.cincoSeisDias,
    diasSemana: 6,
    dias: [
      TemplateDia(
        nome: 'A · Peito e tríceps',
        slots: [
          TemplateSlot.padrao(
            PadraoMovimento.pushHorizontal,
            'Peito principal',
          ),
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Peito variação'),
          TemplateSlot.padrao(PadraoMovimento.pushVertical, 'Ombro anterior'),
          TemplateSlot.grupo(GrupoMuscular.triceps, 'Tríceps'),
        ],
      ),
      TemplateDia(
        nome: 'B · Costas e bíceps',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pullVertical, 'Dorsal vertical'),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Remada'),
          TemplateSlot.grupo(
            GrupoMuscular.ombroPosterior,
            'Posterior de ombro',
          ),
          TemplateSlot.grupo(GrupoMuscular.biceps, 'Bíceps'),
        ],
      ),
      TemplateDia(
        nome: 'C · Pernas e glúteo',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior'),
          TemplateSlot.padrao(PadraoMovimento.lunge, 'Unilateral'),
          TemplateSlot.grupo(GrupoMuscular.gluteo, 'Glúteo'),
          TemplateSlot.grupo(GrupoMuscular.panturrilha, 'Panturrilha'),
        ],
      ),
    ],
  ),
  TemplateSplit(
    id: 'ppl',
    nome: 'Empurrar / Puxar / Pernas',
    descricao: 'PPL — hipertrofia com 2 ciclos na semana',
    grupo: TemplateSplitGroup.cincoSeisDias,
    diasSemana: 6,
    dias: [
      TemplateDia(
        nome: 'Empurrar',
        slots: [
          TemplateSlot.padrao(
            PadraoMovimento.pushHorizontal,
            'Supino principal',
          ),
          TemplateSlot.padrao(
            PadraoMovimento.pushHorizontal,
            'Supino variação',
          ),
          TemplateSlot.padrao(PadraoMovimento.pushVertical, 'Desenvolvimento'),
          TemplateSlot.grupo(GrupoMuscular.ombroLateral, 'Lateral'),
          TemplateSlot.grupo(GrupoMuscular.triceps, 'Tríceps'),
        ],
      ),
      TemplateDia(
        nome: 'Puxar',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pullVertical, 'Puxada'),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Remada'),
          TemplateSlot.grupo(GrupoMuscular.ombroPosterior, 'Posterior'),
          TemplateSlot.grupo(GrupoMuscular.biceps, 'Bíceps'),
        ],
      ),
      TemplateDia(
        nome: 'Pernas',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior'),
          TemplateSlot.padrao(PadraoMovimento.lunge, 'Avanço'),
          TemplateSlot.grupo(GrupoMuscular.gluteo, 'Glúteo'),
          TemplateSlot.grupo(GrupoMuscular.panturrilha, 'Panturrilha'),
        ],
      ),
    ],
  ),

  // ── Foco ──────────────────────────────────────────────────────────────
  TemplateSplit(
    id: 'lower-focus',
    nome: 'Glúteo e pernas',
    descricao: 'Prioridade inferior — comum em alunas e fases de base',
    grupo: TemplateSplitGroup.foco,
    diasSemana: 2,
    dias: [
      TemplateDia(
        nome: 'Inferior A',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior principal'),
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento'),
          TemplateSlot.grupo(GrupoMuscular.gluteo, 'Glúteo isolado'),
          TemplateSlot.padrao(PadraoMovimento.lunge, 'Unilateral'),
          TemplateSlot.grupo(GrupoMuscular.abdutor, 'Abdutores'),
          TemplateSlot.grupo(GrupoMuscular.panturrilha, 'Panturrilha'),
        ],
      ),
      TemplateDia(
        nome: 'Inferior B',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento variação'),
          TemplateSlot.grupo(GrupoMuscular.quadriceps, 'Quadríceps'),
          TemplateSlot.grupo(GrupoMuscular.posteriorCoxa, 'Posterior'),
          TemplateSlot.grupo(GrupoMuscular.gluteo, 'Glúteo'),
          TemplateSlot.grupo(GrupoMuscular.adutor, 'Adutores'),
        ],
      ),
    ],
  ),
  TemplateSplit(
    id: 'torso-arms',
    nome: 'Torso e braços',
    descricao: 'Só superiores — dia sem pernas ou prioridade de tronco',
    grupo: TemplateSplitGroup.foco,
    diasSemana: 2,
    dias: [
      TemplateDia(
        nome: 'A',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Peito'),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Costas'),
          TemplateSlot.padrao(PadraoMovimento.pushVertical, 'Ombro'),
          TemplateSlot.grupo(GrupoMuscular.biceps, 'Bíceps'),
          TemplateSlot.grupo(GrupoMuscular.triceps, 'Tríceps'),
          TemplateSlot.padrao(PadraoMovimento.coreAntiRotacao, 'Core'),
        ],
      ),
    ],
  ),
  TemplateSplit(
    id: 'mobilidade-forca',
    nome: 'Mobilidade + força',
    descricao: 'Aquecimento funcional com blocos leves de força',
    grupo: TemplateSplitGroup.foco,
    diasSemana: 2,
    dias: [
      TemplateDia(
        nome: 'A',
        slots: [
          TemplateSlot.padrao(
            PadraoMovimento.mobilidadeDinamica,
            'Mobilidade dinâmica',
          ),
          TemplateSlot.padrao(PadraoMovimento.smr, 'Liberação miofascial'),
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Empurrar leve'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior controlado'),
          TemplateSlot.padrao(PadraoMovimento.coreAntiExtensao, 'Estabilidade'),
        ],
      ),
    ],
  ),
];

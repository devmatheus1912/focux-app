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

class TemplateSplit {
  final String id;
  final String nome;
  final String descricao;
  final List<TemplateDia> dias;

  const TemplateSplit({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.dias,
  });
}

/// Modelos de estrutura — apenas splits mais usados por personais (90% dos casos).
const templateSplits = <TemplateSplit>[
  TemplateSplit(
    id: 'fullbody-iniciante',
    nome: 'Full body iniciante',
    descricao: '3x semana, base simples e rápida de montar',
    dias: [
      TemplateDia(
        nome: 'A',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento'),
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Supino / empurrar'),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Remada / puxar'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior de quadril'),
          TemplateSlot.padrao(PadraoMovimento.coreAntiExtensao, 'Core'),
        ],
      ),
    ],
  ),
  TemplateSplit(
    id: 'upper-lower',
    nome: 'Upper / Lower',
    descricao: '4x semana, organização clássica por membros',
    dias: [
      TemplateDia(
        nome: 'Upper',
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
        nome: 'Lower',
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
  TemplateSplit(
    id: 'ppl',
    nome: 'Push / Pull / Legs',
    descricao: '6x semana, alto volume com divisão clara',
    dias: [
      TemplateDia(
        nome: 'Push',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Supino principal'),
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
        nome: 'Pull',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pullVertical, 'Puxada'),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Remada'),
          TemplateSlot.grupo(GrupoMuscular.ombroPosterior, 'Posterior'),
          TemplateSlot.grupo(GrupoMuscular.biceps, 'Bíceps'),
        ],
      ),
      TemplateDia(
        nome: 'Legs',
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
  TemplateSplit(
    id: 'casa-sem-equipo',
    nome: 'Casa sem equipamento',
    descricao: 'Peso corporal, bom para alunos remotos',
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
];

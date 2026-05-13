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

const templateSplits = <TemplateSplit>[
  TemplateSplit(
    id: 'fullbody-iniciante',
    nome: 'Full body iniciante',
    descricao: '3x semana, base simples e rapida de montar',
    dias: [
      TemplateDia(
        nome: 'A',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento'),
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Empurrar'),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Puxar'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior'),
          TemplateSlot.padrao(PadraoMovimento.coreAntiExtensao, 'Core'),
        ],
      ),
    ],
  ),
  TemplateSplit(
    id: 'upper-lower',
    nome: 'Upper / Lower',
    descricao: '4x semana, organizacao classica por membros',
    dias: [
      TemplateDia(
        nome: 'Upper',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Peito'),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Remada'),
          TemplateSlot.padrao(PadraoMovimento.pushVertical, 'Ombro'),
          TemplateSlot.padrao(PadraoMovimento.pullVertical, 'Dorsal'),
          TemplateSlot.grupo(GrupoMuscular.biceps, 'Biceps'),
          TemplateSlot.grupo(GrupoMuscular.triceps, 'Triceps'),
        ],
      ),
      TemplateDia(
        nome: 'Lower',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Hinge'),
          TemplateSlot.padrao(PadraoMovimento.lunge, 'Unilateral'),
          TemplateSlot.grupo(GrupoMuscular.gluteo, 'Gluteo'),
          TemplateSlot.grupo(GrupoMuscular.panturrilha, 'Panturrilha'),
          TemplateSlot.padrao(PadraoMovimento.coreAntiRotacao, 'Core'),
        ],
      ),
    ],
  ),
  TemplateSplit(
    id: 'ppl',
    nome: 'Push / Pull / Legs',
    descricao: '6x semana, alto volume com divisao clara',
    dias: [
      TemplateDia(
        nome: 'Push',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pushHorizontal, 'Supino'),
          TemplateSlot.padrao(
            PadraoMovimento.pushHorizontal,
            'Supino variacao',
          ),
          TemplateSlot.padrao(PadraoMovimento.pushVertical, 'Desenvolvimento'),
          TemplateSlot.grupo(GrupoMuscular.ombroLateral, 'Lateral'),
          TemplateSlot.grupo(GrupoMuscular.triceps, 'Triceps'),
        ],
      ),
      TemplateDia(
        nome: 'Pull',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.pullVertical, 'Puxada'),
          TemplateSlot.padrao(PadraoMovimento.pullHorizontal, 'Remada'),
          TemplateSlot.grupo(GrupoMuscular.ombroPosterior, 'Posterior'),
          TemplateSlot.grupo(GrupoMuscular.biceps, 'Biceps'),
        ],
      ),
      TemplateDia(
        nome: 'Legs',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Agachamento'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior'),
          TemplateSlot.padrao(PadraoMovimento.lunge, 'Avanco'),
          TemplateSlot.grupo(GrupoMuscular.gluteo, 'Gluteo'),
          TemplateSlot.grupo(GrupoMuscular.panturrilha, 'Panturrilha'),
        ],
      ),
    ],
  ),
  TemplateSplit(
    id: 'bro-split',
    nome: 'Bro split',
    descricao: '5 dias, foco por grupo muscular',
    dias: [
      TemplateDia(
        nome: 'Peito',
        slots: [
          TemplateSlot.grupo(GrupoMuscular.peito, 'Peito 1'),
          TemplateSlot.grupo(GrupoMuscular.peito, 'Peito 2'),
          TemplateSlot.grupo(GrupoMuscular.peito, 'Peito 3'),
        ],
      ),
      TemplateDia(
        nome: 'Costas',
        slots: [
          TemplateSlot.grupo(GrupoMuscular.costasLatissimo, 'Dorsal'),
          TemplateSlot.grupo(GrupoMuscular.costasRetangulares, 'Remada'),
          TemplateSlot.grupo(GrupoMuscular.trapezio, 'Trapezio'),
        ],
      ),
      TemplateDia(
        nome: 'Pernas',
        slots: [
          TemplateSlot.padrao(PadraoMovimento.squat, 'Quadriceps'),
          TemplateSlot.padrao(PadraoMovimento.hinge, 'Posterior'),
          TemplateSlot.grupo(GrupoMuscular.gluteo, 'Gluteo'),
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

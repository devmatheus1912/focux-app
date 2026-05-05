import 'enums.dart';

class TaxonomyLabels {
  static const modalidade = {
    Modalidade.musculacao: 'Musculacao',
    Modalidade.mobilidade: 'Mobilidade',
    Modalidade.cardio: 'Cardio',
  };

  static const padrao = {
    PadraoMovimento.pushHorizontal: 'Empurrar horizontal',
    PadraoMovimento.pushVertical: 'Empurrar vertical',
    PadraoMovimento.pullHorizontal: 'Puxar horizontal',
    PadraoMovimento.pullVertical: 'Puxar vertical',
    PadraoMovimento.hinge: 'Quadril / hinge',
    PadraoMovimento.squat: 'Agachamento',
    PadraoMovimento.lunge: 'Avanco',
    PadraoMovimento.carry: 'Carregamento',
    PadraoMovimento.coreAntiExtensao: 'Core anti-extensao',
    PadraoMovimento.coreAntiRotacao: 'Core anti-rotacao',
    PadraoMovimento.locomocao: 'Locomocao',
    PadraoMovimento.isometricoGeral: 'Isometrico',
    PadraoMovimento.mobilidadeDinamica: 'Mobilidade dinamica',
    PadraoMovimento.mobilidadeEstatica: 'Mobilidade estatica',
    PadraoMovimento.smr: 'Liberacao miofascial',
    PadraoMovimento.cardioEsteira: 'Esteira',
    PadraoMovimento.cardioBike: 'Bike',
    PadraoMovimento.cardioEliptico: 'Eliptico',
    PadraoMovimento.cardioHiit: 'HIIT',
    PadraoMovimento.cardioOutdoor: 'Outdoor',
    PadraoMovimento.cardioStep: 'Step',
  };

  static const grupo = {
    GrupoMuscular.peito: 'Peito',
    GrupoMuscular.costasLatissimo: 'Costas',
    GrupoMuscular.costasRetangulares: 'Costas altas',
    GrupoMuscular.ombroAnterior: 'Ombro anterior',
    GrupoMuscular.ombroLateral: 'Ombro lateral',
    GrupoMuscular.ombroPosterior: 'Ombro posterior',
    GrupoMuscular.biceps: 'Biceps',
    GrupoMuscular.triceps: 'Triceps',
    GrupoMuscular.antebraco: 'Antebraco',
    GrupoMuscular.quadriceps: 'Quadriceps',
    GrupoMuscular.posteriorCoxa: 'Posterior de coxa',
    GrupoMuscular.gluteo: 'Gluteo',
    GrupoMuscular.panturrilha: 'Panturrilha',
    GrupoMuscular.adutor: 'Adutor',
    GrupoMuscular.abdutor: 'Abdutor',
    GrupoMuscular.abdomen: 'Abdomen',
    GrupoMuscular.obliquo: 'Obliquo',
    GrupoMuscular.lombar: 'Lombar',
    GrupoMuscular.trapezio: 'Trapezio',
    GrupoMuscular.fullBody: 'Corpo inteiro',
  };

  static const equipamento = {
    Equipamento.barra: 'Barra',
    Equipamento.halter: 'Halter',
    Equipamento.kettlebell: 'Kettlebell',
    Equipamento.maquina: 'Maquina',
    Equipamento.polia: 'Polia',
    Equipamento.pesoCorporal: 'Peso corporal',
    Equipamento.banda: 'Banda',
    Equipamento.smith: 'Smith',
    Equipamento.banco: 'Banco',
    Equipamento.trx: 'TRX',
    Equipamento.corda: 'Corda',
    Equipamento.bolaSuica: 'Bola suica',
    Equipamento.caixa: 'Caixa',
    Equipamento.outros: 'Outros',
  };

  static const espaco = {
    Espaco.academiaCompleta: 'Academia completa',
    Espaco.academiaBasica: 'Academia basica',
    Espaco.casaEquipada: 'Casa equipada',
    Espaco.casaSemEquipo: 'Casa sem equipamento',
    Espaco.outdoor: 'Outdoor',
  };

  static const dificuldade = {
    Dificuldade.iniciante: 'Iniciante',
    Dificuldade.intermediario: 'Intermediario',
    Dificuldade.avancado: 'Avancado',
  };
}

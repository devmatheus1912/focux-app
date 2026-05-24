import 'enums.dart';

class TaxonomyLabels {
  static const modalidade = {
    Modalidade.musculacao: 'Musculação',
    Modalidade.mobilidade: 'Mobilidade',
    Modalidade.cardio: 'Cardio',
  };

  static const padrao = {
    PadraoMovimento.pushHorizontal: 'Empurrar horizontal',
    PadraoMovimento.pushVertical: 'Empurrar vertical',
    PadraoMovimento.pullHorizontal: 'Puxar horizontal',
    PadraoMovimento.pullVertical: 'Puxar vertical',
    PadraoMovimento.hinge: 'Posterior de quadril',
    PadraoMovimento.squat: 'Agachamento',
    PadraoMovimento.lunge: 'Avanço',
    PadraoMovimento.carry: 'Carregamento',
    PadraoMovimento.coreAntiExtensao: 'Core anti-extensão',
    PadraoMovimento.coreAntiRotacao: 'Core anti-rotação',
    PadraoMovimento.locomocao: 'Locomoção',
    PadraoMovimento.isometricoGeral: 'Isométrico',
    PadraoMovimento.mobilidadeDinamica: 'Mobilidade dinâmica',
    PadraoMovimento.mobilidadeEstatica: 'Mobilidade estática',
    PadraoMovimento.smr: 'Liberação miofascial',
    PadraoMovimento.cardioEsteira: 'Esteira',
    PadraoMovimento.cardioBike: 'Bike',
    PadraoMovimento.cardioEliptico: 'Elíptico',
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
    GrupoMuscular.biceps: 'Bíceps',
    GrupoMuscular.triceps: 'Tríceps',
    GrupoMuscular.antebraco: 'Antebraço',
    GrupoMuscular.quadriceps: 'Quadríceps',
    GrupoMuscular.posteriorCoxa: 'Posterior de coxa',
    GrupoMuscular.gluteo: 'Glúteo',
    GrupoMuscular.panturrilha: 'Panturrilha',
    GrupoMuscular.adutor: 'Adutor',
    GrupoMuscular.abdutor: 'Abdutor',
    GrupoMuscular.abdomen: 'Abdômen',
    GrupoMuscular.obliquo: 'Oblíquo',
    GrupoMuscular.lombar: 'Lombar',
    GrupoMuscular.trapezio: 'Trapézio',
    GrupoMuscular.fullBody: 'Corpo inteiro',
  };

  static const equipamento = {
    Equipamento.barra: 'Barra',
    Equipamento.halter: 'Halter',
    Equipamento.kettlebell: 'Kettlebell',
    Equipamento.maquina: 'Máquina',
    Equipamento.polia: 'Polia',
    Equipamento.pesoCorporal: 'Peso corporal',
    Equipamento.banda: 'Banda',
    Equipamento.smith: 'Smith',
    Equipamento.banco: 'Banco',
    Equipamento.trx: 'TRX',
    Equipamento.corda: 'Corda',
    Equipamento.bolaSuica: 'Bola suíça',
    Equipamento.caixa: 'Caixa',
    Equipamento.outros: 'Outros',
  };

  static const espaco = {
    Espaco.academiaCompleta: 'Academia completa',
    Espaco.academiaBasica: 'Academia básica',
    Espaco.casaEquipada: 'Casa equipada',
    Espaco.casaSemEquipo: 'Casa sem equipamento',
    Espaco.outdoor: 'Outdoor',
  };

  static const dificuldade = {
    Dificuldade.iniciante: 'Iniciante',
    Dificuldade.intermediario: 'Intermediário',
    Dificuldade.avancado: 'Avançado',
  };
}

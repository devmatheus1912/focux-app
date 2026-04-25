// Focux — realistic Brazilian demo data for the mockups

const FxData = {
  personal: {
    nome: 'Matheus Ribeiro',
    handle: '@matheus.pt',
    plano: 'PRO',
    alunosAtivos: 24,
    limite: 40,
  },

  kpi: {
    receitaMes: 8_420,
    previsao: 11_750,
    ticketMedio: 349,
    aderenciaMedia: 78,
    inadimplentes: 2,
    aCobrar: 3_200,
    treinosHoje: 14,
    checkinsHoje: 9,
    spark: [5.2, 5.8, 6.4, 6.1, 7.3, 7.9, 8.4], // R$ k/mês
  },

  alunos: [
    { id:1, nome:'Beatriz Carvalho',  idade:28, obj:'Hipertrofia',   status:'active',   aderencia:92, treinos:18, diasSem:1, valor:380, risco:'baixo',  sparkline:[60,65,72,70,80,85,92] },
    { id:2, nome:'Lucas Andrade',     idade:34, obj:'Emagrecimento', status:'active',   aderencia:71, treinos:12, diasSem:3, valor:280, risco:'baixo',  sparkline:[50,55,60,58,65,68,71] },
    { id:3, nome:'Rafael Medeiros',   idade:41, obj:'Performance',   status:'overdue',  aderencia:45, treinos:7,  diasSem:9, valor:450, risco:'alto',   sparkline:[70,65,55,48,50,47,45] },
    { id:4, nome:'Camila Prado',      idade:25, obj:'Condicionamento',status:'active',  aderencia:88, treinos:15, diasSem:2, valor:320, risco:'baixo',  sparkline:[65,70,75,78,82,85,88] },
    { id:5, nome:'Juliana Torres',    idade:36, obj:'Reabilitação',  status:'inactive', aderencia:22, treinos:3,  diasSem:14,valor:380, risco:'alto',   sparkline:[55,48,40,35,28,25,22] },
    { id:6, nome:'Pedro Henrique',    idade:29, obj:'Hipertrofia',   status:'active',   aderencia:84, treinos:14, diasSem:1, valor:320, risco:'baixo',  sparkline:[70,72,75,78,80,82,84] },
    { id:7, nome:'Fernanda Lima',     idade:31, obj:'Emagrecimento', status:'active',   aderencia:76, treinos:11, diasSem:2, valor:320, risco:'medio',  sparkline:[65,68,70,72,74,75,76] },
    { id:8, nome:'Gabriel Moura',     idade:22, obj:'Hipertrofia',   status:'new',      aderencia:95, treinos:4,  diasSem:0, valor:280, risco:'baixo',  sparkline:[80,85,90,92,94,95,95] },
  ],

  alunoFoco: {
    id: 1,
    nome: 'Beatriz Carvalho',
    idade: 28,
    altura: 168, // cm
    peso: 64.3,  // kg
    obj: 'Hipertrofia · Definição',
    inicio: 'Jan 2026',
    plano: 'Mensal · R$ 380',
    aderencia: 92,
    treinosTotal: 58,
    treinosMes: 18,
    prMes: 4,
    diasSem: 1,
    streak: 12,
    medidas: { cintura: 68, quadril: 94, braco: 28, coxa: 55 },
    evolucao: [68.2, 67.6, 66.9, 66.1, 65.4, 64.8, 64.3],
  },

  treino: {
    id: 7,
    nome: 'Superior · Push A',
    nivel: 'Intermediário',
    objetivo: 'Hipertrofia peito + tríceps',
    tempoEstimado: 52, // min
    volumeKg: 4820,
    exercicios: [
      { n:1, nome:'Supino reto com barra',       grupo:'Peito',   series:4, reps:'8-10', carga:70, desc:90 },
      { n:2, nome:'Supino inclinado halter',     grupo:'Peito',   series:3, reps:'10-12', carga:26, desc:75 },
      { n:3, nome:'Crossover no pulley',         grupo:'Peito',   series:3, reps:'12-15', carga:18, desc:60 },
      { n:4, nome:'Desenvolvimento militar',     grupo:'Ombro',   series:4, reps:'8-10', carga:42, desc:90 },
      { n:5, nome:'Elevação lateral',            grupo:'Ombro',   series:3, reps:'12-15', carga:12, desc:45 },
      { n:6, nome:'Tríceps pulley corda',        grupo:'Tríceps', series:4, reps:'10-12', carga:28, desc:60 },
      { n:7, nome:'Tríceps francês halter',      grupo:'Tríceps', series:3, reps:'10-12', carga:18, desc:60 },
    ],
  },

  financeiro: {
    mesAtual: 'abr · 2026',
    recebido: 8420,
    previsto: 11750,
    pendente: 3330,
    ticketMedio: 349,
    inadimplentes: 2,
    evolucao: [
      { m:'nov', v:5240 }, { m:'dez', v:5890 }, { m:'jan', v:6430 },
      { m:'fev', v:6120 }, { m:'mar', v:7380 }, { m:'abr', v:8420 },
    ],
    vencimentos: [
      { nome:'Rafael Medeiros', mes:'abr/26', valor:450, status:'atrasado', dias:9 },
      { nome:'Juliana Torres',  mes:'abr/26', valor:380, status:'atrasado', dias:5 },
      { nome:'Lucas Andrade',   mes:'mai/26', valor:280, status:'proximo',  dias:3 },
      { nome:'Camila Prado',    mes:'mai/26', valor:320, status:'proximo',  dias:5 },
    ],
    topAlunos: [
      { nome:'Rafael Medeiros',  total:2700 },
      { nome:'Beatriz Carvalho', total:2280 },
      { nome:'Juliana Torres',   total:1900 },
      { nome:'Camila Prado',     total:1600 },
    ],
  },
};

window.FxData = FxData;

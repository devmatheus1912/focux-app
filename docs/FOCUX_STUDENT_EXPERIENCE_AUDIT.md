# Focux — Auditoria da experiência do aluno

Data: 2026-09-25 · Escopo: `focux-app` (Flutter) e `focux-backend` (Spring Boot).
Direção e decisões detalhadas: `docs/superpowers/specs/2026-09-25-aluno-dados-insights-design.md`.

## 1. Arquitetura atual

- **App**: shell do aluno em `lib/core/router/app_router_aluno_routes.dart`
  (`StatefulShellRoute` + `AlunoShell`, dock `FxDockItems.aluno`): Hoje
  `/dashboard/aluno`, Treinos `/checkin/treinos`, Saúde `/saude`, Chat
  `/chat/aluno`, Perfil `/aluno/perfil`. Estado com Riverpod.
- **BFF da Home**: `GET /api/dashboard/aluno/home` →
  `modules/dashboard/AlunoDashboardController` (`@PreAuthorize ALUNO`, rate limit
  60/min) → `AlunoDashboardService.getHome(TenantContext.getAlunoId())`.
- **Cache**: servidor Caffeine `aluno-dashboard-home` 60s, chave `alunoId`
  (`infra/config/CacheConfig.java`), eviction local + Redis
  (`AlunoDashboardHomeCacheEvictor`); ETag fraca via `infra/api/ConditionalGet`.
  App: `AlunoDashboardHomeClientCache` em memória, fresco 60s, stale até 5 min
  com refresh em background; ETag em `ApiEtagStore`.
- **Tenant**: `JwtFilter` preenche `TenantContext` (ThreadLocal) a partir das
  claims; o `alunoId` nunca vem de path/query nos endpoints do aluno.
- **Tempo**: `FocuxClock` em `America/Sao_Paulo`; semana começa na segunda.

## 2. Fluxo do aluno

Splash/login fazem prefetch da Home (`prefetchAlunoDashboardHome`) → Home →
treino (`/checkin/executar`: iniciar, séries, concluir) → folha de evolução da
sessão (`showCheckinEvolucaoSheet`) → volta à Home (provider invalidado). Em
paralelo: Saúde (sync `POST /api/aluno/saude/sync`), Chat, Agenda
(`/agenda/aluno`), Perfil. `/evolucao` redireciona para a Home — **não existe
tela de Evolução do aluno**.

## 3. Home atual

`lib/features/dashboard/screens/aluno_dashboard_screen.dart` (+ parts `header`,
`cards`, `tools`), de cima para baixo:

1. `_TodayFocusCard` — ação principal escolhida no app por `_mainHomeAction`
   (`data/aluno_autonomy_plan.dart`), streak em semanas, pill de ritmo
   (`rhythmLabel`), narrativas.
2. `_AlunoAnamneseCta` (condicional).
3. `AlunoRecoveryCard` "Prontidão do dia" (se houver wearable).
4. `CoachProativoCard` (se houver mensagens).
5. `AlunoUpsellCarousel` (se houver ofertas).
6. `_AlunoHeroCard` (marca do personal).
7. `FxEmptyState` ou `ProgressoSemanalWidget` "Consistência" (7 dias, chips de
   aderência e volume).
8. `_PerformanceEvolutionCard` — gráfico volume × força (`_DualTrendPainter`),
   último PR, volume semana/mês.
9. `_StudentJourneyCard` "Central do aluno" (plano de autonomia, 7 tarefas).
10. `_StudentToolsSection` "Atalhos do dia".

Estados: `SkeletonList` no loading, `FxErrorState` no erro, pull-to-refresh.

## 4. Dados disponíveis

Payload `AlunoDashboardHomeResponse` / `AlunoDashboardHomeBundle`
(`lib/features/dashboard/data/dashboard_repository.dart`): `aluno`,
`personalBrand`, `treinos`, `historicoResumo` (12), `medidas` (5), `chat`,
`notificacoesNaoLidas`, `coachMensagens` (5), `upsellPendentes` (5),
`npsDeveResponder`, `recovery`, `hasWearableHistory`, `streakAtual`,
`volumeSemanaKg`, `volumeMesKg`, `volumePorSemana` (8), `forcaPorSemana` (8),
`frequenciaDias`. `recordes` é lido pelo app mas **não é enviado pelo BFF**.
Fora da Home: `/api/checkin/{id}/evolucao-sessao`, `/api/checkin/historico`,
`/api/aluno/evolucao` (recordes sem limite), `/api/gamificacao`.

## 5. Métricas existentes (fórmula real)

| Métrica | Onde | Fórmula |
|---|---|---|
| Aderência | `AlertasService.metricsFor` / `calcularRisco` | dias distintos com treino concluído em 30 dias × 100 / 30 |
| Dias sem treino | `AlertasService` | dias desde `MAX(COALESCE(concluidoEm, iniciadoEm))` |
| Score de prontidão | `alunos/ProntidaoService` | 100 − inadimplência − penalidade de aderência; não usado na Home |
| Prontidão (recovery) | `health/RecoveryScoreCalculator` | base 62 ± sono, passos, FC média; gravado no sync |
| Sequência | `GamificacaoService.atualizarStreakAposTreino` | semanas ISO consecutivas com treino; só recalculado ao concluir |
| Volume | `AlunoHomeVolume` | Σ carga × primeiro número das reps, séries concluídas |
| Força | `AlunoHomeVolume` | média simples da carga de todas as séries da semana |
| Meta semanal | `FocuxScoreCalculator.metaDiasSemanaPlano` | `min(7, nº de treinos ativos)` |
| PR | `CheckinEvolucaoAnalyzer` + `CheckinRecordeSync` | só PR de carga é persistido |
| FocuxScore (app) | `_buildFocuxScore` em `aluno_autonomy_plan.dart` | pesos de perfil, consistência, evolução, medida, chat, financeiro |

## 6. Métricas possíveis (com dados que já existem)

- Força como 1RM estimado (Epley) por exercício, comparável entre semanas.
- Variação de força só entre exercícios comuns (`forcaDeltaPercent`).
- Volume da última semana completa vs média das 6 anteriores.
- Sessões na semana ISO vs meta; sessões em 7 e 28 dias.
- Sequência calculada ao ler, sempre atual.
- Últimos PRs de carga no BFF.
- Idade do dado de prontidão.

## 7. Insights possíveis

Novo aluno, recuperação baixa, PR recente, retorno após pausa, meta atingida,
força subindo, volume subindo, consistência, ritmo caiu, dados insuficientes.
Regras, prioridade e confiança na spec (Parte 2). Hoje o único "insight" do
aluno é client-side (`rhythmLabel`, `alunoPerformanceForcaDeltaInsight`) e as
mensagens do coach proativo (`CoachProativoScheduler`).

## 8. Gráficos existentes

Todos `CustomPainter` (`fl_chart` está no `pubspec.yaml` e não é importado):
`_DualTrendPainter` (Home, volume × força), `RecoveryScoreRing`
(`lib/features/health/widgets/recovery_score_ring.dart`), `FxSparkline`
(histórico), anel do descanso (`checkin_timer_widgets.dart`), bolinhas dos 7
dias em `ProgressoSemanalWidget`.

## 9. Problemas de UX

- A Home não responde "estou evoluindo?" com dado confiável: a linha de força
  mistura exercícios e o texto compara primeira e última semana no app.
- "Força +X% no último PR" usa uma evolução que nem sempre é PR.
- Prontidão de semanas atrás aparece como de hoje.
- Sequência congelada para quem parou de treinar.
- Muitos blocos no fold (hero da marca, upsell, coach, central, atalhos)
  competindo com o treino do dia; §37.5 pede 1 P0 sem catálogo no fold.
- Sem tela de Evolução do aluno.

## 10. Problemas de UI

- Textos sem acento em caminho do aluno: "Recuperacao parcial" e "hidratacao"
  (`lib/core/health/recovery_score.dart`), "Nao foi possivel…" no chat.
- "Adêrencia" (citado no prompt) não existe no código.
- `score.value`, `riskLabel`, `objectiveLens` calculados e nunca exibidos.
- Home e Central do aluno recalculam o mesmo plano.

## 11. Problemas de performance

- Cache miss do BFF dispara 14 transações paralelas contra pool Hikari de 5.
- Entidade do aluno carregada ~4 vezes por request; ~27–32 queries por miss.
- N+1 em `upsellPendentes` (`AlunoOferta.oferta` LAZY) e em `evolucao-sessao`.
- `iniciar`/`registrarSerie` não limpam o cache da Home (até 60s defasado).
- App: `minhaAnamneseProvider` sem TTL, refetch a cada abertura.

## 12. Oportunidades

- Motor determinístico de insights no BFF (um insight, com confiança).
- Minimização LGPD: o aluno recebe campos de CRM do personal (`emRisco`,
  `riscoNivel`, `proximoContato`, `snoozedUntil`, `ultimoContato`,
  `operacaoFocusMode`, `statusFinanceiro`).
- Unificar o parser de repetições (Home e `EvolucaoInteligenteService` divergem).
- Analytics da Home do aluno (hoje sem evento de visualização nem de CTA).

## 13. Alternativas consideradas

- Motor de insights: (A) backend no BFF, (B) app em Dart, (C) sinais no
  backend e escolha no app. Escolhida **A**: fonte única, testável em JUnit,
  corrigível sem publicar app; segue o padrão de `ProximaAcaoResolverChain`.
- Força: 1RM estimado (escolhido), carga máxima, remover a linha, renomear.
- Sequência: calcular ao ler (escolhido), job diário, ambos.
- Prontidão: hoje/ontem (escolhido), só hoje, 72h com idade.
- Escopo: 4 specs (escolhido) vs spec única.

## 14. Direção escolhida

Primeiro tornar os dados verdadeiros e o insight confiável (spec 1); depois
redesenhar a Home em torno das quatro perguntas (spec 3) e fazer o acabamento
transversal (spec 4). Nada de métrica inventada; LOW só em mensagem neutra.

## 15. Plano de implementação

1. Backend: `AlunoHomeForca`, `RepeticoesParser`, sequência ao ler, prontidão
   hoje/ontem, `recordes` no BFF, `AlunoSelfResponse`, BFF com ≤ 4 tarefas.
2. Backend: pacote `dashboard.insights` (10 regras) + testes dos 7 cenários.
3. App: modelo `AlunoHomeInsight`, texto de força pelo servidor, prontidão
   desatualizada, insight no `_TodayFocusCard`, i18n, analytics, limpeza.
4. Specs 3 e 4.

Plano detalhado sai do skill writing-plans após aprovação da spec.

## 16. Riscos

- Volume do painel do personal muda levemente (série sem reps deixa de contar 10).
- Números de força mudam de escala (média de carga → 1RM estimado).
- App antigo da loja: mitigado por contrato aditivo e `Aluno.fromJson` tolerante.
- Reagrupar o BFF pode mudar latência; medir antes/depois no perfil não-teste.
- Pisos JaCoCo já vermelhos em `iap`, `checkin` (0.78) e `infra.security`
  mantêm o `check` do CI vermelho independentemente desta entrega.

## 17. Itens que NÃO devem ser implementados agora

- Redesenho visual da Home e tela de Evolução (spec 3).
- IA generativa para insights.
- Insights de queda de força ou volume.
- PR de repetições e novos tipos de PR.
- Notificações push de insight.
- Mudança da fórmula da aderência.
- Gráficos 3D ou migração para `fl_chart`.

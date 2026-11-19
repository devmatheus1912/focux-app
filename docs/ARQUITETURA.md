# Arquitetura do app

Como o app Flutter do Focux Personal está organizado e quais regras os testes de contrato protegem. Para o visual, ver [`DESIGN-SYSTEM.md`](DESIGN-SYSTEM.md). Para publicar nas lojas, ver [`RELEASE.md`](RELEASE.md).

## Visão geral

- **Um app, dois perfis:** personal e aluno, com shells e rotas separados por papel. A equipe do personal entra como personal com permissões limitadas pelo backend.
- **Stack:** Flutter 3, Riverpod 3 (estado), GoRouter 18 (navegação), Dio (HTTP), STOMP (tempo real).
- **Backend:** API REST do `focux-backend`. O app não guarda regra de negócio que o backend já decide; ele formata e apresenta.
- **Idioma:** só português do Brasil (`lib/l10n/app_pt.arb`). Texto em função sem `BuildContext` usa `ptS` (`lib/l10n/pt.dart`).

## Estrutura

```text
lib/
  core/        # infraestrutura compartilhada: api, auth, router, theme, widgets, health, media, storage…
  features/    # um diretório por domínio (alunos, treinos, checkin, financeiro, ia, agenda, evolucao…)
  l10n/        # textos
test/
  core/        # contratos globais que leem o código-fonte (design system, rotas, segurança, saúde)
  features/    # testes por domínio
```

Cada feature segue a mesma divisão: `screens/`, `widgets/`, `utils/`, `models/`, `data/`, `providers/`. Tela grande vira arquivos `*.part.dart`. Algumas pastas têm contrato de tamanho de arquivo (a execução do treino, por exemplo, limita a 500 linhas).

## Navegação

| Shell | Abas |
|---|---|
| Personal | Hoje `/dashboard/personal` · Alunos `/alunos` · Conversas `/chat/inbox` · Agenda `/agenda` · Treinos `/treinos` |
| Aluno | Hoje `/dashboard/aluno` · Treinos `/checkin/treinos` · Saúde `/saude` · Chat `/chat/aluno` · Perfil `/aluno/perfil` |

- Rotas em `lib/core/router/` (`app_router_personal_shell_routes.dart`, `app_router_aluno_routes.dart`, `app_router_chrome_routes.dart`, `app_router_auth_routes.dart`, `app_router_redirect.dart`).
- Rota nova entra em `lib/core/design_system/focux_surfaces_catalog.dart`.
- Estado da rota só por `estadoDaRota` / `uriDaRota` (`core/router/estado_da_rota.dart`). `GoRouterState.of` entra em laço infinito quando a tela que sai de um `ShellRoute` reconstrói (foi o travamento FLUTTER-4/5). Contrato em `test/core/router/estado_da_rota_test.dart`.
- Abrir uma tela com toque duplo protegido: `core/navigation/fx_abertura_unica.dart`.

## Dados e estado

- Toda escrita aceita sobe `MutacaoRecente.geracao`; o `AtualizaAoVoltarScope` busca de novo Hoje, Alunos e 360 ao voltar para eles. As telas não invalidam providers depois de `push`.
- A Home do personal só atualiza por `invalidatePersonalDashboardHome`.
- `GetDedupe` junta GETs iguais em andamento.
- **Check-in sem internet:** o pacote da semana fica no aparelho (`OfflineCache`, 7 dias); sem rede o treino roda numa sessão local (id negativo, `checkin/data/checkin_offline.dart`) e sobe depois de concluído. Os caminhos da execução moram só em `checkin/data/checkin_rotas_api.dart`.
- **Série atual do treino:** só `checkin/utils/serie_de_agora.dart`.
- **Logout:** apaga sessão, rascunhos criptografados, cache offline, vídeos guardados e histórico de saúde importado. A primeira abertura depois de instalar apaga a sessão antiga do Keychain.

## Segurança e privacidade

- Token em secure storage; JWT renovado pelo cliente de API.
- Sentry sem corpo de requisição (`MaxRequestBodySize.never`), sem argumentos de rota e sem token de ativação. Amplitude bloqueia texto livre, ids, e-mail e token (`amplitudeSafeProps`); o usuário é identificado só pelo `sub` do token.
- Nenhum dado vai para a IA sem aceite (`IA_TERCEIROS`, `IA_COPILOTO`, `SAUDE_IA`), revogável em Perfil > Privacidade.
- Saúde (Apple Saúde / Health Connect) por `core/health/health_service.dart`. No Android não há leitura de HRV (recusada pelo Google Play).

## Testes

| O que | Comando |
|---|---|
| Análise estática sem tolerância | `dart analyze --fatal-warnings --fatal-infos lib test` |
| Testes unitários, de widget e de contrato | `flutter test --no-pub` (cerca de 7 minutos) |
| Integração | `flutter test integration_test` |
| E2E (Playwright sobre o build web) | ver [`e2e/README.md`](../e2e/README.md) |
| Verificação local completa | `tool/verify.ps1` |

Os testes de contrato em `test/core/` leem o código-fonte e protegem regras do projeto inteiro (tipografia, ícones, fundo das páginas, ações sem texto solto, rotas, tamanho de arquivo). Se um quebrar, entenda a regra antes de mexer no teste. Teste novo testa comportamento: desenha a tela ou chama a função.

**Goldens** não carregam Inter nem Phosphor (o texto vira bloco). Para ver a tela com a fonte de verdade, crie um `test/flutter_test_config.dart` temporário que carregue as fontes, rode o golden com `--update-goldens`, confira o PNG, apague o config e gere os goldens de novo sem ele.

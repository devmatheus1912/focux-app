# Focux — Auditoria 10/10

Checklist executável do monorepo (`focux-app` + `focux-backend`). Atualizado após implementação dos gates de auditoria.

## Política de cobertura (backend)

| Métrica | Piso CI | Meta equipe | Módulos críticos |
|---------|---------|-------------|------------------|
| JaCoCo linhas | **40%** | 60% | auth, planos, financeiro, RBAC: 70% |
| Branches | — | 45% | regras puras (mappers): 80% |

JaCoCo é **indicador anti-regressão**, não objetivo final.

## Gates automáticos — Backend

| Gate | Arquivo | Invariante |
|------|---------|------------|
| Map→DTO | `MapResponseContractTest` | Zero `Map<String,Object>` em controllers (exc. webhooks) |
| Validação | `ValidMutationContractTest` | `@Valid` em mutações com `@RequestBody` |
| OpenAPI | `OpenApiContractTest` | `/v3/api-docs` publica contrato v1.1.0 |
| Erros uniformes | `ErrorResponseContractTest` | Handlers usam `errorBody` + `requestId` |
| Tenant isolation | `CrossTenantIsolationTest` | Personal B não lê/deleta aluno/anamnese de A |
| Smoke HTTP | `*ControllerTest` (~69) | Sem 5xx; auth obrigatória |
| RBAC 403 | `forbiddenForWrongRole` | ALUNO bloqueado em endpoints PERSONAL |
| JaCoCo | `build.gradle` → `check` | Piso 40% linhas |

### Service tests (módulos de risco)

- `SuporteServiceTest`, `PagamentoServiceTest`, `IapVerifierTest`
- `NfseServiceTest`, `AnamneseServiceTest`, `CloudinaryServiceTest`

## Gates automáticos — Frontend

| Gate | Arquivo | Invariante |
|------|---------|------------|
| Módulos | `all_modules_contract_test.dart` | Data layer + screen por feature |
| Repositórios API | `all_repositories_api_contract_test.dart` | Todo `*_repository.dart` usa `/api/` |
| Launch API | `launch_repositories_api_contract_test.dart` | 17 módulos launch com `/api/` |
| Tier S+ | `screen_tier_s_plus_contract_test.dart` | 115 telas: a11y, loading, tokens |
| A11y | `a11y_controls_contract_test.dart` | Labels em controles |
| Router | `app_router_contract_test.dart` | Rotas, guards, fallbacks |
| Analyze | CI `dart analyze --fatal-infos` | Zero warnings/infos |

## CI/CD

| Repo | Workflow | Comando principal |
|------|----------|-------------------|
| BE | `ci.yml` | `./gradlew check` + Flyway PG |
| BE | `security.yml` | gitleaks |
| FE | `analyze.yml` | analyze + `flutter test` + orphan scan |
| FE | `e2e.yml` | `test:smoke` + `gradlew check` |
| Ambos | `dependabot.yml` | Atualizações semanais |

## Segurança (manual trimestral)

- [ ] Matriz RBAC role × recurso revisada
- [ ] Teste manual TalkBack nos 8 hubs
- [ ] Restore de backup (`BackupService`) em staging
- [ ] Revisão de secrets (gitleaks + rotação)

## LGPD

Ver `docs/LGPD-RUNBOOK.md`.

## Definition of Done (PR)

1. `./gradlew check` verde (BE) ou `flutter test` + analyze verde (FE)
2. Sem novo `Map<String,Object>` em controller
3. Regra de negócio nova → teste unitário no service/mapper
4. Endpoint novo → smoke + RBAC se PERSONAL-only
5. Tela nova → passa Tier S+ + a11y gate

## ADRs

- `docs/adr/001-jacoco-indicador.md` — cobertura como bússola
- `docs/adr/002-brasil-first-sem-i18n.md` — PT-BR fixo; i18n em standby

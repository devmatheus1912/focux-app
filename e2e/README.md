# Focux E2E (Playwright)

Suite Playwright para Focux Personal Web.

## Pré-requisito (1 vez só)

```bash
cd e2e
npm install
npx playwright install chromium
cp .env.example .env
# editar .env com email/senha das contas QA reais
```

## Subir app

Em 2 terminais separados (não fechar):

```bash
# Terminal 1 — backend
cd ../../focux-backend
./gradlew bootRun
# espera "Started Application"
```

```bash
# Terminal 2 — flutter web
cd ..
flutter run -d chrome --web-port 60791 --web-renderer html
# espera servidor estabilizar em http://localhost:60791
```

## Rodar

```bash
cd e2e

# todos os testes (headless)
npm test

# só P0 (release-blocker)
npm run test:p0

# CI executa @p0 (8 specs); smoke (@smoke) é subconjunto
npm run test:smoke

# com browser visível (debug)
npm run test:headed

# UI mode (melhor pra investigar)
npm run test:ui

# abrir relatório HTML com vídeos/screenshots
npm run report
```

## Gravar novo teste

```bash
npm run codegen
# OU específico:
npx playwright codegen http://localhost:60791/alunos
```

## Estrutura

```
e2e/
├── playwright.config.ts        # config + projects (auth-personal, auth-aluno, personal, aluno, public)
├── package.json
├── .env                        # NÃO commitar — credenciais
├── .env.example
├── .auth/                      # storage state (cookies de sessão) — NÃO commitar
├── tests/
│   ├── _fixtures.ts            # captura console error + 500/403
│   ├── auth.personal.setup.ts  # login automático personal
│   ├── auth.aluno.setup.ts     # login automático aluno
│   ├── public/                 # rotas que não exigem login
│   ├── personal/               # roda como personal logado
│   └── aluno/                  # roda como aluno logado
└── playwright-report/          # gerado após rodar
```

## Tags

- `@p0` — release-blocker, deve passar antes do publish
- `@p1` — bug grave, fixar antes de escalar
- `@smoke` — fluxo crítico, parte do smoke pré-deploy

## Regressões cobertas (status.md)

| Bug | Spec |
|---|---|
| getKey() POST /api/treinos 500 | personal/03-treinos.spec.ts |
| /api/evolucao/{id}/fotos 404 | personal/09-evolucao-fotos-P0.spec.ts |
| BoxConstraints meus treinos aluno | aluno/02-meus-treinos-P1.spec.ts |
| IA fora do app aluno | aluno/04-ia-aluno-P1.spec.ts |
| /api/aluno/anamnese 404 | aluno/06-anamnese-P1.spec.ts |
| Hubs refatorados (chat, copiloto, migracao, exercicios) | personal/11-rotas-criticas-P0.spec.ts |

## Falhas esperadas hoje

`personal/09-evolucao-fotos-P0.spec.ts` — falha enquanto endpoint /api/evolucao/{id}/fotos não for criado no backend ou frontend não migrar pra /api/alunos/{id}/fotos.

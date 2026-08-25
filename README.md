# Focux Personal — App

> **Proprietário e confidencial.** Este repositório e seu conteúdo são propriedade privada. Uso, cópia, distribuição ou engenharia reversa sem autorização expressa são proibidos.

Cliente Flutter (Android, iOS e Web) da plataforma **Focux Personal** — o espaço de trabalho onde personal trainers operam o negócio e alunos vivem o treino, a evolução e o acompanhamento, no mesmo produto multi-tenant.

Site: [focuxpersonal.com](https://focuxpersonal.com)

---

## O produto

Dois papéis. Uma experiência coerente. Dois hubs distintos.

| Perfil | O que o app entrega |
|---|---|
| **Personal** | Command Center com Índice Focux, base de alunos, treinos e biblioteca, agenda, financeiro, IA copiloto, CRM, comunicação, marca e planos |
| **Aluno** | Execução de treino com check-in, evolução e fotos, saúde/recovery, chat, feed, pagamentos, gamificação e notificações |

O app fala com o `focux-backend` (API REST, tempo real e regras de negócio). Autenticação por sessão JWT, navegação por perfil e first paint dos hubs via BFF agregado — um request, a home pronta.

---

## Experiência

### Para o personal

Centro de comando operacional: aderência da base, alertas, agenda do dia e atalhos para o que importa agora. Em torno disso, dezenas de telas organizadas por módulo — alunos (visão 360), treinos e exercícios, agenda, financeiro e cobrança, chat e broadcasts, feed, leads e growth, identidade visual white-label, planos e assinatura, automação, NPS, suporte e analytics.

A navegação do personal é um shell próprio, separado da jornada do aluno. Feature gates por plano controlam o que cada tenant enxerga.

### Para o aluno

Dashboard enxuto, execução de treino (incluindo modo presencial e coaching por pose no mobile), histórico, evolução com fotos, hábitos, saúde e recovery, chat com o personal, feed, ranking e gamificação, financeiro do lado do aluno e notificações push.

### Transversal

Onboarding, convites, busca, perfil, preferências de aparência, i18n (português, inglês e espanhol), e superfícies públicas de captura/landing ligadas à web oficial.

---

## Identidade de design

O Focux não parece um template genérico de fitness. A interface foi desenhada como produto premium: superfícies em vidro líquido (Liquid Glass / Tokens Strip), tipografia de hub com hierarquia clara, motion discreto na entrada de telas e estados de loading/erro/vazio consistentes — skeleton em vez de spinner solto, erros amigáveis, empty states com CTA.

Tema claro e escuro seguem o sistema do dispositivo (ou escolha do usuário). Cada personal pode carregar a própria cor e marca — white-label de verdade, sem hardcode de identidade Focux nas superfícies white-label. Acessibilidade (TalkBack / VoiceOver), contraste e reduced motion fazem parte do contrato do design system, com gates de teste dedicados.

---

## Stack

| Camada | Escolha |
|---|---|
| UI / runtime | Flutter (Android, iOS, Web) · Material 3 |
| Estado | Riverpod |
| Navegação | GoRouter (shells por perfil) |
| Rede | Dio · STOMP / WebSocket |
| Sessão | Secure storage no mobile |
| Push & crash | Firebase Cloud Messaging · Crashlytics |
| Auth social | Google Sign-In |
| Pagamentos | In-app purchase (lojas) · fluxos financeiros via API |
| Saúde | Apple Health / Health Connect |
| Visão / mídia | ML Kit (pose) · câmera · áudio · Rive |
| i18n | ARB · PT / EN / ES |

Arquitetura em `lib/`:

```text
lib/
├── core/       # api, auth, router, theme, security, widgets, plataforma
├── features/   # dezenas de domínios (dashboard, alunos, treinos, ia, …)
└── l10n/       # pt, en, es
```

Ecossistema: `focux-app` (este cliente) · `focux-backend` (API) · `focux-website` (site e superfícies públicas).

---

## Qualidade

Sinal de engenharia, não checklist de onboarding.

| Gate | Postura |
|---|---|
| Testes unitários / widget | ~380 arquivos · ~1.200 casos em `test/` |
| Analyzer | `dart analyze` com warnings e infos fatais |
| Integração | `integration_test/` + E2E web (Playwright) |
| CI | Analyze + testes + scan de órfãos · E2E · secret scan · SAST |

Pilares de design system, navegação, segurança e UX têm contratos automatizados — regressão visual e estrutural entra no mesmo pipeline que a lógica de negócio.

```bash
dart analyze --fatal-warnings --fatal-infos
flutter test
flutter test integration_test
# E2E web: cd e2e && npm install && npx playwright test
```

---

## Segurança

Postura defensiva no cliente; isolamento de tenant e PII no backend.

- Sessão JWT com refresh; logout invalida cliente e servidor
- Builds de produção usam certificate pinning e armazenamento seguro de sessão
- Hardening de loja: ofuscação / ProGuard, tráfego claro desabilitado, políticas de backup restritas
- Detecção de ambiente comprometido e gates biométricos em fluxos sensíveis de assinatura
- Erros de UI nunca vazam detalhe técnico; clipboard sensível é tratado à parte
- IA com disclaimer de supervisão profissional
- LGPD e tratamento de dados pessoais no backend
- CI com varredura de secrets e análise estática

**Não versionar:** credenciais, keystores, configs Firebase reais, pins ou URLs de produção em arquivos locais. Use `.example` e `--dart-define` no build.

Builds oficiais de loja passam por scripts internos de release — hardening adicional é requisito, não opcional.

---

## Como rodar localmente

**Pré-requisitos:** Flutter SDK estável · Android Studio e/ou Xcode · emulador, dispositivo ou Chrome · backend local ou remoto.

```bash
flutter pub get
cp .env.local.example .env.local   # opcional; valores reais ficam gitignored
```

Configuração de ambiente via `--dart-define` (categorias: `API_URL`, `PUBLIC_WEB_URL`). Detalhe em `lib/core/config/env.dart`.

```bash
# Android (emulador → host da máquina)
flutter run -d emulator-5554 \
  --dart-define=API_URL=http://10.0.2.2:8080 \
  --dart-define=PUBLIC_WEB_URL=http://10.0.2.2:8080

# Web
flutter run -d chrome --web-port 61791 \
  --dart-define=API_URL=http://localhost:8080 \
  --dart-define=PUBLIC_WEB_URL=http://localhost:61791
```

Build de desenvolvimento:

```bash
flutter build apk --release \
  --dart-define=API_URL=https://SEU_BACKEND \
  --dart-define=PUBLIC_WEB_URL=https://focuxpersonal.com

flutter build appbundle --release
flutter build web --release
```

Para builds de loja, use os scripts em `tools/release/` (configuração interna). i18n: fontes em `lib/l10n/` · `flutter gen-l10n`.

---

## Licença e confidencialidade

Projeto **privado e proprietário**. Código, design system, copy, assets e documentação deste repositório não são open source. Qualquer uso, distribuição, republicação ou exploração comercial depende de autorização do proprietário.

> **Proprietário e confidencial.** Acesso a este repositório não implica licença de uso além do necessário para avaliação autorizada.

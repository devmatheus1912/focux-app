# Focux App

Aplicativo mobile do **Focux** — plataforma SaaS para personal trainers gerenciarem alunos, exercícios, treinos e negócio.

## Visão Geral

O Focux App é o cliente mobile da plataforma Focux. Suporta dois perfis de usuário:

- **Personal Trainer** — gerencia alunos, cria exercícios/treinos, controla assinatura e finanças
- **Aluno** — visualiza treinos, faz check-in, chata com personal, acessa feed

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3.29.3 |
| Estado | Riverpod (flutter_riverpod) |
| Navegação | GoRouter |
| HTTP | Dio |
| Storage seguro | flutter_secure_storage |
| WebSocket | stomp_dart_client (STOMP) |
| Push notifications | Firebase Messaging |
| Markdown | flutter_markdown |
| Vídeo | video_player |
| PDF | pdf + printing |
| Gráficos | fl_chart |

## Estrutura do Projeto

```
lib/
├── core/
│   ├── api/            # ApiClient (Dio + interceptor JWT)
│   ├── router/         # AppRouter (GoRouter — todas as rotas)
│   ├── storage/        # SecureStorage (token, role, isAdmin)
│   └── theme/          # AppTheme
└── features/
    ├── admin/          # Painel admin (stats + personais)
    ├── agenda/         # Agenda de atendimentos
    ├── alertas/        # Alertas de risco de abandono (Epic 4)
    ├── alimentar/      # Plano alimentar do aluno
    ├── alunos/         # Lista, detalhe e cadastro
    ├── anamnese/       # Anamnese do aluno
    ├── assinatura/     # Planos e assinatura (MercadoPago)
    ├── auth/           # Login, Register, Splash
    ├── avaliacao/      # Avaliação física
    ├── checkin/        # Execução de treino + histórico
    ├── chat/           # Chat Personal<->Aluno (WebSocket)
    ├── convites/       # Convidar alunos por código
    ├── dashboard/      # Dashboard do personal e do aluno
    ├── exercicios/     # Biblioteca de exercícios (GIF + vídeo)
    ├── feed/           # Feed de conteúdo privado
    ├── financeiro/     # Mensalidades + PIX + dashboard (Epics 2–3)
    ├── ia/             # IA: gerar treino, dieta, progressão, chat
    ├── leads/          # Funil comercial (Epic 1)
    ├── onboarding/     # Tela de onboarding
    ├── perfil/         # Perfil do personal
    ├── relatorio/      # Relatório de aderência
    └── treinos/        # Treinos com exercícios ordenados
```

## Funcionalidades — Estado atual (v1.1.0)

### Personal Trainer
- **Dashboard** — métricas, menu completo
- **Alunos** — lista com badge inadimplência/risco, detalhe, anamnese, avaliação, plano alimentar
- **Funil de Leads** — cadastrar, filtrar status, ligar/WhatsApp, converter em aluno *(Epic 1)*
- **Financeiro** — dashboard com gráfico, mensalidades, PIX, registrar cobrança *(Epics 2–3)*
- **Alertas de Risco** — score de abandono, configuração de thresholds *(Epic 4)*
- **Convites** — código de convite para aluno criar conta
- **Exercícios** — biblioteca com GIF (Cloudinary) e vídeo
- **Treinos** — criar, adicionar exercícios, atribuir a aluno
- **Agenda** — agendar e gerenciar atendimentos
- **Chat** — WebSocket STOMP com aluno
- **Feed** — publicar conteúdo para alunos
- **IA** — gerar treino, dieta, progressão de carga com Claude AI, exportar PDF
- **Relatório** — aderência por período
- **Perfil** — editar dados e logo
- **Assinatura** — planos FREE/PRO/PREMIUM via MercadoPago
- **Painel Admin** *(só admin)* — stats da plataforma + gerenciar personais

### Aluno
- **Dashboard** — meus treinos, feed, chat, IA
- **Check-in** — executar treino com registro de cargas, histórico
- **Chat** — conversar com personal
- **Feed** — conteúdo do personal
- **Assistente IA** — tirar dúvidas de fitness

## Rodando Localmente

**Pré-requisitos:** Flutter 3.29.3+

```bash
git clone https://github.com/devmatheus1912/focux-app.git
cd focux_app
flutter pub get
flutter run
```

Por padrão aponta para o backend em produção (`https://focux-backend-production.up.railway.app`).

## Build Release (Android)

```bash
flutter build appbundle --release
# Keystore: android/app/focux.jks (senha em android/key.properties)
# Upload .aab em play.google.com/console
```

## Backend

- Repositório: [devmatheus1912/focux-backend](https://github.com/devmatheus1912/focux-backend)
- Produção: `https://focux-backend-production.up.railway.app`

---

## Roadmap — 15 Epics

| Epic | Título | Status |
|---|---|---|
| 1 | Funil comercial do personal (Leads) | ✅ Completo |
| 2 | Dashboard financeiro | ✅ Completo |
| 3 | Cobrança e inadimplência inteligentes | ✅ Completo |
| 4 | Alertas de risco de abandono | ✅ Completo |
| 5 | Relatório de evolução do aluno | ❌ Pendente |
| 6 | Histórico de engajamento | ❌ Pendente |
| 7 | Templates e duplicação de treino | ❌ Pendente |
| 8 | Ações em massa | ❌ Pendente |
| 9 | Agenda operacional avançada | ❌ Pendente |
| 10 | IA copiloto do personal | ❌ Pendente |
| 11 | IA progressão — aceitar sugestão | ❌ Pendente |
| 12 | Vídeo com feedback técnico | ❌ Pendente |
| 13 | Onboarding premium (fluxo guiado) | ❌ Pendente |
| 14 | White-label / identidade própria | ❌ Pendente |
| 15 | Diferenciais de escala e retenção | ❌ Pendente |

Para implementar os epics, use o prompt em `FOCUX_EPICS_PROMPT.md` na raiz do projeto pai.

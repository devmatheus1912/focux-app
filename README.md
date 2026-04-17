# Focux — App Mobile

> Aplicativo Flutter para personal trainers independentes gerenciarem alunos, treinos, finanças e negócio numa única plataforma.

## Sobre o Projeto

O Focux App é o cliente mobile da plataforma Focux — um SaaS multi-tenant para personal trainers. O aplicativo suporta dois perfis de usuário com fluxos completamente distintos:

- **Personal Trainer** — gestão de alunos, treinos, financeiro, CRM, alertas e IA
- **Aluno** — execução de treinos, chat com o personal, feed de conteúdo e assistente IA

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3.29.3 |
| Gerência de estado | Riverpod |
| Navegação | GoRouter |
| HTTP | Dio |
| Storage seguro | flutter_secure_storage / SharedPreferences (web) |
| WebSocket | stomp_dart_client (STOMP) |
| Push notifications | Firebase Messaging |
| Markdown | flutter_markdown |
| Vídeo | video_player |
| Gráficos | fl_chart |
| PDF | pdf + printing |

## Estrutura

```
lib/
├── core/
│   ├── api/          # ApiClient — Dio com interceptor JWT
│   ├── router/       # AppRouter — todas as rotas (GoRouter)
│   ├── storage/      # SecureStorage — token, role, isAdmin
│   └── theme/        # AppTheme
└── features/
    ├── admin/        # Painel admin da plataforma
    ├── agenda/       # Agenda de atendimentos
    ├── alertas/      # Score de risco de abandono
    ├── alimentar/    # Plano alimentar
    ├── alunos/       # Lista, detalhe, cadastro
    ├── anamnese/     # Ficha de anamnese
    ├── assinatura/   # Planos e assinatura
    ├── auth/         # Login, registro, splash
    ├── avaliacao/    # Avaliação física
    ├── checkin/      # Execução de treino + histórico
    ├── chat/         # Chat Personal ↔ Aluno (WebSocket)
    ├── convites/     # Convite para onboarding do aluno
    ├── dashboard/    # Dashboard do personal e do aluno
    ├── exercicios/   # Biblioteca (GIF + vídeo)
    ├── feed/         # Feed de conteúdo privado
    ├── financeiro/   # Mensalidades, PIX, dashboard financeiro
    ├── ia/           # IA: treino, dieta, progressão, chat
    ├── leads/        # CRM — funil comercial
    ├── onboarding/   # Onboarding inicial
    ├── perfil/       # Perfil do personal
    ├── relatorio/    # Relatório de aderência
    └── treinos/      # Treinos com exercícios ordenados
```

## Funcionalidades

### Personal Trainer

| Módulo | Descrição |
|---|---|
| **Dashboard** | Métricas de alunos ativos, acesso rápido a todos os módulos |
| **Alunos** | Lista com badge de inadimplência e risco, detalhe completo, anamnese, avaliação física, plano alimentar |
| **Funil de Leads** | CRM com status (Lead → Teste → Ativo), filtros, ações rápidas (ligar, WhatsApp), conversão em aluno |
| **Financeiro** | Dashboard com gráfico de evolução mensal (fl_chart), mensalidades, geração de PIX, registro de cobrança |
| **Alertas de Risco** | Score por aluno baseado em dias sem treino e taxa de aderência; thresholds configuráveis |
| **Treinos** | Criação, adição de exercícios com séries/repetições, atribuição por aluno |
| **Exercícios** | Biblioteca com upload de GIF (Cloudinary) e vídeo |
| **Check-in** | Acompanha execuções dos alunos em tempo real |
| **Agenda** | Agendamento e gestão de atendimentos |
| **Chat** | WebSocket STOMP bidirecional com aluno |
| **Feed** | Publicação de conteúdo para alunos |
| **IA** | Geração de treino, dieta e progressão de carga com Claude AI; exportação em PDF |
| **Relatório** | Taxa de aderência por aluno e período |
| **Assinatura** | Planos FREE / PRO / PREMIUM via MercadoPago |
| **Painel Admin** | Estatísticas da plataforma e gestão de personais *(acesso restrito)* |

### Aluno

| Módulo | Descrição |
|---|---|
| **Dashboard** | Acesso aos treinos, feed, chat e IA |
| **Check-in** | Executa treino com registro de séries e cargas, histórico completo |
| **Chat** | Conversa com o personal em tempo real |
| **Feed** | Conteúdo publicado pelo personal |
| **Assistente IA** | Chat com IA para dúvidas sobre treino e nutrição |

## Rodando Localmente

**Pré-requisitos:** Flutter 3.29.3+

```bash
git clone https://github.com/devmatheus1912/focux-app.git
cd focux_app
flutter pub get
flutter run
```

Por padrão conecta ao backend em produção (`https://focux-backend-production.up.railway.app`).

## Build Release (Android)

```bash
flutter build appbundle --release
```

O `.aab` gerado é enviado ao Google Play Console.

## Backend

Repositório: [devmatheus1912/focux-backend](https://github.com/devmatheus1912/focux-backend)  
API em produção: `https://focux-backend-production.up.railway.app`

---

## Roadmap

| # | Funcionalidade | Status |
|---|---|---|
| 1 | Funil de Leads (CRM) | ✅ |
| 2 | Dashboard financeiro com gráficos | ✅ |
| 3 | Cobrança e inadimplência inteligentes | ✅ |
| 4 | Alertas de risco de abandono | ✅ |
| 5 | Relatório de evolução do aluno | 🔲 |
| 6 | Histórico de engajamento | 🔲 |
| 7 | Templates e duplicação de treino | 🔲 |
| 8 | Ações em massa sobre alunos | 🔲 |
| 9 | Agenda operacional avançada | 🔲 |
| 10 | IA copiloto do personal | 🔲 |
| 11 | Aceitar/editar sugestão de progressão | 🔲 |
| 12 | Análise de vídeo com feedback técnico | 🔲 |
| 13 | Onboarding guiado premium | 🔲 |
| 14 | White-label / identidade própria | 🔲 |
| 15 | Ferramentas de escala e retenção | 🔲 |

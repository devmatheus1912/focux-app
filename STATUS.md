# Focux — Status do Projeto

> Leia este arquivo no início de cada conversa para ter contexto completo sem precisar varrer os projetos.
> Atualizar sempre que algo for concluído ou planejado.

---

## Repositórios

| Projeto | Caminho local | GitHub | Deploy |
|---|---|---|---|
| Backend | `Projetos Intellij/focux-backend/` | `devmatheus1912/focux-backend` | Railway (branch `master`) |
| App Flutter | `Projetos Intellij/focux_app/` | `devmatheus1912/focux-app` | — |

**Backend URL:** `https://focux-backend.up.railway.app`  
**Health check:** `GET /actuator/health`

---

## Stack

- **Backend:** Java 21 + Spring Boot 3.4.4 + PostgreSQL + Flyway + JWT (jjwt 0.12.5)
- **Flutter:** 3.29.3 — Riverpod + GoRouter + Dio + FlutterSecureStorage
- **Pagamentos:** MercadoPago SDK 2.1.7
- **Mídia:** Cloudinary
- **Sem Lombok** (incompatível com JDK 25 local)

---

## Fase 1 — Fundação SaaS ✅ COMPLETA

### Backend
| Módulo | Endpoint(s) | Status |
|---|---|---|
| Auth Personal | `POST /api/auth/register/personal` `POST /api/auth/login` | ✅ |
| Auth Aluno | `POST /api/auth/register/aluno` `POST /api/auth/login/aluno` | ✅ |
| Alunos | `GET/POST /api/alunos` `GET /api/alunos/{id}` | ✅ |
| Convites | `POST /api/convites/gerar` | ✅ |
| Dashboard | `GET /api/dashboard/personal` | ✅ |
| Perfil | `GET/PUT /api/personal/perfil` | ✅ |
| Planos | `GET /api/planos` | ✅ |
| Pagamento | `POST /api/pagamentos/preferencia/{planoId}` | ✅ |
| Webhook MP | `POST /api/webhooks/mercadopago` | ✅ |

### Flutter
| Tela | Rota | Status |
|---|---|---|
| Splash | `/` | ✅ |
| Login | `/login` | ✅ |
| Cadastro Personal | `/register` | ✅ |
| Dashboard Personal | `/dashboard/personal` | ✅ |
| Dashboard Aluno | `/dashboard/aluno` | ✅ (placeholder) |
| Lista de Alunos | `/alunos` | ✅ |
| Novo Aluno | `/alunos/novo` | ✅ |
| Detalhe Aluno | `/alunos/:id` | ✅ |
| Perfil Personal | `/perfil` | ✅ |
| Editar Perfil | `/perfil/editar` | ✅ |
| Convites | `/convites` | ✅ |
| Planos / Assinatura | `/planos` | ✅ |

### Banco (Flyway)
```
V1  planos_saas
V2  personais
V3  alunos
V4  convites
V5  seed planos (FREE/PRO/PREMIUM)
V6  alter alunos.status → VARCHAR(20)
```

---

## Fase 2 — Core Fitness 🔄 EM ANDAMENTO

### Backend
| Módulo | Endpoint(s) | Status |
|---|---|---|
| Exercícios | `GET/POST /api/exercicios` `GET/PUT/DELETE /api/exercicios/{id}` `POST /api/exercicios/{id}/gif` | ✅ |
| Treinos | `GET/POST /api/treinos` `GET /api/treinos/{id}` `POST /api/treinos/{id}/exercicios` `POST /api/treinos/{id}/atribuir` | ✅ |
| Check-in | `GET /api/checkin/meus-treinos` `POST /api/checkin/iniciar` `PUT /api/checkin/{id}/exercicio/{eid}` `PUT /api/checkin/{id}/concluir` `GET /api/checkin/historico` | ✅ |
| Anamnese | `POST/GET /api/alunos/{id}/anamnese` | ⏳ migration V11 criada, código pendente |
| Avaliação física | medidas + fotos + gráficos | ❌ não iniciado |
| Plano alimentar | macros | ❌ não iniciado |

### Flutter
| Tela | Rota | Status |
|---|---|---|
| Lista de Exercícios | `/exercicios` | ✅ |
| Novo Exercício + GIF | `/exercicios/novo` | ✅ |
| Detalhe Exercício | `/exercicios/:id` | ✅ |
| Lista de Treinos | `/treinos` | ✅ |
| Criar Treino | `/treinos/novo` | ✅ |
| Detalhe Treino | `/treinos/:id` | ✅ |
| Check-in Aluno | `/checkin/treinos` `/checkin/executar` `/checkin/historico` | ✅ |
| Anamnese | a definir | ❌ não iniciado |
| Avaliação física | a definir | ❌ não iniciado |

### Banco (Flyway)
```
V7  exercicios
V8  treinos + treino_exercicios + aluno_treinos
V9  aluno_treinos (relação treino→aluno)
V10 indexes de performance
V11 execucao_treinos + execucao_exercicios (check-in) — migration criada, código pendente
```

---

## Fase 3 — IA + Comunicação ❌ Não iniciada

- Gerador treino/dieta com Claude API
- Chatbot do aluno 24h
- Chat WebSocket
- Push notifications FCM
- Vídeos nos exercícios
- Feed de conteúdo privado

---

## Fase 4 — Negócio do Personal ❌ Não iniciada

- Financeiro (mensalidades + PIX automático + bloqueio inadimplente)
- Agenda
- Relatório de aderência
- White-label

---

## Fase 5 — Escala ❌ Não iniciada

- IA avançada (progressão de carga, PDF)
- Painel admin Focux
- Onboarding wizard
- App Store / Google Play

---

## Variáveis de ambiente (Railway)

```
PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD  ← via ${{Postgres.*}}
JWT_SECRET
APP_URL = https://focux-backend.up.railway.app
MP_ACCESS_TOKEN
CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET
```

---

## Regras importantes

- **Sem Lombok** — construtores, getters e setters explícitos
- **Sem `Co-Authored-By: Claude`** nos commits
- `personal_id` nunca vem da requisição — sempre do `TenantContext` (JWT)
- Exceções de negócio: `FocuxException` → `GlobalExceptionHandler`
- Deploy: push em `master` → Railway faz deploy automático
- Testes: `@SpringBootTest` + `@AutoConfigureMockMvc` + `@Transactional`

---

## Próximos passos (Fase 2)

1. ~~Check-in de treino~~ ✅
2. **Anamnese** — backend + Flutter (formulário histórico de saúde)
3. **Avaliação física** — medidas corporais + fotos comparativas
4. **Plano alimentar** — macros por refeição

*Última atualização: 2026-04-14*

# Focux App

Aplicativo mobile do **Focux** — plataforma SaaS para personal trainers gerenciarem alunos, exercícios e treinos.

## Visão Geral

O Focux App é o cliente mobile da plataforma Focux. Suporta dois perfis de usuário:

- **Personal Trainer** — gerencia alunos, cria exercícios/treinos, controla assinatura
- **Aluno** — visualiza seus treinos atribuídos pelo personal

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3.29.3 |
| Estado | Riverpod (flutter_riverpod) |
| Navegação | GoRouter |
| HTTP | Dio |
| Storage seguro | flutter_secure_storage |
| Links externos | url_launcher |

## Estrutura do Projeto

```
lib/
├── core/
│   ├── api/            # ApiClient (Dio + interceptor JWT)
│   ├── router/         # AppRouter (GoRouter — todas as rotas)
│   ├── storage/        # SecureStorage (token JWT)
│   └── theme/          # AppTheme
└── features/
    ├── auth/           # Login, Register, Splash
    ├── alunos/         # Lista, detalhe e cadastro de alunos
    ├── assinatura/     # Planos e assinatura (MercadoPago)
    ├── convites/       # Convidar alunos por e-mail
    ├── dashboard/      # Dashboard do personal e do aluno
    ├── exercicios/     # Biblioteca de exercícios com GIF
    ├── perfil/         # Perfil do personal
    └── treinos/        # Treinos com exercícios ordenados
```

Cada feature segue a estrutura `data/` → `providers/` → `screens/`.

## Funcionalidades

### Personal Trainer
- **Dashboard** — métricas de alunos ativos, limite do plano e acesso rápido ao menu
- **Alunos** — listar, cadastrar e visualizar detalhes dos alunos
- **Convites** — enviar convite por e-mail para o aluno criar conta
- **Exercícios** — criar e gerenciar biblioteca de exercícios (com GIF, músculo-alvo, categoria)
- **Treinos** — criar treinos, adicionar exercícios com séries/repetições/carga/descanso
- **Perfil** — editar informações do perfil
- **Assinatura** — visualizar plano atual e fazer upgrade via MercadoPago

### Aluno
- **Dashboard** — visualizar treinos atribuídos pelo personal

## Navegação

| Rota | Tela |
|---|---|
| `/` | SplashScreen (decide para onde redirecionar) |
| `/login` | Login |
| `/register` | Cadastro |
| `/dashboard/personal` | Dashboard do personal |
| `/dashboard/aluno` | Dashboard do aluno |
| `/alunos` | Lista de alunos |
| `/alunos/novo` | Cadastrar aluno |
| `/alunos/:id` | Detalhe do aluno |
| `/exercicios` | Lista de exercícios |
| `/exercicios/novo` | Criar exercício |
| `/exercicios/:id` | Detalhe do exercício |
| `/treinos` | Lista de treinos |
| `/treinos/novo` | Criar treino |
| `/treinos/:id` | Detalhe do treino |
| `/treinos/:id/exercicios/add` | Adicionar exercício ao treino |
| `/convites` | Gerenciar convites |
| `/perfil` | Perfil do personal |
| `/perfil/editar` | Editar perfil |
| `/planos` | Planos e assinatura |

## Rodando Localmente

**Pré-requisitos:** Flutter 3.29.3+, Dart SDK

1. Clone o repositório:
```bash
git clone https://github.com/devmatheus1912/focux-app.git
cd focux_app
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure a URL da API em `lib/core/api/api_client.dart` (por padrão aponta para o backend em produção no Railway).

4. Execute:
```bash
flutter run
```

## Autenticação

O app armazena o JWT no `flutter_secure_storage`. O `ApiClient` injeta o token automaticamente em todas as requisições via interceptor do Dio. Na inicialização, o `SplashScreen` verifica o token e redireciona para o dashboard correto (personal ou aluno) ou para o login.

## Backend

O app se comunica com a API REST do **focux-backend**:

- Repositório: [devmatheus1912/focux-backend](https://github.com/devmatheus1912/focux-backend)
- Produção: `https://focux-backend.up.railway.app`

# Changelog

Mudanças do app publicadas nas lojas, da mais nova para a mais antiga. O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/). A versão vem do `pubspec.yaml`; cada versão publicada tem uma tag `vX.Y.Z`.

## Não lançado (`develop`)

### Alterado
- Erro do login com Google aparece em texto para o usuário ("Não deu para entrar com Google. Use e-mail e senha.") em vez da mensagem técnica.
- Dependências do pub e do E2E atualizadas (versões menores).
- Documentação oficial do repositório: arquitetura, design system, produto, release, política de segurança, guia de contribuição e modelos de PR e issue. Os scripts de `tools/` foram para `tool/`, e as regras do Cursor saíram do Git.

### Marca
- Guia de marca (`brand/brand_guidelines.md`) e kit do logo v2 em `brand/kit/`. O app ainda usa o logo anterior até a troca dos arquivos.

## 1.2.5+241 · 17/11/2026

Aprovada na App Store e no Google Play.

### Adicionado
- Métodos por série: progressão (fixa, pirâmide crescente e decrescente) e técnica de intensidade por série (drop-set, rest-pause, pico, excêntrica, isometria, parciais).
- Treino sem internet: a semana fica no aparelho e as sessões sobem quando a rede volta.
- Modo presencial: o personal conduz o treino do aluno pelo próprio app.
- Economia de dados: vídeos dos exercícios guardados no aparelho; no dado móvel o vídeo só toca com um toque.

### Alterado
- Vídeo gravado em pé aparece inteiro na biblioteca, no feed e no feedback.
- Resposta do suporte (Intercom) chega por push.

### Removido
- Leitura de HRV no Android (recusada pelo Google Play). O iPhone segue lendo.

### Corrigido
- Upload não entra mais na fila offline.
- A aba Treinos voltou a abrir a prévia depois de iniciar um treino.

### Segurança
- Reinstalar o app não herda a sessão anterior do Keychain.
- Token de ativação não vai mais para o Sentry.

## 1.2.4 · 16/11/2026

Primeira versão aprovada na App Store com usuários reais.

## 1.2.2 e anteriores

Versões de teste e revisão antes do lançamento público. O histórico está no Git.

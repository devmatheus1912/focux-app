# Changelog

Mudanças do app publicadas nas lojas, da mais nova para a mais antiga. O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/). A versão vem do `pubspec.yaml`; cada versão publicada tem uma tag `vX.Y.Z`.

## Não lançado (`develop`)

## 1.2.6+242 · 20/11/2026

### Adicionado
- Perfil > Notificações (personal e aluno): estado do celular, o que avisar por tipo, som do fim do descanso e notificação de teste. No iOS, "Ajustes de notificação do Focux" abre a tela; no Android, um canal por tipo.
- Fim do descanso avisa com a tela bloqueada ou o app em segundo plano (notificação agendada; no Android, contagem regressiva na tela de bloqueio).
- Aviso de versão nova: folha "Nova versão disponível" (uma vez por versão) e tela de bloqueio abaixo da versão mínima; no Android, atualização pela própria Play.
- Cadastro de exercício: "Preparando vídeo…" enquanto o celular entrega o arquivo, Cadastrar espera o vídeo, envio com progresso ("Enviando vídeo 42%", "Processando vídeo…"), recusa de vídeo da galeria acima de 60 s e confirmação ao sair durante o envio.
- Lançar mensalidade sem chave PIX avisa antes, com "Cadastrar chave" e "Lançar mesmo assim".

### Alterado
- Aba Exercícios: Meus · Biblioteca · Favoritos, a mesma linha da biblioteca do "Adicionar exercício", busca com chips de grupo e equipamento, "⋯" em folha (Assistir, vídeo, Editar, Duplicar, Excluir com o efeito) e topo que conta exercícios.
- Aluno sem PIX do personal: a folha do PIX oferece "Falar com o personal" e "Já paguei".
- Feedback em vídeo: "Remover este vídeo" saiu da folha de resposta (fica no "⋯"); falha do áudio aparece em texto claro.
- "Wi‑Fi", "e‑mail" e "check‑in" não partem mais no fim da linha.
- Erro do login com Google aparece em texto para o usuário ("Não deu para entrar com Google. Use e-mail e senha.") em vez da mensagem técnica.
- Dependências do pub e do E2E atualizadas (versões menores).
- Documentação oficial do repositório: arquitetura, design system, produto, release, política de segurança, guia de contribuição e modelos de PR e issue. Os scripts de `tools/` foram para `tool/`, e as regras do Cursor saíram do Git.

### Corrigido
- Revisar cargas: exercício sem carga na ficha recebendo carga ("Sem carga → 17 kg", pílula "Carga nova") e troca só de séries/repetições contam como mudança, vêm marcados e o botão aplica; o resumo conta essas mudanças; editar a carga de uma linha que ficava igual a marca; sem nada para aplicar, o botão some e a nota explica.
- Build do iOS: `facebook_app_events` volta para 0.31.0 (a 0.33 do Dependabot traz um SDK do Facebook que não compila no Xcode 26.3).
- Push volta a registrar o aparelho. Android: `google-services.json` com a chave de API atual (a da 1.2.5 tinha expirado na rotação). iOS: o token do FCM só é pedido depois que o token APNs chega (até 10 s). Falha no registro vai ao Sentry como aviso, sem o token.

### Marca
- Guia de marca (`brand/brand_guidelines.md`) e kit do logo v2 em `brand/kit/`.
- Logo v2 no app inteiro: logos das telas e do PDF, ícone do iOS e do Android (braço branco sobre `#0B4F5C`), ícone de notificação, splash e ícones da versão web, todos gerados do kit. No escuro, o símbolo usa o petróleo `#0E93A8`.
- Tema escuro no chão petróleo do guia: fundo `#0A1A1F`, superfície `#10262C`, superfície alta `#16323A`, borda `#1B3A42`, sem os brilhos do fundo. Splash nativo no mesmo chão.
- Fundo claro em paper `#F4F6F8` sólido, sem degradê nem brilhos (`FxChao` no lugar do antigo fundo em malha). A marca própria com estilo Cinematográfico tinge a cor, ainda sólida. O logo anterior saiu de `brand/legado/`.

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

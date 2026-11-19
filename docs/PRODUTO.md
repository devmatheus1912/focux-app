# Produto

O que é o Focux Personal, para quem é e quais princípios guiam as decisões de produto. Vale para o app, a API e o site.

## O que é

**Quem treinou, quem pagou e quem sumiu.** App de gestão para personal trainer.

O personal opera a assessoria no celular: alunos, fichas de treino, agenda, cobrança com PIX, IA e marca própria. O aluno treina, faz check-in série a série, acompanha a evolução e fala com o personal, no mesmo app.

- **Em produção** desde novembro de 2026, na App Store e no Google Play, com usuários reais.
- **Mercado:** Brasil. Português do Brasil, PIX, NFS-e e reais (ver ADR 002 do backend).
- **Site:** [focuxpersonal.com](https://focuxpersonal.com).

## Para quem

| Pessoa | O que precisa |
|---|---|
| **Personal trainer** (principal), com consultoria online primeiro | Saber em segundos quem precisa de atenção hoje, montar treino rápido, cobrar sem constrangimento e não perder aluno |
| **Aluno do personal** | Treinar com o treino certo, registrar a série mesmo sem sinal na academia e ver a própria evolução |
| **Equipe do personal** (co-personal, secretária) | Operar o espaço do dono com acesso limitado por papel |

## O que o app faz

**Personal:** tela Hoje (o que pede ação agora), alunos e Aluno 360, fichas e biblioteca de exercícios com vídeo, modo presencial, agenda e aulas em grupo, financeiro com PIX, IA Focux (Copiloto e Ajustar cargas), captação e página de vendas, automações, desafios e marca própria.

**Aluno:** treino do dia com vídeo, check-in com carga e RPE (funciona sem internet), histórico, evolução (medidas, fotos, recordes, metas), saúde pelo Apple Saúde e Health Connect, agenda, chat e notificações.

## Planos

Assinatura só pela App Store e pelo Google Play (compra no app). O site não vende.

| Plano | Resumo |
|---|---|
| **Free** | Até 3 alunos, sem cobrança |
| **Pro** | Até 50 alunos, financeiro com PIX, IA Focux (200 usos por mês), interessados, relatórios, hábitos, feedback em vídeo, importação por foto (25 por mês). 30 dias grátis na primeira assinatura mensal |
| **Enterprise** | Sem limite de alunos, marca própria (com opção de ocultar a marca Focux), página de vendas, venda de planos com PIX, desafios com ranking, mensagens automáticas, reconquista, equipe com permissões, IA (600 usos por mês), importação por foto (80 por mês) |

Os números da oferta moram em `client/src/lib/data.ts` do site e nas travas do backend (`planos/Feature`). Mudou um, muda o outro.

**Marca própria** é aplicada dentro do app Focux (logo, paleta e um de três estilos). Não existe app separado nas lojas.

## Princípios

1. **Hoje primeiro.** Toda tela do personal responde "quem precisa de mim agora e o que eu faço".
2. **Funciona na academia.** O fluxo do aluno não depende de sinal bom nem de muitos toques.
3. **Um lugar, uma verdade.** O mesmo dado mostra o mesmo valor em todas as telas; cada conta mora num lugar só.
4. **Marca do personal, produto do Focux.** O aluno sente que é o app do personal dele.
5. **Dado de saúde é sensível.** Consentimento explícito, nada vaza entre contas e nada sobra no aparelho depois de sair.
6. **Nada inventado.** Nenhum depoimento, número de resultado ou cliente fictício, no app, no site ou nas lojas.

## Voz

Português brasileiro direto e humano, sem jargão de academia nem de tecnologia. A tela inicial se chama **Hoje**. Não usar "sistema operacional" nem "tudo em um só lugar". Detalhes no [guia de marca](../brand/brand_guidelines.md).

## Como uma feature nasce

Conversa, depois uma spec (`SPEC-<nome>.md` no workspace) aprovada antes do código. Implementada a spec, as regras que ficam valendo entram no mapa do projeto e a spec é apagada.

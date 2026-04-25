# Focux App — Status de Design (Análise de Fidelidade ao Handoff)

Atualizado em: 25/04/2026
Baseado em: análise completa do arquivo `Focux Personal Design.html` comparado ao app atual

---

## RESULTADO GERAL

🔴 **Divergências críticas identificadas** — o app funciona, mas há diferenças visuais substanciais em relação ao design oficial. O usuário reportou corretamente: as telas estão mais claras que o design e a logo ficou mais escura. A análise abaixo cobre todas as telas.

---

## PROBLEMAS CRÍTICOS — Bloqueadores Visuais

### 1. Navegação global: Floating Glass Dock ausente

O design usa um dock flutuante glassmorphism na parte inferior da tela (estilo iOS 26), com borda arredondada, blur e 5 abas: Hoje, Alunos, Treinos, Finance, IA. O dock está posicionado 18px acima da borda inferior, tem borderRadius de 28px, fundo translúcido com blur de 24px e saturação de 180%, sombra externa grande e borda inset de 0.5px.

Situação atual: a navegação usa a NavigationBar padrão do Material Design colada na borda inferior. O drawer hambúrguer presente no dashboard não existe no design — o design mostra apenas lockup + data + sino + avatar no topo sem menu lateral.

Impacto: é o elemento visual mais diferente. Define toda a identidade de navegação do produto.

---

### 2. Logo: F-eagle aparece escura e apagada

O design usa a imagem original com fundo preto renderizada com `mix-blend-mode: screen`, o que faz o fundo preto desaparecer e deixa o F-eagle brilhante em azul/branco sobre o tile escuro. O resultado visual é um F luminoso, com brilho, sobre o gradiente azul-escuro.

Situação atual: o `logo_icon.png` do Flutter é RGBA (fundo branco/transparente). A imagem é exibida em 130% do tamanho do tile com clip, mas sem modo de blend. O F-eagle aparece na sua cor natural sem o brilho extra que o screen blend confere. O usuário percebeu que ficou mais escuro — correto, pois o screen blend torna as cores mais brilhantes que o compositing normal.

Solução necessária: implementar o blend com BlendMode.screen usando CustomPainter que desenha o gradiente de fundo e depois a imagem com blendMode screen, ou buscar uma versão da imagem com fundo preto transparente via alpha adequado.

---

### 3. Botão primário de auth: sem gradiente e sem sombra

O design define o botão primário com gradiente linear de 135 graus de brand para brandInk e uma sombra de 8px blur -8px offset na cor brand com 60% de opacidade. O efeito dá profundidade e premium ao botão.

Situação atual: o `AuthPrimaryButton` usa cor sólida `EagleTokens.brand` sem gradiente e sem sombra. Parece plano comparado ao design.

---

### 4. Hero card do dashboard: label errado e subtítulo errado

O design mostra "Receita · abril" em minúsculas (11px Inter, espaçamento 0.12em) e ao lado do valor exibe o previsto como "/ 11.750" — ou seja, o divisor mostra a previsão de receita do mês, não "/ mês".

Situação atual: o texto exibe "RECEITA · ABRIL" em maiúsculas com letterSpacing de 1.5, e o subtítulo mostra "/ mês" fixo. Dois erros: casing errado e dado errado.

Os três mini-stats do rodapé do hero card no design são PENDENTE / INADIMPL. / TICKET. O app atual mostra PREVISÃO / INADIMPL. / TICKET. O primeiro stat está errado — deve ser o valor pendente, não a previsão.

---

### 5. Seção de atalhos do dashboard: título e conteúdo errados

O design chama a seção de "Atalhos" e lista 6 ações rápidas orientadas a tarefas: Gerar treino IA, Novo aluno, Agenda, Mensagens, Cobrar PIX, Leads.

Situação atual: a seção se chama "Ferramentas" e lista links de navegação: Alunos, Exercícios, Treinos, Financeiro, Agenda, Feed, Planos, Migracao, Acessos. São 9 itens de navegação em vez de 6 atalhos de ação.

---

## PROBLEMAS ALTOS — Diferenças Visuais Grandes

### 6. QuickTile layout: Spacer entre ícone e valor está errado

O design coloca o ícone no canto superior esquerdo (30×30px, borderRadius 10, fundo brandSoft) e o valor logo abaixo com marginTop de 10px. Depois vêm o label e o sub. Não há espaçamento extra empurrando o valor para baixo.

Situação atual: o `_QuickTile` usa `Spacer()` entre o ícone e o valor, empurrando o número para o fundo do tile. Isso distorce a hierarquia visual — o número (28px bold) deveria vir logo depois do ícone, não colado na base.

---

### 7. Tipografia: Space Grotesk não aplicado em todas as telas

O design usa Space Grotesk para todos os textos de exibição (títulos de seção com 20px, titles com 32px, números grandes do hero). Inter é reservado para texto de corpo (labels, legendas, descrições).

Situação atual: revisão necessária em todas as telas. Os títulos de seção no dashboard, cabeçalhos de telas de alunos, financeiro, perfil precisam usar Space Grotesk. Em muitos lugares o font-family não está sendo especificado e cai para o padrão do tema.

---

### 8. Onboarding: tile de ícone sem glow dinâmico de cor

O design exibe nos slides de onboarding um tile de 120×120px com bordas, backdrop-blur, e uma sombra de 60px no tom da cor de destaque de cada slide. Cada slide tem seu próprio accent color (azul claro, mais claro, azul gelo) que cria um ambiente de luz diferente.

Situação atual: precisaria verificar a tela de onboarding. Se o glow dinâmico não estiver implementado, o slide parece genérico.

---

### 9. Telas de auth mais claras que o design

O design foi analisado nas duas variantes. A variante padrão light usa gradiente radial de `#1836A0 → #0D1B5C → #070F33`. A variante dark usa `#1A3A7A → #060C1E → #020818`.

O usuário reporta que as telas estão mais claras que o design enviado como referência. Isso indica que as screenshots de referência eram do modo dark e o app está renderizando o modo light. Ou o gradiente precisa de ajuste de posição ou intensidade.

---

### 10. Ícones: Material Icons vs FxIcon SVG personalizado

O design usa um conjunto próprio de ícones SVG stroke-based monoline para toda a interface: dumbbell, coin, spark, home, users, bell, check, warn, flame, clock, pix, chat, trend, filter, send, play, dots, chev, chevDown, etc.

Situação atual: o app usa Material Icons (Icons.people, Icons.fitness_center, Icons.attach_money, etc.). Visualmente são muito diferentes — o FxIcon tem stroke width menor (1.8-2.2), estilo mais fino e geométrico.

---

## PROBLEMAS MÉDIOS — Diferenças Perceptíveis

### 11. Avatares: iniciais de 1 caractere em vez de 2

O design exibe as iniciais de primeiro e último nome (exemplo: "MR" para Matheus Ribeiro). A função `FxAvatar` pega as primeiras letras de cada palavra do nome separado por espaços.

Situação atual: vários lugares no app pegam apenas `nome[0]` — uma letra só.

---

### 12. Tela de alunos: falta o chip "Novos" nos filtros

O design lista 5 chips: Todos, Ativos, Inadimplentes, Risco alto, Novos. O enum `AlunoFiltro` atual tem apenas 4 opções — Novos está ausente.

---

### 13. Tela de treino (detalhe): hero full-bleed não implementado

O design mostra um hero de tela cheia com gradiente, grid texture sutil em branco com 6% de opacidade, tile de capa do treino (108×108px), dados do treino (duração, exercícios, volume em kg), e 3 botões de ação (Iniciar treino, Compartilhar, Mais). Abaixo vem uma ribbon de 3 métricas e a lista de exercícios agrupada por grupo muscular.

Precisaria verificar o estado atual da tela de treino.

---

### 14. Tela de check-in: toda a tela é complexa e nova

O design tem: barra de status de treino em andamento, timer gigante (56px Space Grotesk), barra de progresso fina, card do exercício atual com grid de séries (número, reps, carga, RPE, status), card de sugestão IA com gradiente azul e mini gráfico de evidência, card do aluno, e um rest timer flutuante acima do dock.

É uma das telas mais elaboradas do design. Precisaria verificar se foi implementada.

---

### 15. Tela de financeiro: ring de progresso e bar chart

O design mostra um hero card com SVG de anel circular (120×120px) mostrando o percentual recebido do previsto, ao lado dos valores. Abaixo há uma grid 3×1 de métricas (Pendente, Ticket, Acumulado) e um bar chart de 6 meses com barras gradiente para o mês atual.

---

### 16. Tela de chat: bolhas com gradiente para o personal

O design usa gradiente linear de 135 graus brand→brandInk nas bolhas do personal, com borderRadius assimétrico. As bolhas do aluno têm fundo branco/darkCardHi com border. Header tem avatar com ponto verde de online, botões de IA e more.

---

### 17. Tela de IA Copiloto: segmented control e result card

O design tem um seletor segmentado (Treino / Dieta / Progressão) em estilo pill com o ativo preenchido de brand, chips de contexto do aluno, card de progresso de geração com checkmarks, e result card com header gradiente mostrando duração/frequência/exercícios.

---

## PROBLEMAS BAIXOS — Polimento Final

### 18. Borders em telas além do dashboard

O padrão do design usa `border: 1px solid line` em todos os cards de todas as telas em modo light. Nas telas de financeiro, treino, check-in, perfil, chat e IA, os cards precisam ter essa borda. Corrigido no dashboard mas não nas demais telas.

---

### 19. Seção "Aderência da semana" do dashboard: sem dados reais de sparkline

O design mostra sparkline por aluno com dados reais de aderência semanal. A implementação atual usa dados estáticos/mock para os 3 alunos exibidos.

---

### 20. Perfil: hero com grid texture e stat strip de 4 colunas

O design mostra a tela de perfil com hero gradiente + grid texture (padrão de linhas brancas 6% opacidade, 26×26px) e uma strip de 4 stats colada na borda inferior do hero com fundo semitransparente e blur. Precisaria verificar o estado atual.

---

### 21. Verificação dos tokens de cor dark

Valores do design para dark mode: `darkBg: #0A0F1E`, `darkCard: #121A30`, `darkCardHi: #1A2442`, `darkLine: #1F2B4A`, `darkInk: #F3F4F8`, `darkInkMute: #8A94AE`. Verificar se `EagleTokens` bate exatamente nesses hexadecimais — qualquer desvio acumula diferença visual.

---

### 22. Divisores com espessura 0.5px

O design usa separadores de 0.5px entre itens de lista (alunos, exercícios, treinos, chat). Verificar se os `BorderSide` e `Divider` usam width de 0.5 em toda a app.

---

## O QUE FOI FEITO NESTA RODADA (commits anteriores)

- Design tokens de raio adicionados ao EagleTokens
- AppTheme reescrito com ColorScheme explícito e textTheme completo com Space Grotesk e Inter
- FxLogo e AuthLogoMark convertidos de círculo/glassmorphism para tile quadrado arredondado com gradiente azul-escuro
- FxSparkline com end-dot de 2.5px no último ponto
- Hero do dashboard com gradiente animado (8s) e counter animado de receita
- Cards do dashboard corrigidos de BoxShadow spread para border.all
- flutter analyze limpo

---

## PRIORIDADE DE IMPLEMENTAÇÃO SUGERIDA

Alta urgência, máximo impacto visual:

1. Floating glass dock (navegação completa)
2. Logo com blend mode screen (brilho correto do F-eagle)
3. Auth primary button com gradiente e sombra
4. Hero card: corrigir label lowercase e subtítulo para previsão
5. Dashboard shortcuts: renomear seção e mudar conteúdo para 6 ações
6. QuickTile: remover Spacer, valor logo abaixo do ícone

Sequência após esses 6 críticos:

7. Tipografia Space Grotesk em todas as telas
8. Avatares com 2 iniciais
9. Chip "Novos" na tela de alunos
10. Tela de treino hero full-bleed
11. Tela de check-in completa
12. Tela de financeiro com ring e bar chart
13. Chat com bolhas gradiente
14. IA Copiloto completo
15. Polimento: borders em todas as telas, divisores 0.5px, tokens dark verificados

---

## Estado da validação técnica

- flutter analyze: 🟢 sem issues
- flutter build web: 🟢
- Commits desta análise: 5b17eb1, 792e540
- Push em origin/main: 🟢

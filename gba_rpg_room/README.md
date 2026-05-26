# 🎮 Aventura Pokémon GBA - Edição Expandida

Um jogo de RPG estilo Pokémon GBA completo, desenvolvido em HTML5 Canvas e JavaScript puro, totalmente em **português do Brasil**.

## ✨ Novidades da Versão Expandida

### 🗺️ Mapa e Mundo
- **Mapa ampliado**: 40x30 tiles (antes 20x11)
- **8 regiões planejadas**: Vila Inicial, Floresta Misteriosa, Cidade Porto, Monte Lua, Rota 1, Cidade Violeta, Ilha do Tesouro, Caverna Digital
- **16 tipos de tiles**: Grama, água, areia, neve, caverna, grama alta, Centro Pokémon, Loja, Ginásio, e mais!
- **Cores variadas**: Cada tile tem 3 variações de cor para visual mais rico

### 👥 NPCs e Conteúdo
- **15+ NPCs únicos**: Prof. Carvalho, Enfermeira Joy, Ancião, Luna, Treinadores, Vendedora, e mais
- **6 itens coletáveis**: Poção, Super Poção, Poké Ball, Great Ball, Antídoto, Cura Total
- **2 treinadores para batalha**: Treinador Red e Bug Catcher
- **Sistema de diálogos melhorado**: Efeito typewriter com nomes dos NPCs

### ⚔️ Sistema de Batalha
- **Batalhas contra treinadores**: Desafie e derrote treinadores para ganhar dinheiro
- **Encontros selvagens**: Grama alta tem chance de encontrar Pokémon selvagens
- **Sistema simplificado**: Batalhas automáticas baseadas no nível dos Pokémon
- **Recompensas**: Ganhe dinheiro e medalhas ao derrotar líderes de ginásio

### 🕐 Ciclo Dia/Noite
- **Tempo dinâmico**: O relógio do jogo avança automaticamente
- **4 períodos**: Manhã (5h-12h), Dia (12h-17h), Tarde (17h-20h), Noite (20h-5h)
- **Overlay visual**: A tela escurece à noite
- **HUD atualizado**: Mostra horário e período atual

### 🎨 Gráficos Aprimorados
- **Personagens detalhados**: Corpos, cabeças, chapéus/cabelos, sombras
- **Tiles com detalhes**: 
  - Árvores com tronco e copa
  - Flores coloridas (4 cores)
  - Rochas triangulares
  - Água com animação de ondas
  - Grama alta com lâminas
  - Edifícios identificados (P, G)
- **Itens brilhantes**: Efeito de brilho nos itens no chão
- **Poké Balls desenhadas**: Vermelho, branco e botão central

### 📱 Interface
- **Mini-mapa**: Mostra todo o mapa com posição do jogador
- **HUD expandido**: Nome, tempo, medalhas conquistadas
- **Menu com 8 opções**: Mochila, Pokémon, Status, Treinadores, Medalhas, Salvar, Opções, Sair
- **Notificações**: Feedback visual ao coletar itens
- **Fontes retrô**: Fonte "Press Start 2P" do Google Fonts

### 💾 Sistema de Save
- **Save automático**: Progresso salvo no localStorage
- **Dados salvos**: Jogador, região, tempo, flags, itens coletados
- **Carregamento**: Jogo continua de onde parou

## 🎮 Como Jogar

### Controles
```
⬆️⬇️⬅️➡️ ou WASD  - Mover personagem
Z ou Enter         - Ação/Confirmar (Botão A)
X ou Esc           - Menu/Voltar (Botão B)
Espaço             - Avançar diálogo
R                  - Reiniciar posição
```

### Mobile
- D-Pad virtual para movimento
- Botões A e B na tela
- START e SELECT funcionais

## 🏃 Funcionalidades

### Exploração
- ✅ Movimentação em grid 16x16
- ✅ Câmera que segue o jogador
- ✅ Colisão com obstáculos (árvores, pedras, água)
- ✅ Colisão com NPCs e treinadores
- ✅ Coleta automática de itens

### Interação
- ✅ Diálogos com múltiplas linhas
- ✅ Efeito typewriter nos textos
- ✅ Nomes dos NPCs nas caixas de diálogo
- ✅ 6 NPCs interativos na vila inicial

### Combate
- ✅ Desafiar treinadores andando até eles
- ✅ Batalhas automáticas
- ✅ Pokémon selvagens na grama alta
- ✅ Recompensas em dinheiro
- ✅ Sistema de medalhas

### Menu
- ✅ **Mochila**: Ver itens coletados
- ✅ **Pokémon**: Ver time com HP
- ✅ **Status**: Nome, nível, dinheiro, passos, medalhas
- ✅ **Treinadores**: Lista com status de derrota
- ✅ **Medalhas**: Conquistas obtidas
- ✅ **Salvar**: Salvar progresso
- ✅ **Opções**: Ver tempo e região
- ✅ **Sair**: Confirmar saída

## 🗂️ Estrutura de Arquivos

```
gba_rpg_room/
├── index.html          # Estrutura HTML com novos elementos
├── style.css           # CSS aprimorado com efeitos
├── game.js             # Lógica completa do jogo
├── README.md           # Esta documentação
├── assets/             # Assets futuros
├── sprites/            # Sprites futuros
├── maps/               # Mapas futuros
└── audio/              # Áudio futuro
```

## 🎨 Paleta de Cores

### Tiles Principais
| Tile | Cor Principal | Variação 1 | Variação 2 |
|------|--------------|------------|------------|
| Grama | #4a8c3a | #5a9c4a | #3a7c2a |
| Água | #5ba3d0 | #6bb3e0 | #4b93c0 |
| Árvore | #2d5a27 | #3d6a37 | #1d4a17 |
| Flor | #ff69b4 | #ff79c4 | #ff59a4 |
| Rocha | #808080 | #909090 | #707070 |
| Areia | #f4d03f | #ffe04f | #e4c02f |
| Grama Alta | #2d6a27 | #3d7a37 | #1d5a17 |

### Edifícios
| Tipo | Cor | Símbolo |
|------|-----|---------|
| Centro Pokémon | #ff6b6b | P |
| Loja | #4a90d9 | - |
| Ginásio | #d4af37 | G |

## 📊 Estatísticas do Jogo

- **Tamanho do Mapa**: 40x30 = 1,200 tiles
- **Tiles diferentes**: 16 tipos
- **NPCs**: 6 na vila inicial
- **Itens**: 6 coletáveis
- **Treinadores**: 2 para batalhar
- **Pokémon selvagens**: 4 espécies
- **Períodos do dia**: 4 (manhã, dia, tarde, noite)
- **Opções de menu**: 8

## 🚀 Melhorias Técnicas

### Performance
- Renderização otimizada (só desenha tiles visíveis)
- Camera follow suave
- RequestAnimationFrame para 60 FPS

### Código
- Estrutura modular
- Banco de dados de NPCs, itens e treinadores
- Sistema de flags para progresso
- Save/load com localStorage

### Visual
- Sombras nos personagens
- Brilho nos itens
- Animação de ondas na água
- Overlay de dia/noite
- Notificações animadas

## 🎯 Próximas Melhorias Sugeridas

1. **Mais regiões**: Implementar as 7 regiões restantes
2. **Sprites personalizados**: Substituir retângulos por sprites
3. **Sistema de batalha completo**: Turnos, golpes, animações
4. **Áudio**: Músicas e efeitos sonoros
5. **Mais Pokémon**: 150+ espécies capturáveis
6. **Missões/Quests**: Sistema de tarefas
7. **Multiplayer**: Troca e batalha online
8. **Efeitos de clima**: Chuva, neve, neblina

## 🌟 Como Testar

1. Abra o arquivo `index.html` em qualquer navegador moderno
2. Ou use um servidor local:
   ```bash
   cd gba_rpg_room
   python -m http.server 8080
   ```
3. Acesse `http://localhost:8080`

## 📝 Notas de Desenvolvimento

- **Compatibilidade**: Funciona em Chrome, Firefox, Edge, Safari
- **Mobile**: Controles touch implementados
- **Responsive**: Se adapta a telas menores
- **Sem dependências**: Apenas HTML, CSS e JS puros
- **Código aberto**: Modifique e expanda como quiser!

---

**Divirta-se explorando esta aventura Pokémon estilo GBA!** 🎮✨

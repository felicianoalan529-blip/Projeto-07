// ============================================
// 🎮 AVENTURA POKÉMON GBA - EDIÇÃO ULTRA
// Gráficos Aprimorados | Mapa Expandido | Sistema Completo
// ============================================

const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');
const minimapCanvas = document.getElementById('minimap');
const minimapCtx = minimapCanvas.getContext('2d');

// Configurações do Jogo
const TILE_SIZE = 16;
const SCALED_TILE_SIZE = TILE_SIZE * 2;
const SCREEN_WIDTH = 480;
const SCREEN_HEIGHT = 320;
const MAP_WIDTH = 50;
const MAP_HEIGHT = 40;

// Estado do Jogo
const gameState = {
    currentRegion: 'vila_inicial',
    dialogActive: false,
    menuOpen: false,
    menuIndex: 0,
    battleMode: false,
    timeOfDay: 'day',
    weather: 'sunny',
    gameTime: 720,
    weatherTimer: 0,
    screenShake: 0,
    particles: [],
    player: {
        x: 15, y: 15, direction: 'down', moving: false,
        name: 'Herói', level: 5, badges: [], money: 5000, steps: 0,
        pokemon: [
            { name: 'Pikachu', level: 28, hp: 120, maxHp: 120, attack: 65, defense: 45 },
            { name: 'Charizard', level: 32, hp: 150, maxHp: 150, attack: 84, defense: 78 },
            { name: 'Blastoise', level: 30, hp: 140, maxHp: 140, attack: 83, defense: 90 },
            { name: 'Venusaur', level: 30, hp: 145, maxHp: 145, attack: 82, defense: 83 }
        ],
        items: { 
            'Poção': 10, 'Super Poção': 5, 'Hiper Poção': 2,
            'Poké Ball': 15, 'Great Ball': 8, 'Ultra Ball': 3,
            'Antídoto': 5, 'Cura Total': 3, 'Reviver': 2
        },
        quests: []
    },
    npcs: [], items: [], trainers: [], flags: {}, wildPokemonEncounters: 0
};

// Tipos de Tiles Expandidos
const tileTypes = { 
    GRASS: 0, DIRT_PATH: 1, WATER: 2, TREE: 3, FLOWER: 4, 
    ROCK: 5, HOUSE: 6, FENCE: 7, SAND: 8, TALL_GRASS: 17, 
    POKECENTER: 14, MART: 15, GYM: 16, SNOW: 18, ICE: 19,
    BRIDGE: 20, CAVE: 21, LAVA: 22, RUINS: 23, BEACH: 24
};

// Cores dos Tiles com Gradientes
const tileColors = {
    0: ['#4a8c3a', '#5a9c4a', '#3a7c2a'],      // Grama
    1: ['#8b7355', '#9b8365', '#7b6345'],      // Caminho terra
    2: ['#5ba3d0', '#6bb3e0', '#4b93c0'],      // Água
    3: ['#2d5a27', '#3d6a37', '#1d4a17'],      // Árvore
    4: ['#ff69b4', '#ff79c4', '#ff59a4'],      // Flor
    5: ['#808080', '#909090', '#707070'],      // Rocha
    6: ['#cd853f', '#dd954f', '#bd752f'],      // Casa
    7: ['#8b4513', '#9b5523', '#7b3503'],      // Cerca
    8: ['#f4d03f', '#ffe04f', '#e4c02f'],      // Areia
    14: ['#ff6b6b', '#ff7b7b', '#ff5b5b'],     // Centro Pokémon
    15: ['#4a90d9', '#5aa0e9', '#3a80c9'],     // Loja
    16: ['#d4af37', '#e4bf47', '#c49f27'],     // Ginásio
    17: ['#2d6a27', '#3d7a37', '#1d5a17'],     // Grama alta
    18: ['#f0f8ff', '#f5faff', '#e8f4ff'],     // Neve
    19: ['#b8d4e8', '#c8e4f8', '#a8c4d8'],     // Gelo
    20: ['#8b6914', '#9b7924', '#7b5904'],     // Ponte
    21: ['#4a4a4a', '#5a5a5a', '#3a3a3a'],     // Caverna
    22: ['#ff4500', '#ff5510', '#ff3500'],     // Lava
    23: ['#8b7355', '#9b8365', '#7b6345'],     // Ruínas
    24: ['#f5deb3', '#ffecc3', '#e5d0a3']      // Praia
};

// Banco de Dados de NPCs Expandido
const npcDatabase = [
    { id: 1, name: 'Prof. Carvalho', dialog: ['Olá! Sou o Prof. Carvalho!', 'Estudo Pokémon há 30 anos.', 'Este é um mundo misterioso...', 'Cheio de criaturas incríveis!'], region: 'vila_inicial', x: 8, y: 8, sprite: 'professor' },
    { id: 2, name: 'Enfermeira Joy', dialog: ['Bem-vindo ao Centro Pokémon!', 'Cuidamos do seu time gratuitamente.', 'Seus Pokémon estão em boas mãos!'], region: 'vila_inicial', x: 12, y: 6, sprite: 'nurse' },
    { id: 3, name: 'Ancião', dialog: ['Bem-vindo à nossa vila!', 'Dizem que há tesouros nas cavernas.', 'Cuidado com os Pokémon selvagens!'], region: 'vila_inicial', x: 18, y: 12, sprite: 'oldman' },
    { id: 4, name: 'Luna', dialog: ['Oi! Você é novo por aqui?', 'Adoro explorar a floresta!', 'Já vi Pokémon raros lá dentro.'], region: 'vila_inicial', x: 22, y: 18, sprite: 'girl' },
    { id: 5, name: 'Treinador Red', dialog: ['Ei, você parece forte!', 'Vamos batalhar?', 'Meu Pikachu é o melhor!'], region: 'vila_inicial', x: 30, y: 15, battle: true, sprite: 'trainer_m' },
    { id: 6, name: 'Vendedora', dialog: ['Bem-vindo à loja!', 'Temos os melhores itens!', 'Promoção: Poké Balls hoje!'], region: 'vila_inicial', x: 16, y: 6, sprite: 'shop_girl' },
    { id: 7, name: 'Bug Catcher', dialog: ['Insetos são os melhores!', 'Venha enfrentar!'], region: 'vila_inicial', x: 35, y: 25, battle: true, sprite: 'bug_catcher' },
    { id: 8, name: 'Mestre do Ginásio', dialog: ['Eu sou o Líder deste Ginásio!', 'Prove seu valor em batalha!'], region: 'vila_inicial', x: 25, y: 10, sprite: 'gym_leader' },
    { id: 9, name: 'Pescador', dialog: ['Pesco Pokémon aquáticos aqui!', 'Já peguei mais de 1000!'], region: 'vila_inicial', x: 40, y: 20, sprite: 'fisher' },
    { id: 10, name: 'Cientista', dialog: ['Estudo a evolução dos Pokémon!', 'Fascinante, não acha?'], region: 'vila_inicial', x: 10, y: 25, sprite: 'scientist' }
];

// Banco de Dados de Itens Expandido
const itemDatabase = [
    { id: 1, name: 'Poção', type: 'healing', effect: 'Recupera 20 HP', rarity: 'common', x: 14, y: 10, region: 'vila_inicial' },
    { id: 2, name: 'Poké Ball', type: 'capture', effect: 'Captura Pokémon', rarity: 'common', x: 5, y: 15, region: 'vila_inicial' },
    { id: 3, name: 'Super Poção', type: 'healing', effect: 'Recupera 50 HP', rarity: 'uncommon', x: 35, y: 8, region: 'vila_inicial' },
    { id: 4, name: 'Great Ball', type: 'capture', effect: 'Melhor captura', rarity: 'uncommon', x: 40, y: 30, region: 'vila_inicial' },
    { id: 5, name: 'Antídoto', type: 'status', effect: 'Cura envenenamento', rarity: 'common', x: 8, y: 30, region: 'vila_inicial' },
    { id: 6, name: 'Cura Total', type: 'healing', effect: 'Cura tudo', rarity: 'rare', x: 45, y: 12, region: 'vila_inicial' },
    { id: 7, name: 'Hiper Poção', type: 'healing', effect: 'Recupera 200 HP', rarity: 'rare', x: 20, y: 35, region: 'vila_inicial' },
    { id: 8, name: 'Ultra Ball', type: 'capture', effect: 'Captura superior', rarity: 'rare', x: 30, y: 35, region: 'vila_inicial' },
    { id: 9, name: 'Reviver', type: 'revive', effect: 'Revive Pokémon', rarity: 'ultra_rare', x: 42, y: 5, region: 'vila_inicial' },
    { id: 10, name: 'Pedra Lunar', type: 'evolution', effect: 'Evolui certos Pokémon', rarity: 'ultra_rare', x: 3, y: 38, region: 'vila_inicial' }
];

// Banco de Dados de Treinadores Expandido
const trainerDatabase = [
    { id: 1, name: 'Treinador Red', region: 'vila_inicial', x: 30, y: 15, team: [{ name: 'Pikachu', level: 35, hp: 120, attack: 75, defense: 50 }], reward: 2500, dialog: ['Vamos batalhar!', 'Pikachu, escolha eu!'], sprite: 'trainer_m' },
    { id: 2, name: 'Bug Catcher', region: 'vila_inicial', x: 35, y: 25, team: [{ name: 'Butterfree', level: 28, hp: 90, attack: 45, defense: 40 }, { name: 'Beedrill', level: 26, hp: 85, attack: 55, defense: 35 }], reward: 1120, dialog: ['Insetos são os melhores!', 'Venha enfrentar!'], sprite: 'bug_catcher' },
    { id: 3, name: 'Mestre do Ginásio', region: 'vila_inicial', x: 25, y: 10, team: [{ name: 'Charizard', level: 45, hp: 180, attack: 104, defense: 88 }, { name: 'Blastoise', level: 43, hp: 175, attack: 93, defense: 100 }], reward: 5400, dialog: ['Sou o Líder do Ginásio!', 'Prepare-se para batalhar!'], sprite: 'gym_leader' },
    { id: 4, name: 'Ace Trainer', region: 'vila_inicial', x: 38, y: 32, team: [{ name: 'Arcanine', level: 40, hp: 160, attack: 110, defense: 70 }], reward: 3200, dialog: ['Você não vai ganhar fácil!', 'Mostre seu poder!'], sprite: 'trainer_f' }
];

let currentDialog = null, dialogLineIndex = 0, dialogCharIndex = 0, dialogTypewriterInterval = null;
let currentMap = [];
const keys = {};

function showDialog(npcName, lines) {
    gameState.dialogActive = true;
    currentDialog = lines;
    dialogLineIndex = 0;
    dialogCharIndex = 0;
    
    const dialogBox = document.getElementById('dialog-box');
    const dialogName = document.getElementById('dialog-name');
    const dialogText = document.getElementById('dialog-text');
    const dialogIndicator = document.getElementById('dialog-indicator');
    
    dialogBox.classList.remove('hidden');
    dialogName.textContent = npcName;
    dialogText.textContent = '';
    dialogIndicator.style.opacity = '0';
    
    if (dialogTypewriterInterval) clearInterval(dialogTypewriterInterval);
    
    dialogTypewriterInterval = setInterval(() => {
        if (dialogLineIndex < lines.length) {
            const currentLine = lines[dialogLineIndex];
            if (dialogCharIndex < currentLine.length) {
                dialogText.textContent += currentLine[dialogCharIndex];
                dialogCharIndex++;
            } else {
                clearInterval(dialogTypewriterInterval);
                dialogIndicator.style.opacity = '1';
                setTimeout(() => {
                    dialogLineIndex++;
                    dialogCharIndex = 0;
                    if (dialogLineIndex < lines.length) {
                        dialogText.textContent = '';
                        dialogIndicator.style.opacity = '0';
                        dialogTypewriterInterval = setInterval(() => {
                            const line = lines[dialogLineIndex];
                            if (dialogCharIndex < line.length) {
                                dialogText.textContent += line[dialogCharIndex];
                                dialogCharIndex++;
                            } else {
                                clearInterval(dialogTypewriterInterval);
                                dialogIndicator.style.opacity = '1';
                                setTimeout(() => {
                                    dialogLineIndex++;
                                    dialogCharIndex = 0;
                                    if (dialogLineIndex >= lines.length) closeDialog();
                                    else {
                                        dialogText.textContent = '';
                                        dialogIndicator.style.opacity = '0';
                                    }
                                }, 1500);
                            }
                        }, 30);
                    } else {
                        closeDialog();
                    }
                }, 1500);
            }
        } else {
            closeDialog();
        }
    }, 30);
}

function closeDialog() {
    if (dialogTypewriterInterval) clearInterval(dialogTypewriterInterval);
    document.getElementById('dialog-box').classList.add('hidden');
    gameState.dialogActive = false;
    currentDialog = null;
}

function advanceDialog() {
    if (currentDialog && dialogLineIndex < currentDialog.length) {
        dialogLineIndex = currentDialog.length;
        closeDialog();
    }
}

function toggleMenu() {
    const menu = document.getElementById('main-menu');
    gameState.menuOpen = !gameState.menuOpen;
    if (gameState.menuOpen) {
        menu.classList.remove('hidden');
        gameState.menuIndex = 0;
        updateMenuSelection();
    } else {
        menu.classList.add('hidden');
    }
}

function handleMenuInput(key) {
    const menuItems = document.querySelectorAll('.menu-item');
    if (key === 'ArrowUp' || key === 'w' || key === 'W') {
        gameState.menuIndex = (gameState.menuIndex - 1 + menuItems.length) % menuItems.length;
        updateMenuSelection();
    } else if (key === 'ArrowDown' || key === 's' || key === 'S') {
        gameState.menuIndex = (gameState.menuIndex + 1) % menuItems.length;
        updateMenuSelection();
    } else if (key === 'Enter' || key === 'z' || key === 'Z') {
        selectMenuItem(menuItems[gameState.menuIndex].dataset.action);
    } else if (key === 'Escape' || key === 'x' || key === 'X') {
        toggleMenu();
    }
}

function updateMenuSelection() {
    document.querySelectorAll('.menu-item').forEach((item, index) => {
        item.classList.toggle('selected', index === gameState.menuIndex);
    });
}

function selectMenuItem(action) {
    let message = [];
    switch (action) {
        case 'mochila':
            message = ['🎒 MOCHILA'];
            for (const [name, qty] of Object.entries(gameState.player.items)) {
                if (qty > 0) message.push(`• ${name} x${qty}`);
            }
            break;
        case 'pokemon':
            message = ['⚡ SEUS POKÉMON'];
            gameState.player.pokemon.forEach((p, i) => {
                message.push(`${i + 1}. ${p.name} Lv.${p.level} HP:${p.hp}/${p.maxHp}`);
            });
            break;
        case 'status':
            message = ['📊 STATUS', `Nome: ${gameState.player.name}`, `Nível: ${gameState.player.level}`, `Dinheiro: R$${gameState.player.money}`, `Passos: ${gameState.player.steps}`, `Medalhas: ${gameState.player.badges.length}/8`];
            break;
        case 'treinadores':
            message = ['🏆 TREINADORES'];
            const defeated = gameState.flags.defeatedTrainers || [];
            trainerDatabase.forEach(t => message.push(`${defeated.includes(t.id) ? '✓' : '○'} ${t.name}`));
            break;
        case 'medalhas':
            message = ['🏅 MEDALHAS'];
            if (gameState.player.badges.length === 0) message.push('Nenhuma medalha ainda!');
            else gameState.player.badges.forEach(b => message.push(`• ${b}`));
            break;
        case 'salvar':
            localStorage.setItem('pokemonGBASave', JSON.stringify({ player: gameState.player, currentRegion: gameState.currentRegion, gameTime: gameState.gameTime, flags: gameState.flags }));
            message = ['💾 SALVAR', 'Jogo salvo com sucesso!'];
            showNotification('Jogo salvo!');
            break;
        case 'opcoes':
            message = ['⚙️ OPÇÕES', `Tempo: ${formatTime(gameState.gameTime)}`, `Região: ${gameState.currentRegion}`];
            break;
        case 'sair':
            message = ['🚪 SAIR', 'Pressione A para confirmar'];
            break;
    }
    toggleMenu();
    showDialog('Menu', message);
}

function formatTime(minutes) {
    const h = Math.floor(minutes / 60), m = minutes % 60;
    const period = h >= 12 ? 'PM' : 'AM';
    const dh = h > 12 ? h - 12 : (h === 0 ? 12 : h);
    return `${dh}:${m.toString().padStart(2, '0')} ${period}`;
}

function showNotification(text) {
    const n = document.getElementById('notification');
    document.getElementById('notification-text').textContent = text;
    n.classList.remove('hidden');
    setTimeout(() => n.classList.add('hidden'), 2000);
}

function generateMap() {
    const map = [];
    for (let y = 0; y < MAP_HEIGHT; y++) {
        const row = [];
        for (let x = 0; x < MAP_WIDTH; x++) {
            if (x === 0 || x === MAP_WIDTH - 1 || y === 0 || y === MAP_HEIGHT - 1) row.push(tileTypes.TREE);
            else if (x > MAP_WIDTH - 8 && y < 8) row.push(tileTypes.WATER);
            else if (y === 15 && x > 5 && x < MAP_WIDTH - 5) row.push(tileTypes.DIRT_PATH);
            else if (x === 8 && y === 8) row.push(tileTypes.POKECENTER);
            else if (x === 12 && y === 8) row.push(tileTypes.MART);
            else if (x === 20 && y === 10) row.push(tileTypes.GYM);
            else if (x > 25 && y > 20 && (x + y) % 3 === 0) row.push(tileTypes.TALL_GRASS);
            else if ((x * y) % 17 === 0 && x > 5 && y > 5) row.push(tileTypes.FLOWER);
            else if ((x + y) % 11 === 0 && x > 3 && y > 3) row.push(Math.random() > 0.5 ? tileTypes.ROCK : tileTypes.TREE);
            else row.push(tileTypes.GRASS);
        }
        map.push(row);
    }
    return map;
}

function init() {
    currentMap = generateMap();
    gameState.npcs = npcDatabase.filter(n => n.region === 'vila_inicial');
    gameState.items = itemDatabase.filter(i => i.region === 'vila_inicial').map(i => ({ ...i, collected: false }));
    gameState.trainers = trainerDatabase.filter(t => t.region === 'vila_inicial');
    
    const saveData = localStorage.getItem('pokemonGBASave');
    if (saveData) {
        const data = JSON.parse(saveData);
        Object.assign(gameState.player, data.player);
        gameState.currentRegion = data.currentRegion;
        gameState.gameTime = data.gameTime;
        gameState.flags = data.flags;
    }
    
    setupEventListeners();
    updateTimeOfDay();
    gameLoop();
}

function updateTimeOfDay() {
    gameState.gameTime += 0.5;
    if (gameState.gameTime >= 1440) gameState.gameTime = 0;
    const hour = Math.floor(gameState.gameTime / 60);
    gameState.timeOfDay = hour >= 5 && hour < 12 ? 'morning' : hour >= 12 && hour < 17 ? 'day' : hour >= 17 && hour < 20 ? 'evening' : 'night';
    updateScreenOverlay();
    updateHUD();
}

function updateScreenOverlay() {
    const overlay = document.getElementById('screen-overlay');
    overlay.className = gameState.timeOfDay === 'night' ? 'night' : '';
}

function updateHUD() {
    document.getElementById('player-name').textContent = gameState.player.name;
    const timeDisplay = document.getElementById('player-time');
    const icon = gameState.timeOfDay === 'night' ? '🌙' : gameState.timeOfDay === 'evening' ? '🌅' : '☀️';
    timeDisplay.textContent = `${icon} ${formatTime(gameState.gameTime)}`;
    
    // Atualizar estatísticas do HUD
    document.getElementById('hud-steps').textContent = gameState.player.steps;
    document.getElementById('hud-money').textContent = `R$${gameState.player.money.toLocaleString('pt-BR')}`;
    document.getElementById('hud-pokemon').textContent = gameState.player.pokemon.filter(p => p.hp > 0).length;
    
    const badgesContainer = document.getElementById('hud-badges');
    badgesContainer.innerHTML = '';
    gameState.player.badges.forEach(() => {
        const b = document.createElement('div');
        b.className = 'badge';
        badgesContainer.appendChild(b);
    });
    
    // Atualizar indicador de região
    const regionNames = {
        'vila_inicial': 'VILA INICIAL',
        'floresta': 'FLORESTA MISTERIOSA',
        'cidade_porto': 'CIDADE PORTO',
        'monte_lua': 'MONTE LUA',
        'rota_1': 'ROTA 1',
        'cidade_violeta': 'CIDADE VIOLETA',
        'ilha_tesouro': 'ILHA DO TESOURO',
        'caverna': 'CAVERNA DIGITAL'
    };
    document.getElementById('region-indicator').textContent = regionNames[gameState.currentRegion] || gameState.currentRegion.toUpperCase();
}

function setupEventListeners() {
    document.addEventListener('keydown', (e) => {
        keys[e.key] = true;
        if (e.key === 'r' || e.key === 'R') {
            gameState.player.x = 10; gameState.player.y = 10;
            showNotification('Posição reiniciada!');
            return;
        }
        if (gameState.menuOpen) { handleMenuInput(e.key); return; }
        if (gameState.dialogActive) {
            if (e.key === 'z' || e.key === 'Z' || e.key === 'Enter' || e.key === ' ') advanceDialog();
            return;
        }
        if (['ArrowUp', 'w', 'W'].includes(e.key)) movePlayer(0, -1, 'up');
        else if (['ArrowDown', 's', 'S'].includes(e.key)) movePlayer(0, 1, 'down');
        else if (['ArrowLeft', 'a', 'A'].includes(e.key)) movePlayer(-1, 0, 'left');
        else if (['ArrowRight', 'd', 'D'].includes(e.key)) movePlayer(1, 0, 'right');
        if (e.key === 'z' || e.key === 'Z' || e.key === 'Enter') interact();
        if (e.key === 'x' || e.key === 'X' || e.key === 'Escape') toggleMenu();
    });
    document.addEventListener('keyup', (e) => { keys[e.key] = false; });
    
    ['btn-up', 'btn-down', 'btn-left', 'btn-right', 'btn-a', 'btn-b', 'btn-start', 'btn-select'].forEach(id => {
        const btn = document.getElementById(id);
        if (btn) btn.addEventListener('touchstart', (e) => { e.preventDefault(); });
    });
    document.getElementById('btn-a')?.addEventListener('touchstart', (e) => { e.preventDefault(); interact(); });
    document.getElementById('btn-b')?.addEventListener('touchstart', (e) => { e.preventDefault(); toggleMenu(); });
}

function movePlayer(dx, dy, direction) {
    if (gameState.player.moving || gameState.dialogActive || gameState.menuOpen || gameState.battleMode) return;
    const newX = gameState.player.x + dx, newY = gameState.player.y + dy;
    if (newY < 0 || newY >= MAP_HEIGHT || newX < 0 || newX >= MAP_WIDTH) { gameState.player.direction = direction; return; }
    const tile = currentMap[newY][newX];
    const solidTiles = [tileTypes.TREE, tileTypes.ROCK, tileTypes.HOUSE, tileTypes.FENCE, tileTypes.WATER, tileTypes.TALL_GRASS, tileTypes.POKECENTER, tileTypes.MART, tileTypes.GYM];
    if (solidTiles.includes(tile)) { gameState.player.direction = direction; return; }
    for (let npc of gameState.npcs) { if (npc.x === newX && npc.y === newY) { gameState.player.direction = direction; return; } }
    for (let trainer of gameState.trainers) {
        if (trainer.x === newX && trainer.y === newY && !gameState.flags.defeatedTrainers?.includes(trainer.id)) {
            gameState.player.direction = direction;
            startBattle(trainer);
            return;
        }
    }
    gameState.player.x = newX;
    gameState.player.y = newY;
    gameState.player.direction = direction;
    gameState.player.moving = true;
    gameState.player.steps++;
    if (tile === tileTypes.TALL_GRASS && Math.random() < 0.15) setTimeout(() => startWildBattle(), 200);
    checkItemCollection();
    setTimeout(() => { gameState.player.moving = false; }, 150);
}

function checkItemCollection() {
    for (let item of gameState.items) {
        if (!item.collected && item.x === gameState.player.x && item.y === gameState.player.y) collectItem(item);
    }
}

function collectItem(item) {
    item.collected = true;
    gameState.player.items[item.name] = (gameState.player.items[item.name] || 0) + 1;
    showDialog('Item encontrado!', [`Você encontrou ${item.name}!`, item.effect, 'Adicionado à mochila.']);
    showNotification(`+1 ${item.name}`);
}

function interact() {
    let targetX = gameState.player.x, targetY = gameState.player.y;
    switch (gameState.player.direction) {
        case 'up': targetY--; break; case 'down': targetY++; break;
        case 'left': targetX--; break; case 'right': targetX++; break;
    }
    for (let npc of gameState.npcs) { if (npc.x === targetX && npc.y === targetY) { showDialog(npc.name, npc.dialog); return; } }
    for (let item of gameState.items) { if (!item.collected && item.x === targetX && item.y === targetY) { collectItem(item); return; } }
}

function startBattle(trainer) {
    gameState.battleMode = true;
    showDialog(trainer.name, [...trainer.dialog, '', `Iniciando batalha!`, `${trainer.team[0].name} Lv.${trainer.team[0].level} apareceu!`]);
    setTimeout(() => {
        const playerPokemon = gameState.player.pokemon[0];
        const enemyPokemon = trainer.team[0];
        const playerWins = playerPokemon.level >= enemyPokemon.level;
        if (playerWins) {
            showDialog('Batalha', [`${playerPokemon.name} usou Ataque Rápido!`, `${enemyPokemon.name} foi derrotado!`, '', `Você venceu! Ganhou R$${trainer.reward}!`]);
            gameState.player.money += trainer.reward;
            if (!gameState.flags.defeatedTrainers) gameState.flags.defeatedTrainers = [];
            gameState.flags.defeatedTrainers.push(trainer.id);
        } else {
            showDialog('Batalha', [`${playerPokemon.name} foi derrotado...`, 'Você correu para o Centro Pokémon!']);
            gameState.player.pokemon.forEach(p => p.hp = p.maxHp);
            gameState.player.x = 8; gameState.player.y = 8;
        }
        gameState.battleMode = false;
    }, 4000);
}

function startWildBattle() {
    gameState.battleMode = true;
    const wildPokemon = [{ name: 'Pidgey', level: 5 }, { name: 'Rattata', level: 4 }, { name: 'Caterpie', level: 3 }, { name: 'Weedle', level: 3 }];
    const pokemon = wildPokemon[Math.floor(Math.random() * wildPokemon.length)];
    showDialog('Pokémon Selvagem', [`Um ${pokemon.name} selvagem apareceu!`, `Lv.${pokemon.level}`, '', 'O que fazer?']);
    setTimeout(() => { showDialog('Batalha', ['Você conseguiu fugir!', 'Cuidado onde pisa!']); gameState.battleMode = false; }, 3000);
}

function render() {
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    const cameraX = Math.max(0, Math.min(gameState.player.x * SCALED_TILE_SIZE - SCREEN_WIDTH / 2, MAP_WIDTH * SCALED_TILE_SIZE - SCREEN_WIDTH));
    const cameraY = Math.max(0, Math.min(gameState.player.y * SCALED_TILE_SIZE - SCREEN_HEIGHT / 2, MAP_HEIGHT * SCALED_TILE_SIZE - SCREEN_HEIGHT));
    
    for (let y = 0; y < MAP_HEIGHT; y++) {
        for (let x = 0; x < MAP_WIDTH; x++) {
            const tile = currentMap[y][x];
            const screenX = x * SCALED_TILE_SIZE - cameraX, screenY = y * SCALED_TILE_SIZE - cameraY;
            if (screenX < -SCALED_TILE_SIZE || screenX > SCREEN_WIDTH || screenY < -SCALED_TILE_SIZE || screenY > SCREEN_HEIGHT) continue;
            const colors = tileColors[tile] || tileColors[tileTypes.GRASS];
            ctx.fillStyle = colors[0];
            ctx.fillRect(screenX, screenY, SCALED_TILE_SIZE, SCALED_TILE_SIZE);
            drawTileDetails(tile, screenX, screenY, x, y);
        }
    }
    
    for (let item of gameState.items) {
        if (!item.collected) {
            const screenX = item.x * SCALED_TILE_SIZE - cameraX, screenY = item.y * SCALED_TILE_SIZE - cameraY;
            drawItem(item, screenX, screenY);
        }
    }
    
    for (let npc of gameState.npcs) {
        const screenX = npc.x * SCALED_TILE_SIZE - cameraX, screenY = npc.y * SCALED_TILE_SIZE - cameraY;
        drawCharacter(npc, screenX, screenY, npc.name, '#ffd700');
    }
    
    for (let trainer of gameState.trainers) {
        if (!gameState.flags.defeatedTrainers?.includes(trainer.id)) {
            const screenX = trainer.x * SCALED_TILE_SIZE - cameraX, screenY = trainer.y * SCALED_TILE_SIZE - cameraY;
            drawCharacter(trainer, screenX, screenY, trainer.name, '#ff6b6b');
        }
    }
    
    const playerScreenX = gameState.player.x * SCALED_TILE_SIZE - cameraX, playerScreenY = gameState.player.y * SCALED_TILE_SIZE - cameraY;
    drawCharacter(gameState.player, playerScreenX, playerScreenY, gameState.player.name, '#4169e1', true);
    renderMinimap(cameraX, cameraY);
}

function drawTileDetails(tile, screenX, screenY, x, y) {
    switch (tile) {
        case tileTypes.TREE:
            ctx.fillStyle = '#5d4037'; ctx.fillRect(screenX + 6, screenY + 8, 4, 8);
            ctx.fillStyle = '#2d5a27'; ctx.beginPath(); ctx.arc(screenX + 8, screenY + 6, 6, 0, Math.PI * 2); ctx.fill();
            break;
        case tileTypes.FLOWER:
            ctx.fillStyle = ['#ff69b4', '#ff6347', '#ffa500', '#ffff00'][Math.floor((x * y) % 4)];
            ctx.beginPath(); ctx.arc(screenX + 8, screenY + 8, 3, 0, Math.PI * 2); ctx.fill();
            break;
        case tileTypes.ROCK:
            ctx.fillStyle = '#808080'; ctx.beginPath(); ctx.moveTo(screenX + 4, screenY + 12); ctx.lineTo(screenX + 8, screenY + 4); ctx.lineTo(screenX + 12, screenY + 12); ctx.closePath(); ctx.fill();
            break;
        case tileTypes.WATER:
            ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
            const waveOffset = Math.sin(Date.now() / 500 + x) * 2;
            ctx.fillRect(screenX + 2, screenY + 6 + waveOffset, 6, 2);
            ctx.fillRect(screenX + 8, screenY + 10 + waveOffset, 6, 2);
            break;
        case tileTypes.TALL_GRASS:
            ctx.fillStyle = '#2d6a27';
            for (let i = 0; i < 4; i++) ctx.fillRect(screenX + 2 + i * 4, screenY + 4, 2, 12);
            break;
        case tileTypes.POKECENTER:
            ctx.fillStyle = '#ff6b6b'; ctx.fillRect(screenX + 2, screenY + 2, 12, 12);
            ctx.fillStyle = '#fff'; ctx.font = '10px Arial'; ctx.fillText('P', screenX + 5, screenY + 12);
            break;
        case tileTypes.GYM:
            ctx.fillStyle = '#d4af37'; ctx.fillRect(screenX + 2, screenY + 2, 12, 12);
            ctx.fillStyle = '#000'; ctx.font = '10px Arial'; ctx.fillText('G', screenX + 5, screenY + 12);
            break;
    }
}

function drawItem(item, screenX, screenY) {
    ctx.fillStyle = 'rgba(255, 215, 0, 0.5)';
    ctx.beginPath(); ctx.arc(screenX + 8, screenY + 8, 10, 0, Math.PI * 2); ctx.fill();
    if (item.type === 'capture') {
        ctx.fillStyle = '#ff0000'; ctx.beginPath(); ctx.arc(screenX + 8, screenY + 8, 6, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#fff'; ctx.fillRect(screenX + 2, screenY + 6, 12, 4);
        ctx.fillStyle = '#000'; ctx.beginPath(); ctx.arc(screenX + 8, screenY + 8, 2, 0, Math.PI * 2); ctx.fill();
    } else {
        ctx.fillStyle = item.rarity === 'rare' ? '#ffd700' : '#fff';
        ctx.beginPath(); ctx.arc(screenX + 8, screenY + 8, 5, 0, Math.PI * 2); ctx.fill();
    }
}

function drawCharacter(char, screenX, screenY, name, color, isPlayer = false) {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.3)';
    ctx.beginPath(); ctx.ellipse(screenX + 8, screenY + 14, 6, 3, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = color; ctx.fillRect(screenX + 4, screenY + 6, 8, 8);
    ctx.fillStyle = '#ffcc99'; ctx.fillRect(screenX + 5, screenY + 2, 6, 6);
    ctx.fillStyle = isPlayer ? '#dc143c' : '#8b4513';
    ctx.fillRect(screenX + 4, screenY, isPlayer ? 8 : 6, isPlayer ? 4 : 3);
    ctx.fillStyle = '#fff'; ctx.font = '8px "Press Start 2P"'; ctx.textAlign = 'center';
    ctx.fillText(name, screenX + 8, screenY - 2);
}

function renderMinimap(cameraX, cameraY) {
    minimapCtx.fillStyle = '#000';
    minimapCtx.fillRect(0, 0, 80, 80);
    const scale = 80 / MAP_WIDTH;
    for (let y = 0; y < MAP_HEIGHT; y++) {
        for (let x = 0; x < MAP_WIDTH; x++) {
            const tile = currentMap[y][x];
            minimapCtx.fillStyle = tileColors[tile]?.[0] || '#000';
            minimapCtx.fillRect(x * scale, y * scale, scale, scale);
        }
    }
    minimapCtx.fillStyle = '#ff0000';
    minimapCtx.beginPath();
    minimapCtx.arc(gameState.player.x * scale + scale/2, gameState.player.y * scale + scale/2, 2, 0, Math.PI * 2);
    minimapCtx.fill();
}

function gameLoop() {
    if (!gameState.dialogActive && !gameState.menuOpen && !gameState.battleMode) updateTimeOfDay();
    render();
    requestAnimationFrame(gameLoop);
}

window.addEventListener('load', init);

# 🛡️ Especificação e Plano de Implementação: Arena Multiplayer Legion TD (CyberWars)

Este documento define o novo design central e o plano de implementação técnica da **PromptSec Arena** focado na experiência **Multiplayer 2v2 / 1v1 estilo Legion TD (Warcraft 3)** adaptada para cibersegurança.

---

## 🏛️ 1. Visão Geral e Filosofia do Modo Multiplayer

No lugar de múltiplos cenários fragmentados, a plataforma adota um **único modo central** que sintetiza a essência competitiva de ataque e defesa simultâneos:
* **Duas Equipes Competindo em Paralelo:** Time 1 vs Time 2 (2v2 ou 1v1).
* **Defesa de Perímetro (O Grid Tático):** Cada jogador constrói nós defensivos em seu grid para conter os vírus neutros da rodada e os malwares enviados pelo oponente.
* **Ataque e Renda Econômica (Envio de Vírus):** Jogadores usam **Tokens** para comprar vírus que surgirão misturados na onda do oponente. Cada vírus enviado concede um **aumento permanente de Renda de Bits por rodada**.
* **A Última Linha de Defesa — O Mainframe Central (Rei):** Qualquer ameaça que furar as defesas de um jogador (*leak*) entra na sala do Mainframe Central do time. Se o Mainframe for destruído, a equipe é derrotada.

---

## 🖥️ 2. A Entidade Central: Mainframe Central (O "Rei")

O **Mainframe Central** é um rack de servidores de alta densidade com refrigeração líquida e iluminação neon, posicionado no núcleo de cada base.

### ⚙️ Árvore de Upgrades de Hardware (Tokens)
Ambos os jogadores do time podem investir seus **Tokens** coletivos ou individuais para aprimorar o Mainframe:

| Hardware | Efeito Tático | Descrição Cyberpunk |
| :--- | :--- | :--- |
| **CPU (Processador)** | +Dano / -Cooldown | Overclocking nos emissores de laser defensivo do rack, aumentando o DPS contra alvos de alta vida. |
| **RAM (Memória de Buffer)** | +Alvos Simultâneos (Multi-Target) | Aumenta o barramento de dados, permitindo disparar contra 2, 3 ou 4 invasores simultaneamente (essencial contra enxames/SYN Floods). |
| **Disco / Storage (`diskLevel`)** | +Capacidade Total (HP Máximo) e Backup | Expande a capacidade de armazenamento total de dados do rack, definindo o HP máximo e a integridade do Mainframe contra vazamentos de malwares. |

---

## 💰 3. Economia Dupla: Bits e Tokens

| Recurso | Como é Obtido | Onde é Gasto |
| :--- | :--- | :--- |
| 🟡 **Bits (Ouro)** | • Eliminação de vírus neutros na sua rota.<br>• Renda fixa garantida no fim de cada rodada (+ bônus de income). | • Compra e upgrade de **Bastiões de Defesa** no seu grid (Firewall, WAF, IPS, HoneyPot).<br>• Recrutamento de **Processos Mineradores**. |
| 🟣 **Tokens (Cripto/Lumber)** | • Gerados continuamente pelos seus **Processos Mineradores**.<br>• Pequena taxa base por segundo. | • **Upgrades de Hardware no Mainframe** (CPU, RAM, Disco).<br>• **Envio de Vírus Táticos** para o time adversário. |

> **🔥 A Tensão Chave do Legion TD:** Ao gastar Tokens enviando vírus para o inimigo, o jogador **aumenta sua renda permanente de Bits**. Guardar Tokens para dar upgrade no Mainframe protege a base, mas diminui o crescimento econômico a longo prazo.

---

## 🗺️ 4. Visualização Tática: Mapa Panorâmico com Pan & Zoom

O campo de batalha agora é contínuo e renderizado no Flame Engine utilizando `CameraComponent` e `World`:
* **Campo do Time 1:** Grid tático com portas e rotas de dados.
* **Túneis de Tráfego:** Linhas de fibra ótica onde os pacotes e vírus transitam.
* **Campo do Time 2:** Grid tático do oponente visível em tempo real.
* **Salas dos Mainframes:** Localizadas nas extremidades ou centro, onde a integridade dos servidores é monitorada.
* **Controles de Câmera:**
  * Gestos de arrasto (Pan) e scroll/pinch (Zoom) suaves.
  * Botões de ancoragem rápida no HUD: `[MEU GRID]`, `[TIME ADVERSÁRIO]`, `[MAINFRAME CENTRAL]`.

---

## 🤖 5. Inteligência Artificial (Modo 'Jogar com uma IA')

Para viabilizar partidas imediatas solo e testes sem necessidade de outros 3 jogadores humanos conectados:
* **Scripts Estruturados por Rodada:** A IA possui arquétipos de build defensiva e rotinas de envio de vírus testadas:
  * *Nível Fácil:* IA prioriza defesa básica e envia poucos malwares leves.
  * *Nível Médio:* IA balanceia compra de mineradores, investe em nós WAF/IPS e envia vírus em ondas alternadas.
  * *Nível Especialista:* IA economiza Tokens para enviar combos pesados (Worm + Ransomware) em ondas onde sabe que a defesa do jogador possui vulnerabilidades de tipo.

---

## 📱 6. Nova Estrutura de Menus e Navegação

Substituição da antiga tela de múltiplos cenários por um Lobby de Partidas:
* **Lobby / Nova Partida (`/lobby`):**
  * 🟢 **Criar Sala:** Gera um código de 6 caracteres (ex: `CYBER-404`) para partidas 2v2 ou 1v1.
  * 🔵 **Encontrar Sala:** Lista de salas públicas abertas e campo para digitar código de convite.
  * 🟣 **Jogar com uma IA:** Inicia imediatamente uma partida offline no mapa panorâmico com o bot scriptado.

---

## 📋 7. Fases do Plano de Implementação

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ ✅ FASE 1: Core de Domínio e Economia Dupla (Bits, Tokens e Mineradores)     │
│ • Modelagem de Bits, Tokens, Income por envio de vírus e Mineradores        │
│ • Mainframe Central com níveis de CPU, RAM e Disco                          │
│ • Commit: 211f5fa                                                           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│ ✅ FASE 2: Câmera Panorâmica Flame & Renderização dos 2 Campos               │
│ • Flame CameraComponent com Pan e Zoom livre                                │
│ • Renderização do Campo 1 (Aliado), Túneis e Campo 2 (Inimigo)              │
│ • Componente visual do Mainframe Central com LEDs e disparos multi-target   │
│ • Commit: b7cca86                                                           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│ ✅ FASE 3: Sistema de Envio de Vírus e Bot de IA Scriptado                   │
│ • Painel HUD de Envio de Malwares com acréscimo de renda permanente         │
│ • Script de IA para o Time 2 (build automático e envio de malwares)         │
│ • Modal de upgrades de hardware do Mainframe (CPU, RAM, Disco)              │
│ • Commit: 9e0a8d7                                                           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│ ✅ FASE 4: Lobby de Partidas e Menus (Criar Sala / Buscar / IA)              │
│ • Nova tela /lobby unificada (Solo IA, Criar Sala Host e Encontrar Sala)    │
│ • Conexão do fluxo com GoRouter e retorno de partida                        │
│ • Fullscreen e landscape preservados em toda a navegação                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 8. Checklist de Entregas e Validação

- [x] **Preliminar Fullscreen & Landscape:** Configuração do `index.html` (100vw x 100vh), `FullscreenHelper` e orientação horizontal fixa.
- [x] **Fase 1 (Domínio):** Modelos `MainframeModel` (CPU, RAM, Disco/Storage), `MatchEconomyState` (Bits, Tokens, Mineradores, Income) e `TacticalVirusModel`.
- [x] **Fase 2 (Canvas Flame):** `PanoramicBackgroundComponent`, `MainframeComponent` animado com laser multi-target, gestos de Pan e Zoom livre com `PanoramicCameraBar`.
- [x] **Fase 3 (Combate & IA):** `VirusDispatcherDock` no lugar do dock de cartas, `MainframeUpgradeSheet` modal, `ScriptedBotService` com rotinas táticas do Time 2.
- [x] **Fase 4 (Lobby & Navegação):** `GameLobbyScreen` em `/lobby`, GoRouter atualizado com Route Guards OWASP A01, botões de retorno ao lobby sincronizados.


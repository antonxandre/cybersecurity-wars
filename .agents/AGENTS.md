# 🤖 Guia dos Agentes de IA - PromptSec Arena (AGENTS.md)

Este documento estabelece as diretrizes de engenharia, arquitetura de software, catálogo de skills e protocolos de segurança para agentes de IA atuando no repositório **PromptSec Arena** (também referenciado como **CyberWars**).

---

## 🎯 1. Visão Geral e Identidade do Projeto

**PromptSec Arena** é uma plataforma open-source e gamificada de Capture The Flag (CTF) focada em **Segurança de Modelos de Linguagem (LLMs)** e **Segurança Ofensiva/Defensiva de Redes & Infraestrutura Multicamadas**.

O projeto simula batalhas PvP em tempo real entre:
* 🔴 **Red Team (Ataque):** Executa ataques de prompt injection (Jailbreak, Prompt Leaking, System Prompt Extraction), escaneamento de portas, bypass de regras de firewall e quebra de chaves criptográficas parciais para capturar a flag (`FLAG{...}`).
* 🔵 **Blue Team (Defesa):** Configura system prompts blindados com delimitadores XML/JSON no "Turno Zero", injeta micro-patches em tempo real durante a partida, aplica regras de firewall (iptables/UFW), estabelece túneis VPN e realiza rotação de segredos respeitando SLAs de serviço.
* 👁️ **Casters/Observadores:** Monitoram a partida ao vivo através de painel de telemetria com medidor de tensão baseado em logprobs do LLM e integridade de portas.

---

## 🏛️ 2. Os Três Eixos Arquiteturais Obrigatórios

Todo código produzido deve respeitar os três eixos definidos em [docs/arquitetura_e_diretrizes.md](file:///Users/antonxandre/cybersecurity_project/docs/arquitetura_e_diretrizes.md):

### ☁️ Eixo 1: Infraestrutura Cloud & Hardening (GCP + Docker + Nginx)
1. **VM Google Compute Engine**: Ubuntu Server 24.04 LTS (nível gratuito e2-micro/e2-small).
2. **Acesso Administrativo**: Apenas chaves criptográficas SSH (Ed25519 ou RSA 4096-bit). Senhas e login root estritamente desabilitados em `/etc/ssh/sshd_config`.
3. **Fail2Ban**: Ativo na porta 22 com tolerância de **4 erros** (`maxretry = 4`), ban de **24 horas** (`bantime = 86400`) e janela de 10 min (`findtime = 600`).
4. **Firewall VPC**: Princípio do menor privilégio, portas restritas a `TCP 80` (HTTP redirect), `TCP 443` (HTTPS) e `TCP 22` (SSH).
5. **Nginx Reverse Proxy**:
   - Redirecionamento HTTP (80) -> HTTPS (443) com status `301 Moved Permanently`.
   - Certificado Let's Encrypt (Certbot 5.4+) com suporte para **endereço IP público** ou domínio.
   - Suporte a **Post-Quantum Cryptography (PQC)** na negociação de chaves TLS (ex: `X25519MLKEM768`).
   - Injeção obrigatória de security headers: `Strict-Transport-Security`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Content-Security-Policy`.

### 📦 Eixo 2: Repositório Seguro & DevSecOps (GitHub Público)
1. **Repositório Público**: Transparência sem exposição de segredos.
2. **Prevenção Anti-Vazamento**:
   - `.gitignore` rígido bloqueando `.env`, chaves privadas SSH, credenciais GCP e artefatos de build.
   - Ativação de GitHub Secret Scanning e Push Protection.
3. **Branch Protection na `main`**: Commits diretos proibidos; exigência de Pull Request com revisão e aprovação em CI.
4. **GitHub Actions Secrets**: Todos os tokens e chaves privadas de deploy armazenados de forma encriptada.

### 💻 Eixo 3: Desenvolvimento Web Seguro (Flutter Web + NestJS API)
1. **Frontend**: Desenvolvido em **Flutter Web**, assistido por IA via Google Antigravity IDE.
2. **Backend**: Desenvolvido em **NestJS** (ESM, TypeScript, Prisma ORM, WebSockets Socket.IO).
3. **Estrutura Mínima Obrigatória**:
   - Tela de Login (`/login`)
   - Dashboard / Arena de Jogo (`/arena`)
   - Botão e Ação de Logout com destruição completa da sessão
4. **Mitigação Ativa do OWASP Top 10:2025**:
   - **A01:2025 - Broken Access Control**: Route Guards reativos no Flutter Web, guards de autenticação JWT e RBAC no NestJS, bloqueio de escalada horizontal entre Red/Blue Teams.
   - **A03:2025 - Injection**: Sanitização estrita de formulários, escape de tags HTML contra XSS, validação via DTOs com `class-validator`, queries parametrizadas com Prisma ORM e encapsulamento de prompts em delimitadores estruturados para isolamento semântico no LLM.
   - **A07:2025 - Identification and Authentication Failures**: Hashing de senhas com Argon2id, limitação de taxa contra força bruta via `@nestjs/throttler`, bloqueio temporário após 5 erros consecutivos, tokens JWT de curta duração com rotação e ausência de enumeração de usuários no login.

---

## 🧰 3. Catálogo de Skills do Projeto (`.agents/skills`)

O repositório possui skills especializadas instaladas em `.agents/skills/`. Os agentes devem consultar e ativar as skills apropriadas para cada tarefa:

### 📱 Frontend (Flutter Web)
| Skill | Quando Utilizar |
| :--- | :--- |
| `flutter-setup-declarative-routing` | Configuração de rotas declarativas e deep linking com `go_router`, route guards e histórico de navegação. |
| `flutter-apply-architecture-best-practices` | Estruturação de camadas limpas (UI, Logic, Data), injeção de dependências e gerência de estado. |
| `flutter-build-responsive-layout` | Adaptação visual da Arena para mobile, tablet e desktop com `LayoutBuilder` e breakpoints flexíveis. |
| `flutter-fix-layout-issues` | Diagnóstico e correção de problemas de renderização e overflow (`RenderFlex overflowed`). |
| `flutter-use-http-package` | Consumo de APIs REST (GET, POST, PUT, DELETE) com tratamento seguro de erros e interceptores. |
| `flutter-implement-json-serialization` | Criação de modelos com serialização JSON segura e tipagem estrita. |
| `flutter-add-widget-test` | Implementação de testes de componentes com `WidgetTester` (validação de interações de UI). |
| `flutter-add-integration-test` | Automação e testes de integração end-to-end com `integration_test` e Flutter Driver. |
| `flutter-add-widget-preview` | Criação de previews interativos de componentes e widgets da Arena. |
| `flutter-setup-localization` | Internacionalização (i18n) do jogo para múltiplos idiomas. |
| `flame-game-development` | Desenvolvimento de jogos 2D híbridos (Flame Engine + Flutter HUD), MVVM com Commands reutilizáveis, design tokens cyberpunk e mecânicas híbridas (Clash Royale + Legion TD + Archero). |

### 🎯 Linguagem Dart
| Skill | Quando Utilizar |
| :--- | :--- |
| `dart-run-static-analysis` | Execução de `dart analyze` e `dart fix --apply` para conformidade com linters. |
| `dart-add-unit-test` | Criação de testes unitários para regras de negócio, cálculo de SLA e pontuação da Arena. |
| `dart-generate-test-mocks` | Geração de mocks para serviços e conexões de rede usando `package:mockito` e `build_runner`. |
| `dart-fix-runtime-errors` | Diagnóstico e correção de falhas em tempo de execução via stack traces e hot reload. |
| `dart-use-pattern-matching` | Aplicação idiomática de pattern matching do Dart 3 em parsing de eventos e dados. |
| `dart-collect-coverage` | Geração de relatórios de cobertura de testes LCOV. |
| `dart-resolve-package-conflicts` | Resolução de incompatibilidades de dependências em `pubspec.yaml`. |
| `dart-write-documentation` | Escrita de documentação de APIs segundo as diretrizes do Effective Dart. |

### ⚡ Backend (NestJS & Prisma)
| Skill | Quando Utilizar |
| :--- | :--- |
| `nestjs-best-practices` | Arquitetura modular, injeção de dependência via construtor, DTOs com `class-validator`, ESM (`.js` imports) e filtros globais. |
| `nestjs-security-owasp` | Implementação de salvaguardas OWASP 2025 (RBAC A01, Sanitização A03, Argon2id & Rate Limiting A07, Helmet, CORS). |
| `nestjs-websocket-gateway` | Gateways Socket.IO para sincronização multiplayer em tempo real, salas de partida, logs de tokens e telemetria de logprobs. |
| `prisma-8` | Modelagem de banco relacional, schemas contratuais, migrations e queries type-safe com PostgreSQL. |
| `prisma-composer-core-concepts` | Gerenciamento de contratos de dados e extensões da CLI do Prisma. |
| `prisma-platform-core-concepts` | Configurações de conexão e pooling de instâncias PostgreSQL. |

### 🛠️ DevSecOps & Infraestrutura
| Skill | Quando Utilizar |
| :--- | :--- |
| `infra-devsecops` | Multi-stage Dockerfiles, orquestração com docker-compose, Nginx com TLS/PQC, Fail2Ban e automação de CI/CD com GitHub Actions. |
| `git-checkpoint` | Criação de commits semânticos e checkpoints atômicos segundo o Conventional Commits e prevenção de vazamento de segredos. |

---

## 📐 4. Padrões de Código e Convenções

### Backend NestJS
* **Módulos Independentes**: Todo recurso é isolado em um módulo (`auth`, `users`, `scenarios`, `matches`, `health`).
* **Imports ESM**: Em TypeScript ESM (`nodenext`), todos os imports relativos locais devem obrigatoriamente incluir a extensão `.js`:
  ```typescript
  import { AuthService } from './auth.service.js';
  import { LoginDto } from './dto/login.dto.js';
  ```
* **Validação Estrita**: Nunca permitir `any` não validado em endpoints. Sempre usar DTOs decorados com `class-validator`.
* **Senhas**: Nunca usar bcrypt legado ou MD5/SHA. Utilizar exclusivamente **Argon2id** (`argon2.hash(password, { type: argon2.argon2id })`).
* **Proteção de Segredos**: Nunca comitar arquivos `.env` ou secrets. Usar `.env.example` com placeholders.

### Frontend Flutter Web
* **Clean Architecture**: Separar UI (widgets/screens), Business Logic (controllers/bloc/cubit/notifier) e Data (repositories/data sources).
* **Guards de Rota**: Proteger páginas restritas (`/arena`) validando o estado de autenticação antes da renderização.
* **Sanitização de Renderização**: Nunca renderizar entradas de usuários como HTML bruto sem sanitização adequada contra XSS.
* **Feedback sem Enumeração**: Não informar se o email existe ou não em erros de login para mitigar User Enumeration.

---

## 🧪 5. Comandos de Verificação e Testes

### Backend NestJS
```bash
cd backend
npm run lint          # Executa oxlint com análise estática
npm test              # Executa testes unitários com Vitest
npm run build         # Compila o projeto TypeScript em dist/
npx prisma contract emit # Atualiza o contrato e tipos do Prisma
```

### Frontend Flutter Web
```bash
flutter analyze       # Análise estática do código Dart
flutter test          # Testes unitários e de widgets
flutter build web --release # Compilação para produção
```

---

## 🔒 6. Matriz de Rastreabilidade OWASP Top 10:2025

| Vulnerabilidade | Localização no Código | Implementação no Projeto |
| :--- | :--- | :--- |
| **A01:2025 - Broken Access Control** | `backend/src/auth/guards/jwt-auth.guard.ts`<br>`backend/src/auth/guards/roles.guard.ts`<br>`lib/router/route_guards.dart` | Tokens JWT validados por requisição, RBAC com papéis definidos (`RED_TEAM`, `BLUE_TEAM`, `CASTER`, `ADMIN`), invalidação de sessão no logout e bloqueio de acesso a recursos adversários. |
| **A03:2025 - Injection** | `backend/src/common/pipes/sanitization.pipe.ts`<br>`backend/src/scenarios/`<br>`backend/src/matches/`<br>`lib/services/prompt_sanitizer.dart` | Global ValidationPipe com whitelist restrita, Prisma queries parametrizadas (anti SQLi), delimitação estruturada XML/JSON em prompts de LLM e escape de entidades HTML (anti XSS). |
| **A07:2025 - Authentication Failures** | `backend/src/auth/auth.service.ts`<br>`backend/src/auth/auth.controller.ts`<br>`lib/screens/login_screen.dart` | Hashing com Argon2id, limitação de taxa (Throttler: 5 req/min), bloqueio temporário após 5 falhas consecutivas, mensagens de erro genéricas e rotação de refresh tokens. |

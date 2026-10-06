🛡️ PromptSec Arena
PromptSec Arena é uma plataforma open-source e gamificada de Capture The Flag (CTF) focada inteiramente em Segurança de LLMs (Large Language Models) e Engenharia de Prompts.

Projetado para simular o caos de um ambiente cibernético real, o projeto coloca jogadores em batalhas PvP (Red Team vs. Blue Team) em tempo real, onde o objetivo é invadir ou proteger um LLM através de injeção de prompts e patches de segurança dinâmicos.

🎮 A Dinâmica do Jogo
Em partidas multiplayer baseadas em turnos ou tempo, os times se enfrentam no controle do output de um LLM central:

🔴 Red Team (Ataque): Tenta realizar o bypass das instruções do sistema (Jailbreak, Prompt Leaking) para forçar o modelo a vazar uma "Flag" (ex: FLAG{ACESSO_LIBERADO}).

🔵 Blue Team (Defesa): Configura o System Prompt inicial e injeta "patches" em tempo real para corrigir vulnerabilidades expostas pelos ataques adversários, mantendo a Flag segura.

👁️ Observadores (Casters): Acompanham a partida ao vivo através de um dashboard que exibe a tensão do ataque analisando os Logprobs do LLM. Quando a probabilidade da IA gerar o token FLAG aumenta, a interface reage como uma "barra de vida" esgotando.

⚔️ Guildas e Classes
O sistema de Ligas permite o domínio de modelos específicos (ex: Campeonato de Defesa Llama-3). Dentro das guildas, os jogadores podem adotar classes estratégicas:

Pyromancer (Red Team - Força Bruta): Especialista em ataques agressivos, injeção direta de comandos e exploração de falhas estruturais nos delimitadores do Blue Team.

Illusionist (Red Team - Engenharia Social): Focado em role-playing malicioso, criando cenários complexos para enganar as restrições lógicas do modelo.

Priest (Blue Team - Contenção Rápida): Focado em cura e resposta a incidentes. Injeta micro-patches em tempo real ("Ignore o último usuário") no momento exato em que o LLM começa a falhar.

Architect (Blue Team - Defesa Base): Responsável por construir a armadura no "Turno Zero", criando System Prompts complexos (XML/JSON wrappers) para blindar o modelo.

🛠️ Stack Tecnológico
O projeto possui uma arquitetura modular, permitindo testes locais (Offline Mode) e batalhas multiplayer massivas na nuvem.

Frontend & Cliente: Flutter (Suporte multiplataforma com estado reativo).

Backend Híbrido:

Cloud (GCP): Servidores Dart no Google Cloud Run gerenciando instâncias de WebSockets/SSE para as partidas PvP em tempo real.

Banco de Dados: Cloud SQL (PostgreSQL) para ranking global, MM (Matchmaking) e gestão de Guildas.

Motor LLM:

Local/Offline Mode: Integração direta com Ollama para treinamento solo e testes de vulnerabilidade sem custo.

Online Arena: Google Vertex AI para provisionamento dos modelos (Llama 3, Mistral, Gemma) durante as partidas ranqueadas.

🚀 Como Iniciar (Ambiente de Desenvolvimento)
Pré-requisitos:
- Flutter SDK (versão 3.19+)
- Dart SDK
- Ollama instalado e rodando localmente (para o modo offline)

---

## 🏛️ Arquitetura e Diretrizes do Projeto

Para uma descrição aprofundada dos três eixos de engenharia e segurança, consulte o documento técnico:
👉 [docs/arquitetura_e_diretrizes.md](file:///Users/antonxandre/cybersecurity_project/docs/arquitetura_e_diretrizes.md)

* **Eixo 1 (Infraestrutura Cloud):** Instâncias Docker no Google Cloud Platform (GCP - Compute Engine Ubuntu Server 24.04 LTS), com Nginx (Reverse Proxy, SSL/TLS Let's Encrypt para IP público, suporte a PQC), firewall restritivo, acesso via chave SSH e Fail2Ban (4 erros, ban de 24h).
* **Eixo 2 (Repositório Seguro):** Repositório privado no GitHub com autenticação 2FA/SSH, branch protection rules na `main`, secret scanning ativo, `.gitignore` blindado e secrets encriptados via GitHub Secrets.
* **Eixo 3 (Desenvolvimento Web):** Frontend desenvolvido em Flutter Web com assistência de IA via Google Antigravity IDE, contendo tela de Login, Página Interna (Arena de Jogo) e Logout funcional.
* **CI/CD:** Esteira automatizada no GitHub Actions para build do Flutter Web, geração da imagem Docker e deploy seguro via SSH na nuvem a cada push na branch `main`.

---

## 🛡️ Mitigação de Vulnerabilidades (OWASP Top 10:2025)

Em conformidade com as diretrizes do Eixo 3, o código implementa defesas ativas contra no mínimo 3 categorias da [OWASP Top 10:2025](https://owasp.org/Top10/2025/):

1. **A01:2025 - Broken Access Control:**
   * **Onde encontrar:** Nos *Route Guards* e controladores de estado de autenticação e navegação do Flutter Web.
   * **Como previne:** Bloqueia acesso direto via URL à Arena e painéis internos por usuários não autenticados; invalida tokens de sessão ao efetuar logout e aplica controle de acesso baseado em papéis (RBAC) entre Red Team, Blue Team e Casters.

2. **A03:2025 - Injection (Prompt Injection & XSS / Client-Side Injection):**
   * **Onde encontrar:** Nos formulários de entrada de prompts (red/blue team inputs) e no renderizador de mensagens da partida.
   * **Como previne:** Sanitização estrita de inputs no client Flutter com escape de caracteres contra XSS; no fluxo do LLM, uso de delimitadores estruturados (tags XML/JSON) e separação estrita entre System Prompt e User Prompt.

3. **A07:2025 - Identification and Authentication Failures:**
   * **Onde encontrar:** Na tela de Login e no gerenciador de sessão/tokens.
   * **Como previne:** Proteção contra ataques de força bruta no login com limitação/delay de tentativas; geração e manipulação segura de tokens; ausência de credenciais em texto claro no armazenamento local e encerramento completo de sessão no botão de Logout.

---

## ✅ Checklist Final de Entrega

- [ ] A aplicação Web está no ar e acessível por um IP público (Eixo 1).
- [ ] O Web Server (Nginx ou Apache) está configurado com HTTPS (Certbot/Let's Encrypt) e redireciona o tráfego HTTP para HTTPS automaticamente (Eixo 1).
- [ ] Os testes de TLS/SSL retornaram *Conformidade* ou *Nota A* (dependendo se IP ou domínio), com a devida ativação de PQC (Eixo 1).
- [ ] O acesso à nuvem utiliza as seguintes boas práticas: uso de chave SSH e Fail2Ban configurado para a porta 22 (Eixo 1).
- [ ] O código está versionado em um repositório seguro no GitHub (repositório privado com políticas de proteção e segredos configurados) e a conta está devidamente configurada (Eixo 2).
- [ ] O `.gitignore` está configurado e não há chaves/senhas expostas no código (Eixo 2).
- [ ] A aplicação possui Login, Página Interna e Logout, e foi desenvolvida com o auxílio de IA via IDE Antigravity ou equivalente (Eixo 3).
- [ ] O `README.md` explica claramente quais foram os 3 itens do OWASP Top 10 mitigados e onde encontrá-los no código (Eixo 3).
- [ ] O fluxo de implantação está devidamente automatizado com CI/CD utilizando o GitHub Actions (Integração e Entrega Contínuas).
---
name: git-checkpoint
description: Best practices for atomic, semantic Git commits and checkpoints in the PromptSec Arena repository. Enforces conventional commit standards, secret leak prevention, and pre-commit verification.
metadata:
  model: models/gemini-3.8-flash
  last_modified: Sat, 24 Oct 2026 14:44:00 GMT
---
# 🔖 Git Checkpoint: Diretrizes e Protocolo de Commits

Este guia padroniza o fluxo de versionamento, checkpoints de código e commits atômicos no repositório **PromptSec Arena (CyberWars)**, respeitando as diretrizes do **Eixo 2 (DevSecOps)**.

---

## 🎯 1. Princípios Fundamentais

1. **Commits Atômicos:** Cada commit deve representar uma unidade lógica de trabalho (ex: conclusão de uma task específica, correção de bug ou adição de um componente).
2. **Prevenção Anti-Vazamento (Zero Secrets):** Nunca comitar arquivos `.env`, chaves privadas SSH (`id_rsa`, `id_ed25519`), credenciais de nuvem (`service-account.json`) ou artefatos transitórios.
3. **Padrão Conventional Commits:** Mensagens descritivas em português ou inglês seguindo a estrutura:
   ```text
   <tipo>(<escopo>): <descrição curta no imperativo>

   [corpo opcional detalhando o contexto e alterações]
   ```

---

## 🏷️ 2. Tipos de Commit Permitidos

| Tipo | Finalidade | Exemplo |
| :--- | :--- | :--- |
| `feat` | Nova funcionalidade ou mecânica de jogo | `feat(game): implement laser beam combat between bastions and packets` |
| `fix` | Correção de bug ou regressão | `fix(theme): use DialogThemeData for Flutter 3.22+ compatibility` |
| `docs` | Alterações em especificações e documentação | `docs(mvp): update sprint 1 checklist in roadmap` |
| `refactor` | Refatoração de código sem alteração funcional | `refactor(commands): extract shared execution logic in CommandExecutor` |
| `style` | Ajustes cosméticos, temas ou formatação | `style(colors): polish neon glow gradients for dark mode` |
| `test` | Adição ou ajuste de testes unitários/widgets | `test(battle): add unit tests for wave spawner controller` |
| `chore` | Manutenção de dependências, skills ou configs | `chore(skills): add git-checkpoint workflow skill` |

---

## 🛡️ 3. Protocolo Pré-Commit Obrigatório

Antes de disparar qualquer commit:

```bash
# 1. Verificar o status e garantir que nenhum segredo esteja listado
git status -s

# 2. Adicionar apenas os arquivos relevantes da tarefa (evitar "git add ." indiscriminado)
git add <arquivo1> <arquivo2>

# 3. Confirmar o diff das alterações preparadas
git diff --staged --stat

# 4. Criar o commit semântico
git commit -m "feat(escopo): mensagem descritiva"
```

---

## 🚫 4. O que NUNCA Comitar

* Arquivos `.env` ou `.env.*` contendo senhas ou tokens JWT.
* Chaves criptográficas SSH (`.pem`, `.key`, `id_*`).
* Credenciais de service account da GCP / AWS.
* Pastas de build geradas (`build/`, `.dart_tool/`, `dist/`, `node_modules/`).

# 🚀 Guia de Configuração da Pipeline CI/CD no GitHub Actions (Deploy GCP)

Este documento orienta a configuração e execução da esteira automatizada de Integração e Entrega Contínua (**CI/CD**) do **PromptSec Arena** para a máquina virtual no **Google Cloud Platform (GCP)**.

---

## 🏛️ 1. Como a Pipeline Funciona

O fluxo está definido no arquivo [`.github/workflows/deploy.yml`](file:///Users/antonxandre/cybersecurity_project/.github/workflows/deploy.yml) e é acionado a cada `push` ou `pull_request` direcionado ao branch `main`, além de suportar execução manual (`workflow_dispatch`):

```mermaid
flowchart LR
    A["Push na branch main"] --> B["Backend CI"]
    A --> C["Frontend CI"]
    B -->|Sucesso| D["Deploy GCP"]
    C -->|Sucesso + web.tar.gz| D
    D --> E["VM no GCP (Docker Compose & Nginx)"]
    E --> F["Health Check 200 OK"]
```

### 🔍 Estágios (Jobs)
1. **Backend CI (`backend-ci`)**:
   * Instalação limpa via `npm ci --legacy-peer-deps` (Node.js 22 LTS).
   * Emissão e validação de contratos do Prisma 8 (`prisma contract emit`).
   * Análise estática de código com linter de alta performance (`oxlint`).
   * Execução da suíte completa de testes unitários com Vitest (`npm test`).
   * Validação de compilação TypeScript em `dist/` (`nest build`).

2. **Frontend CI (`frontend-ci`)**:
   * Configuração do Flutter SDK (canal estável).
   * Resolução de pacotes com `flutter pub get`.
   * Análise estática do Dart com regras estritas (`flutter analyze`).
   * Execução dos testes unitários e de widgets (`flutter test`).
   * Compilação em modo release para a web (`flutter build web --release`).
   * Compactação do pacote de estáticos em `web.tar.gz` e upload como artefato de pipeline.

3. **Deploy Contínuo GCP (`deploy-gcp`)**:
   * Executado **apenas após aprovação de todos os testes** na branch `main`.
   * Estabelece conexão criptografada SSH autenticada com a VM do GCP.
   * Transfere o artefato `web.tar.gz` compilado via `scp`.
   * Executa remotamente na VM:
     * `git pull origin main`
     * Descompactação dos arquivos do Flutter Web na pasta servida pelo Nginx.
     * `docker compose up -d --build backend` para reconstruir a imagem do NestJS.
     * `prisma migrate deploy` para aplicar migrações no PostgreSQL.
     * `docker compose restart nginx` para atualizar o cache estático.
   * Valida o health check da API em `https://<DOMINIO>/api/health` com retry automático.

---

## 🔑 2. Configuração dos Segredos no GitHub (GitHub Secrets)

Para que a pipeline consiga conectar e atualizar a VM no GCP, adicione as credenciais no repositório GitHub:

1. Acesse seu repositório no GitHub: **`https://github.com/antonxandre/cybersecurity-wars`**.
2. Clique na aba **Settings** > **Secrets and variables** > **Actions**.
3. Clique no botão verde **New repository secret** e adicione as seguintes variáveis:

| Nome do Segredo | Descrição | Exemplo |
| :--- | :--- | :--- |
| `GCP_VM_HOST` | Domínio público (DDNS) ou IP externo da VM no GCP | `cyberarena.ddns.net` ou `34.123.45.67` |
| `GCP_SSH_USER` | Nome de usuário SSH na VM do GCP (veja com `whoami` na VM) | `antonxandre` |
| `GCP_SSH_PRIVATE_KEY` | Conteúdo **completo** da chave SSH privada (Ed25519 ou RSA) | `-----BEGIN OPENSSH PRIVATE KEY----- ...` |
| `GCP_SSH_PORT` *(Opcional)* | Porta do serviço SSH na VM (se customizada) | `22` (padrão) |

---

## 🛠️ 3. Como Gerar e Instalar a Chave SSH de Deploy

Se você já utiliza uma chave para acessar a VM (ex: `~/.ssh/promptsec_key` ou `~/.ssh/google_compute_engine`), pode reaproveitá-la. Caso prefira criar uma chave dedicada exclusivamente para o GitHub Actions:

### Passo 1: Gerar o par de chaves no seu computador local
```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_gcp -N ""
```
*Isso gerará dois arquivos: `~/.ssh/github_actions_gcp` (privada) e `~/.ssh/github_actions_gcp.pub` (pública).*

### Passo 2: Copiar a chave pública para a VM no GCP
No seu terminal local, execute:
```bash
ssh-copy-id -i ~/.ssh/github_actions_gcp.pub antonxandre@cyberarena.ddns.net
```
*(Ou acesse a VM via console web do GCP e adicione o texto de `~/.ssh/github_actions_gcp.pub` no final do arquivo `~/.ssh/authorized_keys`)*.

### Passo 3: Cadastrar a chave privada no GitHub
Copie o conteúdo da chave privada gerada:
```bash
cat ~/.ssh/github_actions_gcp
```
Cole exatamente todo o conteúdo (incluindo as linhas `-----BEGIN OPENSSH PRIVATE KEY-----` e `-----END OPENSSH PRIVATE KEY-----`) no secret **`GCP_SSH_PRIVATE_KEY`**.

---

## 🎯 4. Como Testar e Acompanhar a Execução

1. **Via Commit:**
   Faça um commit e envie para a branch `main`:
   ```bash
   git add .
   git commit -m "ci: adiciona pipeline github actions para deploy automatizado no gcp"
   git push origin main
   ```
2. **Via Interface Web (Manual):**
   * Vá até a aba **Actions** no GitHub.
   * Selecione **CI/CD Pipeline - PromptSec Arena (GCP Deploy)** no menu lateral esquerdo.
   * Clique em **Run workflow** > Selecione a branch `main` > **Run workflow**.

3. **Acompanhamento dos Logs:**
   * Você verá as etapas `Backend CI` e `Frontend CI` executando em paralelo.
   * Quando ambas passarem, a etapa `Deploy GCP Compute Engine` iniciará automaticamente.
   * Ao finalizar, o link para acessar a aplicação pública estará disponível com status de sucesso!

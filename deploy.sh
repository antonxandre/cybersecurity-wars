#!/usr/bin/env bash
# ==============================================================================
# PromptSec Arena - Script de Deploy Automatizado (Local -> GCP)
# ==============================================================================
# Este script automatiza o ciclo completo de deploy da sua máquina local para a VM:
# 1. Compila o Flutter Web localmente em release
# 2. Compacta os artefatos estáticos (web.tar.gz)
# 3. Envia o build para a VM no GCP via SCP
# 4. Executa na VM: git pull, docker compose up -d --build, prisma migrate e reload do Nginx
# 5. Valida o health check da aplicação em https://cyberarena.ddns.net/api/health
# ==============================================================================

set -euo pipefail

# Cores para feedback visual
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações Padrão
VM_HOST="${DEPLOY_HOST:-cyberarena.ddns.net}"
VM_USER="${DEPLOY_USER:-$USER}"
SSH_KEY="${DEPLOY_SSH_KEY:-}"
REMOTE_DIR="~/app"
SKIP_BUILD=false
ONLY_FRONTEND=false

# Carregar arquivo de configuração local se existir (.deploy.env)
if [ -f ".deploy.env" ]; then
    # shellcheck disable=SC1091
    source ".deploy.env"
fi

# Se não foi informada chave e existir a chave dedicada promptsec_key, usá-la por padrão
if [ -z "$SSH_KEY" ] && [ -f "$HOME/.ssh/promptsec_key" ]; then
    SSH_KEY="$HOME/.ssh/promptsec_key"
fi

# Função de ajuda
show_help() {
    cat <<EOF
Uso: $0 [opções]

Opções:
  -h, --host <host>       Domínio ou IP externo da VM (padrão: $VM_HOST)
  -u, --user <usuario>    Usuário SSH na VM do GCP (padrão: $VM_USER)
  -k, --key <arquivo>     Caminho da chave SSH privada (ex: ~/.ssh/id_ed25519)
  -s, --skip-build        Pula a compilação do Flutter Web (usa o build existente)
  -f, --only-frontend     Atualiza apenas os arquivos do frontend sem rebuild dos containers
  --help                  Exibe esta ajuda

Exemplos:
  $0
  $0 -u antonxandre -h cyberarena.ddns.net
  $0 -u antonxandre -k ~/.ssh/google_compute_engine
  $0 --skip-build
EOF
    exit 0
}

# Parsing de argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--host)
            VM_HOST="$2"
            shift 2
            ;;
        -u|--user)
            VM_USER="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -f|--only-frontend)
            ONLY_FRONTEND=true
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            echo -e "${RED}Opção inválida: $1${NC}"
            show_help
            ;;
    esac
done

# Montar opções do SSH/SCP
SSH_OPTS=("-o" "StrictHostKeyChecking=accept-new" "-o" "ConnectTimeout=10")
if [ -n "$SSH_KEY" ]; then
    SSH_OPTS+=("-i" "$SSH_KEY")
fi

echo -e "${CYAN}=====================================================${NC}"
echo -e "${CYAN}🚀 PromptSec Arena - Início do Deploy no GCP        ${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo -e "Alvo:    ${YELLOW}${VM_USER}@${VM_HOST}${NC}"
echo -e "Destino: ${YELLOW}${REMOTE_DIR}${NC}"
echo ""

# ------------------------------------------------------------------------------
# 1. Testar Conexão SSH com a VM
# ------------------------------------------------------------------------------
echo -e "${BLUE}📡 [1/5] Testando conexão SSH com a VM...${NC}"
set +e
SSH_ERR_OUTPUT=$(ssh "${SSH_OPTS[@]}" "${VM_USER}@${VM_HOST}" "echo 'Conexão SSH bem-sucedida!'" 2>&1)
SSH_EXIT_CODE=$?
set -e

if [ $SSH_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}❌ Erro: Não foi possível conectar via SSH a ${VM_USER}@${VM_HOST}.${NC}"
    echo -e "${YELLOW}Detalhe do erro retornado pelo SSH:${NC}"
    echo -e "${RED}${SSH_ERR_OUTPUT}${NC}\n"
    echo -e "${YELLOW}Como resolver:${NC}"
    echo -e "1. Usuário na VM: descubra seu usuário rodando 'whoami' no terminal da VM e passe com: $0 -u <usuario>"
    echo -e "2. Chave SSH: garanta que sua chave pública local está no ~/.ssh/authorized_keys da VM."
    echo -e "3. IP direto: tente passar o IP externo com: $0 -h <IP_EXTERNO>"
    exit 1
fi
echo -e "${GREEN}✓ Conexão SSH validada com sucesso.${NC}"

# ------------------------------------------------------------------------------
# 2. Compilar o Frontend Flutter Web
# ------------------------------------------------------------------------------
if [ "$SKIP_BUILD" = false ]; then
    echo -e "\n${BLUE}📦 [2/5] Compilando Flutter Web em release...${NC}"
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter SDK não encontrado no PATH!${NC}"
        exit 1
    fi

    (
        cd frontend
        flutter pub get
        flutter build web --release
    )
    echo -e "${GREEN}✓ Build do Flutter Web concluído com sucesso.${NC}"
else
    echo -e "\n${YELLOW}⏭️  [2/5] Pulando compilação do Flutter (--skip-build ativo)...${NC}"
fi

# Validar se a pasta build/web existe
if [ ! -f "frontend/build/web/index.html" ]; then
    echo -e "${RED}❌ Erro: Arquivo frontend/build/web/index.html não encontrado!${NC}"
    echo -e "Execute o script sem a opção --skip-build."
    exit 1
fi

# ------------------------------------------------------------------------------
# 3. Compactar e Enviar Artefatos para a VM
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}📤 [3/5] Compactando e enviando arquivos estáticos para a VM...${NC}"
tar -czf web.tar.gz -C frontend/build web
scp "${SSH_OPTS[@]}" web.tar.gz "${VM_USER}@${VM_HOST}:${REMOTE_DIR}/"
rm -f web.tar.gz
echo -e "${GREEN}✓ Arquivos enviados para a VM.${NC}"

# ------------------------------------------------------------------------------
# 4. Executar Atualizações Remotas na VM
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}⚙️  [4/5] Executando comandos de atualização na VM...${NC}"

REMOTE_SCRIPT=$(cat << 'EOF'
set -e
cd ~/app

# Garantir posse dos arquivos para o usuário
sudo chown -R $USER:$USER ~/app

# 1. Puxar as alterações mais recentes do repositório Git
echo "🔄 Atualizando repositório via git pull..."
git pull origin main || git pull

# 2. Descompactar o build do frontend na pasta esperada pelo docker-compose
echo "📂 Atualizando arquivos do Flutter Web..."
mkdir -p frontend/build
tar -xzf web.tar.gz -C frontend/build/
rm -f web.tar.gz
chmod -R 755 frontend/build/web

EOF
)

if [ "$ONLY_FRONTEND" = true ]; then
    REMOTE_SCRIPT+=$(cat << 'EOF'
echo "🔄 Recarregando Nginx para servir novo frontend..."
docker compose restart nginx
EOF
)
else
    REMOTE_SCRIPT+=$(cat << 'EOF'
# 3. Rebuild e reinício dos containers necessários
echo "🐳 Reconstruindo contêineres e atualizando backend..."
docker compose up -d --build

# 4. Executar migrações do banco de dados (Prisma)
echo "🗄️ Aplicando migrações do Prisma no banco de dados..."
docker compose exec -T backend npx prisma migrate deploy || true

# 5. Reiniciar o Nginx para garantir que todos os estáticos estão frescos
docker compose restart nginx
EOF
)
fi

ssh "${SSH_OPTS[@]}" "${VM_USER}@${VM_HOST}" "bash -s" <<< "$REMOTE_SCRIPT"
echo -e "${GREEN}✓ Atualização remota concluída na VM.${NC}"

# ------------------------------------------------------------------------------
# 5. Health Check Pós-Deploy
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}🔍 [5/5] Executando Health Check na API de Produção...${NC}"
HEALTH_URL="https://${VM_HOST}/api/health"

sleep 3 # Aguardar 3 segundos para estabilização
HEALTH_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || echo "000")

if [ "$HEALTH_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ API Health Check respondeu 200 OK!${NC}"
    echo ""
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${GREEN}🎉 DEPLOY CONCLUÍDO COM SUCESSO!                     ${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "Acesse a aplicação em: ${CYAN}https://${VM_HOST}/${NC}"
else
    echo -e "${YELLOW}⚠️ Aviso: Health Check retornou status HTTP ${HEALTH_STATUS} em ${HEALTH_URL}.${NC}"
    echo -e "Verifique os logs na VM: ${CYAN}ssh ${VM_USER}@${VM_HOST} 'docker compose logs --tail 30'${NC}"
fi
